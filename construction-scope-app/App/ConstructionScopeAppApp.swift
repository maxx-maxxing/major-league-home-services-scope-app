import SwiftUI
import SwiftData

private let jobTreadDebugWindowID = "jobtread-debug-window"

@main
struct ConstructionScopeAppApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if let startupIssue = persistenceController.startupIssue {
                PersistenceRecoveryView(startupIssue: startupIssue)
            } else {
                RootNavigationView()
            }
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

private struct PersistenceRecoveryView: View {
    let startupIssue: PersistenceStartupIssue

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Local Data Unavailable",
                systemImage: "externaldrive.badge.exclamationmark",
                description: Text(startupIssue.detailedDescription)
            )
            .padding()
            .navigationTitle("Construction Scope")
        }
    }
}
