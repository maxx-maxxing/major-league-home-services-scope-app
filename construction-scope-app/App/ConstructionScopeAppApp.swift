import SwiftUI
import SwiftData

private let jobTreadDebugWindowID = "jobtread-debug-window"

@main
struct ConstructionScopeAppApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
        }
        .modelContainer(persistenceController.container)

#if DEBUG
        WindowGroup("JobTread Debug", id: jobTreadDebugWindowID) {
            JobTreadDebugView()
        }
        .modelContainer(persistenceController.container)
#endif
    }
}
