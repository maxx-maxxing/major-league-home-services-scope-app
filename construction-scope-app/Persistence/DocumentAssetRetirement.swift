import Darwin
import Foundation

enum DocumentAssetRetirementOutcome: String, Equatable, Sendable {
    case removed
    case alreadyAbsent
    case rejected
    case failed
}

enum DocumentAssetRetirement {
    static func retire(
        attachmentID: UUID,
        path: String,
        scopeID: UUID,
        fileManager: FileManager = .default,
        applicationSupportDirectory: URL? = nil
    ) -> DocumentAssetRetirementOutcome {
        guard let supportDirectory = resolvedSupportDirectory(
            fileManager: fileManager,
            injectedDirectory: applicationSupportDirectory
        ),
        let candidate = validatedCandidate(
            attachmentID: attachmentID,
            path: path,
            scopeID: scopeID,
            supportDirectory: supportDirectory
        ) else {
            return .rejected
        }

        let rootResult = openDirectory(path: supportDirectory.path)
        switch rootResult {
        case .absent:
            return .alreadyAbsent
        case .rejected:
            return .rejected
        case .failed:
            return .failed
        case .opened(let supportDescriptor):
            defer { close(supportDescriptor) }

            return retireAnchored(
                filename: candidate.filename,
                scopeID: scopeID,
                supportDescriptor: supportDescriptor
            )
        }
    }
}

private extension DocumentAssetRetirement {
    struct Candidate {
        let filename: String
    }

    enum DirectoryOpenResult {
        case opened(Int32)
        case absent
        case rejected
        case failed
    }

    static func resolvedSupportDirectory(
        fileManager: FileManager,
        injectedDirectory: URL?
    ) -> URL? {
        let directory: URL
        if let injectedDirectory {
            directory = injectedDirectory
        } else {
            guard let defaultDirectory = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                return nil
            }
            directory = defaultDirectory
        }

        guard directory.isFileURL,
              isAbsoluteStandardizedPath(directory.path) else {
            return nil
        }
        return directory
    }

    static func validatedCandidate(
        attachmentID: UUID,
        path: String,
        scopeID: UUID,
        supportDirectory: URL
    ) -> Candidate? {
        guard isAbsoluteStandardizedPath(path) else { return nil }

        let documentsDirectory = supportDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)

        let candidateURL = URL(fileURLWithPath: path, isDirectory: false)
        guard candidateURL.deletingLastPathComponent().path == documentsDirectory.path else {
            return nil
        }

        let filename = candidateURL.lastPathComponent
        guard filename.hasPrefix("\(attachmentID.uuidString)-"),
              filename != ".",
              filename != ".." else {
            return nil
        }

        return Candidate(filename: filename)
    }

    static func isAbsoluteStandardizedPath(_ path: String) -> Bool {
        guard path.hasPrefix("/"), !path.isEmpty else { return false }
        return (path as NSString).standardizingPath == path
    }

    static func retireAnchored(
        filename: String,
        scopeID: UUID,
        supportDescriptor: Int32
    ) -> DocumentAssetRetirementOutcome {
        var currentDescriptor = supportDescriptor
        var ownedDescriptors: [Int32] = []
        defer {
            for descriptor in ownedDescriptors.reversed() {
                close(descriptor)
            }
        }

        for component in ["ScopeAssets", scopeID.uuidString, "Documents"] {
            let result = openDirectory(component: component, relativeTo: currentDescriptor)
            switch result {
            case .absent:
                return .alreadyAbsent
            case .rejected:
                return .rejected
            case .failed:
                return .failed
            case .opened(let descriptor):
                ownedDescriptors.append(descriptor)
                currentDescriptor = descriptor
            }
        }

        var metadata = stat()
        guard fstatat(currentDescriptor, filename, &metadata, AT_SYMLINK_NOFOLLOW) == 0 else {
            return errno == ENOENT ? .alreadyAbsent : .failed
        }

        let fileType = metadata.st_mode & mode_t(S_IFMT)
        guard fileType == mode_t(S_IFREG) else {
            return .rejected
        }

        guard unlinkat(currentDescriptor, filename, 0) == 0 else {
            return errno == ENOENT ? .alreadyAbsent : .failed
        }

        return .removed
    }

    static func openDirectory(path: String) -> DirectoryOpenResult {
        let descriptor = Darwin.open(
            path,
            O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
        guard descriptor >= 0 else {
            return classifiedDirectoryOpenFailure(errno)
        }
        return .opened(descriptor)
    }

    static func openDirectory(component: String, relativeTo descriptor: Int32) -> DirectoryOpenResult {
        let childDescriptor = Darwin.openat(
            descriptor,
            component,
            O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
        guard childDescriptor >= 0 else {
            return classifiedDirectoryOpenFailure(errno)
        }
        return .opened(childDescriptor)
    }

    static func classifiedDirectoryOpenFailure(_ errorNumber: Int32) -> DirectoryOpenResult {
        switch errorNumber {
        case ENOENT:
            return .absent
        case ELOOP, ENOTDIR:
            return .rejected
        default:
            return .failed
        }
    }
}
