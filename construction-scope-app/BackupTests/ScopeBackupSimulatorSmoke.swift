import SwiftUI
import Foundation

/// Task-only entry point. Never add this file to the production application.
/// Build with BACKUP_SIMULATOR_SMOKE and include ScopeBackupTests.swift plus
/// PersistenceFixtureValues.swift. The real backup engine/service are exercised
/// in a dedicated test app's fresh container; no installed Scopes store is read.
@main
struct ScopeBackupSimulatorSmokeApp: App {
    var body: some Scene {
        WindowGroup { ScopeBackupSimulatorSmokeView() }
    }
}

private struct ScopeBackupSimulatorSmokeView: View {
    @State private var result = "Running synthetic backup and recovery checks…"
    @State private var finished = false
    @State private var succeeded = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: finished ? (succeeded ? "checkmark.shield" : "exclamationmark.triangle") : "externaldrive")
                .font(.largeTitle)
            Text("Scopes Backup Recovery Test")
                .font(.title)
            Text(result)
                .font(.body)
                .textSelection(.enabled)
            if finished && succeeded {
                ShareLink("Share Fictional Recovery Fixture", item: fixtureURL)
                    .buttonStyle(.borderedProminent)
            }
            if !finished { ProgressView() }
        }
        .padding(32)
        .task { await run() }
    }

    @MainActor
    private func run() async {
        do {
            let manager = FileManager.default
            let support = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let workspace = support.appendingPathComponent("BackupSmoke", isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
            try manager.createDirectory(at: workspace, withIntermediateDirectories: true)
            try Data("synthetic simulator backup fixture only".utf8).write(to: workspace.appendingPathComponent(".scope-backup-harness"))
            try await ScopeBackupTests.run(at: workspace)
            try manager.createDirectory(at: fixtureURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !manager.fileExists(atPath: fixtureURL.path) {
                try manager.copyItem(at: workspace.appendingPathComponent("Synthetic.scopebackup"), to: fixtureURL)
            }
            result = "PASS: complete scope and asset archive; fresh-store restore/reopen; review state; skip/keep-both conflicts; validation and interrupted recovery."
            try writeResult(passed: true, detail: result)
            succeeded = true
            finished = true
        } catch {
            result = "FAIL: \(error)"
            try? writeResult(passed: false, detail: result)
            finished = true
        }
    }

    private var fixtureURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("RecoveryFixture.scopebackup")
    }

    @MainActor
    private func writeResult(passed: Bool, detail: String) throws {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let payload: [String: Any] = [
            "passed": passed,
            "detail": detail,
            "completedAt": ISO8601DateFormatter().string(from: .now),
            "fixtureKind": "fictional-app-owned-only",
            "skippedChecks": ScopeBackupTests.skippedChecks
        ]
        try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("BackupSmokeResults.json"), options: .atomic)
    }
}
