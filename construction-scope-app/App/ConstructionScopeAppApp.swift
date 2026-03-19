import SwiftUI
import SwiftData

@main
struct ConstructionScopeAppApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
        }
        .modelContainer(persistenceController.container)

#if DEBUG
        WindowGroup("JobTread Debug") {
            JobTreadDebugView()
        }
#endif
    }
}
