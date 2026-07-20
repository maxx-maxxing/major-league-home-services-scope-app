import Foundation
import SwiftData

@main
struct BaselineStoreWriter {
    static func main() {
        do {
            try run()
        } catch {
            FileHandle.standardError.write(
                Data("Baseline fixture writer failed: \(error)\n".utf8)
            )
            exit(EXIT_FAILURE)
        }
    }

    private static func run() throws {
        guard CommandLine.arguments.count == 2 else {
            throw PersistenceCompatibilityHarnessError.invalidArguments
        }

        let storeURL = try PersistenceHarnessPathGuard.validatedStoreURL(
            CommandLine.arguments[1],
            mustExist: false
        )
        let schema = Schema([JobScope.self])
        let configuration = ModelConfiguration(
            "ContinuityFixture",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let scope = PersistenceFixtureValues.makeBaselineScope()
        context.insert(scope)
        try context.save()

        print("Baseline persistence fixture created")
    }
}

private enum PersistenceCompatibilityHarnessError: Error {
    case invalidArguments
}
