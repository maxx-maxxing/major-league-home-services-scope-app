import Foundation

enum PersistenceHarnessPathGuard {
    private static let markerFilename = ".persistence-harness-sentinel"
    private static let directoryPrefix = "scope-persistence-compatibility."
    private static let storeFilename = "Compatibility.store"

    static func validatedStoreURL(_ rawPath: String, mustExist: Bool) throws -> URL {
        let requestedURL = URL(fileURLWithPath: rawPath).standardizedFileURL
        let resolvedParent = requestedURL
            .deletingLastPathComponent()
            .resolvingSymlinksInPath()
        let resolvedTemporaryRoot = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .resolvingSymlinksInPath()

        guard requestedURL.lastPathComponent == storeFilename,
              resolvedParent.lastPathComponent.hasPrefix(directoryPrefix),
              resolvedParent.deletingLastPathComponent() == resolvedTemporaryRoot else {
            throw PersistenceHarnessPathError.unsafeStorePath
        }

        let markerURL = resolvedParent.appendingPathComponent(markerFilename)
        var markerIsDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(
            atPath: markerURL.path,
            isDirectory: &markerIsDirectory
        ), !markerIsDirectory.boolValue else {
            throw PersistenceHarnessPathError.missingHarnessSentinel
        }

        let storeURL = resolvedParent.appendingPathComponent(storeFilename)
        if (try? FileManager.default.destinationOfSymbolicLink(atPath: storeURL.path)) != nil {
            throw PersistenceHarnessPathError.unsafeStorePath
        }

        let storeExists = FileManager.default.fileExists(atPath: storeURL.path)
        guard storeExists == mustExist else {
            throw mustExist
                ? PersistenceHarnessPathError.storeDoesNotExist
                : PersistenceHarnessPathError.storeAlreadyExists
        }

        if storeExists {
            let values = try storeURL.resourceValues(forKeys: [.isSymbolicLinkKey])
            guard values.isSymbolicLink != true else {
                throw PersistenceHarnessPathError.unsafeStorePath
            }
        }

        return storeURL
    }
}

enum PersistenceHarnessPathError: Error {
    case unsafeStorePath
    case missingHarnessSentinel
    case storeAlreadyExists
    case storeDoesNotExist
}
