import Darwin
import Foundation

private struct RetirementTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
private enum DocumentAssetRetirementTests {
    private static let scopeID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    private static let siblingScopeID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    private static let attachmentID = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!
    private static let replacementID = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!

    static func main() {
        let testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("scope-document-retirement-tests-\(UUID().uuidString)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: testRoot, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: testRoot) }

            try testValidRetirementIsScopedAndIdempotent(in: testRoot)
            try testLexicalBoundaryRejections(in: testRoot)
            try testDirectoriesAndSpecialFilesAreRejected(in: testRoot)
            try testFinalAndDanglingSymlinksAreRejected(in: testRoot)
            try testSymlinkedOwnedAncestorsAreRejected(in: testRoot)
            print("Document asset retirement tests passed")
        } catch let failure as RetirementTestFailure {
            fail(failure.description)
        } catch {
            fail("unexpected test failure type: \(String(describing: type(of: error)))")
        }
    }

    private static func testValidRetirementIsScopedAndIdempotent(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "valid", in: testRoot)
        let documentsDirectory = try makeDocumentsDirectory(
            supportDirectory: supportDirectory,
            scopeID: scopeID
        )
        let siblingDocumentsDirectory = try makeDocumentsDirectory(
            supportDirectory: supportDirectory,
            scopeID: siblingScopeID
        )

        let retiredFile = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-old.pdf")
        let replacementFile = documentsDirectory.appendingPathComponent("\(replacementID.uuidString)-new.pdf")
        let siblingFile = siblingDocumentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-sibling.pdf")
        try writeFixture(to: retiredFile)
        try writeFixture(to: replacementFile)
        try writeFixture(to: siblingFile)

        let outcome = retire(path: retiredFile.path, supportDirectory: supportDirectory)
        try require(outcome == .removed, "valid managed file was not retired")
        try require(!pathExistsWithoutFollowingSymlinks(retiredFile.path), "retired file still exists")
        try require(pathExistsWithoutFollowingSymlinks(replacementFile.path), "replacement file was removed")
        try require(pathExistsWithoutFollowingSymlinks(siblingFile.path), "sibling-scope file was removed")

        let repeatedOutcome = retire(path: retiredFile.path, supportDirectory: supportDirectory)
        try require(repeatedOutcome == .alreadyAbsent, "valid missing file was not idempotent")

        let missingSupportDirectory = try makeSupportDirectory(named: "missing-owned-tree", in: testRoot)
        let validMissingPath = documentsPath(
            supportDirectory: missingSupportDirectory,
            scopeID: scopeID
        ).appendingPathComponent("\(attachmentID.uuidString)-missing.pdf").path
        try require(
            retire(path: validMissingPath, supportDirectory: missingSupportDirectory) == .alreadyAbsent,
            "missing owned directory tree was not treated as already absent"
        )
    }

    private static func testLexicalBoundaryRejections(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "lexical", in: testRoot)
        let documentsDirectory = try makeDocumentsDirectory(
            supportDirectory: supportDirectory,
            scopeID: scopeID
        )
        let managedFile = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-managed.pdf")
        try writeFixture(to: managedFile)

        let siblingDocumentsDirectory = try makeDocumentsDirectory(
            supportDirectory: supportDirectory,
            scopeID: siblingScopeID
        )
        let wrongScopeFile = siblingDocumentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-wrong-scope.pdf")
        try writeFixture(to: wrongScopeFile)
        try require(
            retire(path: wrongScopeFile.path, supportDirectory: supportDirectory) == .rejected,
            "wrong-scope path was accepted"
        )

        let otherSupportDirectory = try makeSupportDirectory(named: "other-container", in: testRoot)
        let otherDocumentsDirectory = try makeDocumentsDirectory(
            supportDirectory: otherSupportDirectory,
            scopeID: scopeID
        )
        let wrongContainerFile = otherDocumentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-wrong-container.pdf")
        try writeFixture(to: wrongContainerFile)
        try require(
            retire(path: wrongContainerFile.path, supportDirectory: supportDirectory) == .rejected,
            "wrong-container path was accepted"
        )

        let prefixCollisionDirectory = supportDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent("\(scopeID.uuidString)-other", isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: prefixCollisionDirectory, withIntermediateDirectories: true)
        let prefixCollisionFile = prefixCollisionDirectory.appendingPathComponent("\(attachmentID.uuidString)-prefix.pdf")
        try writeFixture(to: prefixCollisionFile)
        try require(
            retire(path: prefixCollisionFile.path, supportDirectory: supportDirectory) == .rejected,
            "scope-prefix collision was accepted"
        )

        let traversalPath = "\(documentsDirectory.path)/../Documents/\(managedFile.lastPathComponent)"
        try require(
            retire(path: traversalPath, supportDirectory: supportDirectory) == .rejected,
            "non-standardized traversal path was accepted"
        )

        let nestedDirectory = documentsDirectory.appendingPathComponent("Nested", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        let nestedFile = nestedDirectory.appendingPathComponent("\(attachmentID.uuidString)-nested.pdf")
        try writeFixture(to: nestedFile)
        try require(
            retire(path: nestedFile.path, supportDirectory: supportDirectory) == .rejected,
            "non-direct child path was accepted"
        )

        let documentsPrefixDirectory = supportDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
            .appendingPathComponent("DocumentsBackup", isDirectory: true)
        try FileManager.default.createDirectory(at: documentsPrefixDirectory, withIntermediateDirectories: true)
        let documentsPrefixFile = documentsPrefixDirectory
            .appendingPathComponent("\(attachmentID.uuidString)-documents-prefix.pdf")
        try writeFixture(to: documentsPrefixFile)
        try require(
            retire(path: documentsPrefixFile.path, supportDirectory: supportDirectory) == .rejected,
            "Documents-prefix collision was accepted"
        )

        let wrongAttachmentPath = documentsDirectory.appendingPathComponent("\(replacementID.uuidString)-wrong-id.pdf")
        try writeFixture(to: wrongAttachmentPath)
        try require(
            retire(path: wrongAttachmentPath.path, supportDirectory: supportDirectory) == .rejected,
            "wrong attachment identifier prefix was accepted"
        )

        try require(
            retire(path: "relative/\(attachmentID.uuidString)-file.pdf", supportDirectory: supportDirectory) == .rejected,
            "relative path was accepted"
        )
        try require(
            retire(path: "", supportDirectory: supportDirectory) == .rejected,
            "empty path was accepted"
        )

        for protectedPath in [
            managedFile.path,
            wrongScopeFile.path,
            wrongContainerFile.path,
            prefixCollisionFile.path,
            nestedFile.path,
            documentsPrefixFile.path,
            wrongAttachmentPath.path
        ] {
            try require(pathExistsWithoutFollowingSymlinks(protectedPath), "rejected lexical target was modified")
        }
    }

    private static func testDirectoriesAndSpecialFilesAreRejected(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "special", in: testRoot)
        let documentsDirectory = try makeDocumentsDirectory(
            supportDirectory: supportDirectory,
            scopeID: scopeID
        )

        let directoryTarget = documentsDirectory.appendingPathComponent(
            "\(attachmentID.uuidString)-directory",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directoryTarget, withIntermediateDirectories: false)
        try require(
            retire(path: directoryTarget.path, supportDirectory: supportDirectory) == .rejected,
            "directory target was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(directoryTarget.path), "rejected directory was removed")

        let fifoTarget = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-fifo")
        guard Darwin.mkfifo(fifoTarget.path, S_IRUSR | S_IWUSR) == 0 else {
            throw RetirementTestFailure(description: "synthetic FIFO fixture could not be created")
        }
        try require(
            retire(path: fifoTarget.path, supportDirectory: supportDirectory) == .rejected,
            "special-file target was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(fifoTarget.path), "rejected special file was removed")
    }

    private static func testFinalAndDanglingSymlinksAreRejected(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "final-symlinks", in: testRoot)
        let documentsDirectory = try makeDocumentsDirectory(
            supportDirectory: supportDirectory,
            scopeID: scopeID
        )

        let outsideTarget = testRoot.appendingPathComponent("outside-final-target.pdf")
        try writeFixture(to: outsideTarget)
        let finalSymlink = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-final-link.pdf")
        try createSymlink(at: finalSymlink, destination: outsideTarget.path)
        try require(
            retire(path: finalSymlink.path, supportDirectory: supportDirectory) == .rejected,
            "final symlink was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(finalSymlink.path), "final symlink was removed")
        try require(pathExistsWithoutFollowingSymlinks(outsideTarget.path), "final symlink target was removed")

        let missingTarget = testRoot.appendingPathComponent("missing-symlink-target.pdf")
        let danglingSymlink = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-dangling-link.pdf")
        try createSymlink(at: danglingSymlink, destination: missingTarget.path)
        try require(
            retire(path: danglingSymlink.path, supportDirectory: supportDirectory) == .rejected,
            "dangling final symlink was treated as an absent regular file"
        )
        try require(pathExistsWithoutFollowingSymlinks(danglingSymlink.path), "dangling symlink was removed")
    }

    private static func testSymlinkedOwnedAncestorsAreRejected(in testRoot: URL) throws {
        try testSymlinkedScopeAssetsAncestor(in: testRoot)
        try testSymlinkedScopeAncestor(in: testRoot)
        try testSymlinkedDocumentsAncestor(in: testRoot)
        try testSymlinkedInjectedSupportRoot(in: testRoot)
    }

    private static func testSymlinkedScopeAssetsAncestor(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "scope-assets-link", in: testRoot)
        let outsideScopeAssets = testRoot.appendingPathComponent("outside-scope-assets", isDirectory: true)
        let outsideFile = try makeOutsideOwnedFile(root: outsideScopeAssets, includeScopeDirectory: true)
        try createSymlink(
            at: supportDirectory.appendingPathComponent("ScopeAssets", isDirectory: true),
            destination: outsideScopeAssets.path
        )

        let lexicalPath = documentsPath(supportDirectory: supportDirectory, scopeID: scopeID)
            .appendingPathComponent(outsideFile.lastPathComponent).path
        try require(
            retire(path: lexicalPath, supportDirectory: supportDirectory) == .rejected,
            "symlinked ScopeAssets ancestor was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(outsideFile.path), "file behind ScopeAssets symlink was removed")
    }

    private static func testSymlinkedScopeAncestor(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "scope-link", in: testRoot)
        let scopeAssets = supportDirectory.appendingPathComponent("ScopeAssets", isDirectory: true)
        try FileManager.default.createDirectory(at: scopeAssets, withIntermediateDirectories: true)

        let outsideScope = testRoot.appendingPathComponent("outside-scope", isDirectory: true)
        let outsideFile = try makeOutsideOwnedFile(root: outsideScope, includeScopeDirectory: false)
        try createSymlink(
            at: scopeAssets.appendingPathComponent(scopeID.uuidString, isDirectory: true),
            destination: outsideScope.path
        )

        let lexicalPath = documentsPath(supportDirectory: supportDirectory, scopeID: scopeID)
            .appendingPathComponent(outsideFile.lastPathComponent).path
        try require(
            retire(path: lexicalPath, supportDirectory: supportDirectory) == .rejected,
            "symlinked scope ancestor was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(outsideFile.path), "file behind scope symlink was removed")
    }

    private static func testSymlinkedDocumentsAncestor(in testRoot: URL) throws {
        let supportDirectory = try makeSupportDirectory(named: "documents-link", in: testRoot)
        let scopeDirectory = supportDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: scopeDirectory, withIntermediateDirectories: true)

        let outsideDocuments = testRoot.appendingPathComponent("outside-documents", isDirectory: true)
        try FileManager.default.createDirectory(at: outsideDocuments, withIntermediateDirectories: true)
        let outsideFile = outsideDocuments.appendingPathComponent("\(attachmentID.uuidString)-outside.pdf")
        try writeFixture(to: outsideFile)
        try createSymlink(
            at: scopeDirectory.appendingPathComponent("Documents", isDirectory: true),
            destination: outsideDocuments.path
        )

        let lexicalPath = documentsPath(supportDirectory: supportDirectory, scopeID: scopeID)
            .appendingPathComponent(outsideFile.lastPathComponent).path
        try require(
            retire(path: lexicalPath, supportDirectory: supportDirectory) == .rejected,
            "symlinked Documents ancestor was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(outsideFile.path), "file behind Documents symlink was removed")
    }

    private static func testSymlinkedInjectedSupportRoot(in testRoot: URL) throws {
        let realSupportDirectory = try makeSupportDirectory(named: "real-support", in: testRoot)
        let documentsDirectory = try makeDocumentsDirectory(
            supportDirectory: realSupportDirectory,
            scopeID: scopeID
        )
        let protectedFile = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-protected.pdf")
        try writeFixture(to: protectedFile)

        let linkedSupportDirectory = testRoot.appendingPathComponent("linked-support", isDirectory: true)
        try createSymlink(at: linkedSupportDirectory, destination: realSupportDirectory.path)
        let lexicalPath = documentsPath(supportDirectory: linkedSupportDirectory, scopeID: scopeID)
            .appendingPathComponent(protectedFile.lastPathComponent).path
        try require(
            retire(path: lexicalPath, supportDirectory: linkedSupportDirectory) == .rejected,
            "symlinked injected support root was accepted"
        )
        try require(pathExistsWithoutFollowingSymlinks(protectedFile.path), "file behind support-root symlink was removed")
    }

    private static func retire(path: String, supportDirectory: URL) -> DocumentAssetRetirementOutcome {
        DocumentAssetRetirement.retire(
            attachmentID: attachmentID,
            path: path,
            scopeID: scopeID,
            applicationSupportDirectory: supportDirectory
        )
    }

    private static func makeSupportDirectory(named name: String, in testRoot: URL) throws -> URL {
        let directory = testRoot
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func makeDocumentsDirectory(
        supportDirectory: URL,
        scopeID: UUID
    ) throws -> URL {
        let directory = documentsPath(supportDirectory: supportDirectory, scopeID: scopeID)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func documentsPath(supportDirectory: URL, scopeID: UUID) -> URL {
        supportDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
    }

    private static func makeOutsideOwnedFile(
        root: URL,
        includeScopeDirectory: Bool
    ) throws -> URL {
        let documentsDirectory: URL
        if includeScopeDirectory {
            documentsDirectory = root
                .appendingPathComponent(scopeID.uuidString, isDirectory: true)
                .appendingPathComponent("Documents", isDirectory: true)
        } else {
            documentsDirectory = root.appendingPathComponent("Documents", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        let file = documentsDirectory.appendingPathComponent("\(attachmentID.uuidString)-outside.pdf")
        try writeFixture(to: file)
        return file
    }

    private static func writeFixture(to url: URL) throws {
        do {
            try Data("synthetic fixture".utf8).write(to: url, options: .atomic)
        } catch {
            throw RetirementTestFailure(description: "synthetic regular-file fixture could not be created")
        }
    }

    private static func createSymlink(at url: URL, destination: String) throws {
        guard Darwin.symlink(destination, url.path) == 0 else {
            throw RetirementTestFailure(description: "synthetic symlink fixture could not be created")
        }
    }

    private static func pathExistsWithoutFollowingSymlinks(_ path: String) -> Bool {
        var metadata = stat()
        return Darwin.lstat(path, &metadata) == 0
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw RetirementTestFailure(description: message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(
            Data("Document asset retirement verification failed: \(message)\n".utf8)
        )
        Foundation.exit(1)
    }
}
