import Foundation
import CryptoKit
import Darwin

enum ScopeBackupError: LocalizedError {
    case invalidArchive, unsupportedVersion, sizeLimit, unsafeFile, missingAsset
    case changedDuringExport, saveRequired, recoveryRequired, fileOperation, noScopes

    var errorDescription: String? {
        switch self {
        case .invalidArchive: return "This backup is incomplete or its integrity checks failed. No scopes were restored."
        case .unsupportedVersion: return "This backup uses an unsupported format or schema version. Use a compatible Scopes build."
        case .sizeLimit: return "This backup exceeds the supported limit: 128 MB of assets, 32 MB per file, or 1,000 scopes. Export fewer scopes or smaller attachments."
        case .unsafeFile: return "The backup contains an unsupported file or unsafe file reference. No scopes were restored."
        case .missingAsset: return "A scope attachment is missing or is outside its managed scope folder. Preserve the installed app and resolve the attachment before backing up."
        case .changedDuringExport: return "Scope data changed while the backup was being prepared. Try again after attachments finish importing."
        case .saveRequired: return "Save the pending local changes before creating or restoring a backup."
        case .recoveryRequired: return "An interrupted restore needs recovery before another backup operation can continue. Some scopes may already have been restored. Preserve the installed app and reopen Scopes, then review existing scopes before trying again."
        case .fileOperation: return "The backup file operation could not be completed. Existing scopes were preserved. Check available storage and try again."
        case .noScopes: return "There are no local scopes to back up."
        }
    }
}

struct ScopeBackupAsset: Codable, Equatable {
    var path: String
    var data: Data
    var sha256: String
    var createdAt: Date? = nil
    var modifiedAt: Date? = nil
}

// Immutable value snapshots cross a file-work queue; no SwiftData objects cross actors.
struct ScopeBackupContents: Codable, @unchecked Sendable {
    var formatVersion: Int
    var schemaVersion: Int
    var createdAt: Date
    var records: [ScopeBackupRecord]
    var assets: [ScopeBackupAsset]
    var manifestSHA256: String

    var assetCount: Int { assets.count }
    var totalAssetBytes: Int { assets.reduce(0) { $0 + $1.data.count } }
}

enum ScopeBackupArchive {
    static let formatVersion = 1
    static let schemaVersion = 3
    static let maximumArchiveBytes = 192 * 1_024 * 1_024
    static let maximumAssetBytes = 32 * 1_024 * 1_024
    static let maximumTotalAssetBytes = 128 * 1_024 * 1_024
    static let maximumAssetCount = 5_000
    static let maximumScopeCount = 1_000

    private struct Manifest: Codable {
        struct File: Codable { var path: String; var size: Int; var sha256: String; var createdAt: Date?; var modifiedAt: Date? }
        var formatVersion: Int
        var schemaVersion: Int
        var createdAt: Date
        var records: [ScopeBackupRecord]
        var files: [File]
    }

    static func encode(records: [ScopeBackupRecord], assetsRoot: URL) throws -> Data {
        guard !records.isEmpty else { throw ScopeBackupError.noScopes }
        guard records.count <= maximumScopeCount else { throw ScopeBackupError.sizeLimit }
        guard Set(records.map(\.id)).count == records.count else { throw ScopeBackupError.invalidArchive }
        let manager = FileManager.default
        let root = assetsRoot.standardizedFileURL
        try ScopeBackupFiles.rejectLinks(at: root, allowMissing: true)
        var copies = records
        var assets: [ScopeBackupAsset] = []
        var totalBytes = 0
        for index in copies.indices {
            let scopeID = copies[index].id.uuidString
            let folder = root.appendingPathComponent(scopeID, isDirectory: true)
            var mapping: [String: String] = [:]
            if manager.fileExists(atPath: folder.path) {
                try ScopeBackupFiles.rejectLinks(at: folder)
                var enumerationFailed = false
                guard let walker = manager.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey], options: [], errorHandler: { _, _ in enumerationFailed = true; return false }) else { throw ScopeBackupError.fileOperation }
                for case let url as URL in walker {
                    try ScopeBackupFiles.rejectLinks(at: url)
                    let before = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey])
                    if before.isDirectory == true { continue }
                    guard before.isRegularFile == true else { throw ScopeBackupError.unsafeFile }
                    guard let size = before.fileSize, size <= maximumAssetBytes else { throw ScopeBackupError.sizeLimit }
                    let relative = String(url.path.dropFirst(folder.path.count + 1))
                    let archivePath = "assets/\(scopeID)/\(relative)"
                    try validatePath(archivePath, scopeIDs: Set(records.map(\.id)))
                    let data = try ScopeBackupFiles.read(url, limit: maximumAssetBytes)
                    let after = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                    guard data.count == size, before.fileSize == after.fileSize, before.contentModificationDate == after.contentModificationDate else { throw ScopeBackupError.changedDuringExport }
                    totalBytes += data.count
                    guard totalBytes <= maximumTotalAssetBytes, assets.count < maximumAssetCount else { throw ScopeBackupError.sizeLimit }
                    assets.append(ScopeBackupAsset(path: archivePath, data: data, sha256: digest(data), createdAt: before.creationDate, modifiedAt: before.contentModificationDate))
                    mapping[url.standardizedFileURL.path] = archivePath
                }
                guard !enumerationFailed else { throw ScopeBackupError.fileOperation }
            }
            for path in try copies[index].referencedAssetPaths() {
                // Never read arbitrary persisted absolute paths. Every reference must name an inventoried managed file.
                guard URL(fileURLWithPath: path).standardizedFileURL.path == path, mapping[path] != nil else { throw ScopeBackupError.missingAsset }
            }
            try copies[index].remapAssetPaths(mapping)
        }
        var contents = ScopeBackupContents(formatVersion: formatVersion, schemaVersion: schemaVersion, createdAt: .now, records: copies, assets: assets.sorted { $0.path < $1.path }, manifestSHA256: "")
        contents.manifestSHA256 = try manifestDigest(contents)
        let data = try encoder().encode(contents)
        guard data.count <= maximumArchiveBytes else { throw ScopeBackupError.sizeLimit }
        _ = try validate(data: data)
        return data
    }

    static func validate(data: Data) throws -> ScopeBackupContents {
        guard data.count <= maximumArchiveBytes else { throw ScopeBackupError.sizeLimit }
        let contents: ScopeBackupContents
        do { contents = try JSONDecoder().decode(ScopeBackupContents.self, from: data) }
        catch { throw ScopeBackupError.invalidArchive }
        guard contents.formatVersion == formatVersion, contents.schemaVersion == schemaVersion else { throw ScopeBackupError.unsupportedVersion }
        guard !contents.records.isEmpty, contents.records.count <= maximumScopeCount, contents.assets.count <= maximumAssetCount else { throw ScopeBackupError.sizeLimit }
        let scopeIDs = Set(contents.records.map(\.id))
        guard scopeIDs.count == contents.records.count else { throw ScopeBackupError.invalidArchive }
        var paths = Set<String>()
        var portablePaths = Set<String>()
        var total = 0
        for asset in contents.assets {
            try validatePath(asset.path, scopeIDs: scopeIDs)
            guard paths.insert(asset.path).inserted, portablePaths.insert(portablePath(asset.path)).inserted else { throw ScopeBackupError.invalidArchive }
            guard asset.data.count <= maximumAssetBytes else { throw ScopeBackupError.sizeLimit }
            total += asset.data.count
            guard total <= maximumTotalAssetBytes else { throw ScopeBackupError.sizeLimit }
            guard digest(asset.data) == asset.sha256 else { throw ScopeBackupError.invalidArchive }
        }
        // A file must never also be an ancestor directory of another file.
        for path in paths {
            var parent = (path as NSString).deletingLastPathComponent
            while parent != "assets" && !parent.isEmpty {
                guard !portablePaths.contains(portablePath(parent)) else { throw ScopeBackupError.invalidArchive }
                parent = (parent as NSString).deletingLastPathComponent
            }
        }
        for record in contents.records {
            for reference in try record.referencedAssetPaths() {
                try validatePath(reference, scopeIDs: [record.id])
                guard paths.contains(reference) else { throw ScopeBackupError.missingAsset }
            }
        }
        guard try manifestDigest(contents) == contents.manifestSHA256 else { throw ScopeBackupError.invalidArchive }
        return contents
    }

    static func validatePath(_ path: String, scopeIDs: Set<UUID>) throws {
        let parts = path.components(separatedBy: "/")
        guard path.utf8.count <= 1_024, parts.count >= 3, parts[0] == "assets",
              let id = UUID(uuidString: parts[1]), scopeIDs.contains(id), parts[1] == id.uuidString,
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("\\") && !$0.contains(":") && !$0.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) }) else { throw ScopeBackupError.unsafeFile }
    }

    static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    private static func portablePath(_ path: String) -> String {
        path.precomposedStringWithCanonicalMapping.lowercased()
    }

    private static func manifestDigest(_ contents: ScopeBackupContents) throws -> String {
        let manifest = Manifest(formatVersion: contents.formatVersion, schemaVersion: contents.schemaVersion, createdAt: contents.createdAt, records: contents.records, files: contents.assets.map { Manifest.File(path: $0.path, size: $0.data.count, sha256: $0.sha256, createdAt: $0.createdAt, modifiedAt: $0.modifiedAt) })
        return digest(try encoder().encode(manifest))
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

enum ScopeBackupFiles {
    static func read(_ url: URL, limit: Int) throws -> Data {
        try rejectLinks(at: url)
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw ScopeBackupError.fileOperation }
        defer { close(descriptor) }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0, metadata.st_mode & S_IFMT == S_IFREG else { throw ScopeBackupError.unsafeFile }
        guard metadata.st_size >= 0, metadata.st_size <= limit else { throw ScopeBackupError.sizeLimit }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        var data = Data()
        while let chunk = try handle.read(upToCount: min(1_024 * 1_024, limit - data.count + 1)), !chunk.isEmpty {
            data.append(chunk)
            guard data.count <= limit else { throw ScopeBackupError.sizeLimit }
        }
        return data
    }

    static func rejectLinks(at url: URL, allowMissing: Bool = false) throws {
        // Resolve system aliases such as /tmp once, but reject a link at any application-owned component.
        let standardized = url.standardizedFileURL
        var cursor = standardized
        while cursor.path != "/" {
            if FileManager.default.fileExists(atPath: cursor.path) || (try? FileManager.default.destinationOfSymbolicLink(atPath: cursor.path)) != nil {
                let values = try cursor.resourceValues(forKeys: [.isSymbolicLinkKey])
                if values.isSymbolicLink == true {
                    guard cursor.path == "/tmp" || cursor.path == "/var" else { throw ScopeBackupError.unsafeFile }
                }
            } else if cursor == standardized && !allowMissing { throw ScopeBackupError.fileOperation }
            cursor.deleteLastPathComponent()
        }
    }

    static func makeDirectory(_ url: URL) throws {
        try rejectLinks(at: url, allowMissing: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    }
}
