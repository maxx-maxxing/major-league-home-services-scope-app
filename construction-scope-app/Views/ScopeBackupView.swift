import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension UTType {
    static let scopeBackup = UTType(exportedAs: "com.maxxlazos.scopes.backup", conformingTo: .json)
}

/// A backup is prepared locally. Sharing and restoring each require an explicit
/// user action; choosing an import file never changes an existing scope.
struct ScopeBackupView: View {
    let scopes: [JobScope]
    let service: ScopeBackupService

    @Environment(\.dismiss) private var dismiss
    @State private var showingImporter = false
    @State private var stagedBackup: StagedScopeBackup?
    @State private var importedFilename = ""
    @State private var conflictingScopeIDs: Set<UUID> = []
    @State private var conflictPolicy: ScopeBackupConflictPolicy = .skipExisting
    @State private var exportURL: URL?
    @State private var operationTask: Task<Void, Never>?
    @State private var operationLabel: String?
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var scopeToExportID: UUID?

    private var isBusy: Bool { operationLabel != nil }
    private var exportScopes: [JobScope] {
        guard let scopeToExportID else { return scopes }
        return scopes.filter { $0.id == scopeToExportID }
    }

    private var restorableCount: Int {
        guard let stagedBackup else { return 0 }
        switch conflictPolicy {
        case .skipExisting: return stagedBackup.records.count - conflictingScopeIDs.count
        case .keepBoth: return stagedBackup.records.count
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Scopes on this device", value: "\(scopes.count)")
                    Text("Backups contain editable scopes, original attachments, drawings and review marks. PDF exports are separate.")
                        .foregroundStyle(.secondary)
                }

                Section("Create a Backup") {
                    Picker("Include", selection: $scopeToExportID) {
                        Text("All Local Scopes").tag(UUID?.none)
                        ForEach(scopes, id: \.id) { scope in
                            Text(scope.displayName).tag(Optional(scope.id))
                        }
                    }
                    .disabled(isBusy)
                    Button(action: prepareBackup) {
                        Label("Prepare Backup", systemImage: "externaldrive.badge.plus")
                            .frame(minHeight: 44)
                    }
                    .disabled(scopes.isEmpty || isBusy)
                    .accessibilityHint("Prepares all local scopes and their files without sending them anywhere.")

                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Save or Share Backup", systemImage: "square.and.arrow.up")
                                .frame(minHeight: 44)
                        }
                        .disabled(isBusy)
                        Text(exportURL.lastPathComponent)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    Text("A backup includes customer information and original files. Save it in a private location you control. The backup file is not password protected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Restore a Backup") {
                    Button(action: chooseBackup) {
                        Label("Choose Backup", systemImage: "folder")
                            .frame(minHeight: 44)
                    }
                    .disabled(isBusy)
                    .accessibilityHint("Choose a backup to validate and review before restoring it.")

                    if let stagedBackup {
                        restorePreview(stagedBackup)
                    } else {
                        Text("Choose a Scopes backup from Files. You can review its contents before restoring. Existing scopes are never replaced.")
                            .foregroundStyle(.secondary)
                    }
                }

                if let operationLabel {
                    Section {
                        ProgressView(operationLabel)
                            .frame(minHeight: 44)
                            .accessibilityLabel(operationLabel)
                    }
                }

                if let statusMessage {
                    Section {
                        Label(statusMessage, systemImage: "checkmark.circle")
                            .accessibilityElement(children: .combine)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Backup & Restore")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .disabled(isBusy)
                }
            }
            .interactiveDismissDisabled(isBusy)
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.scopeBackup, .json, .data],
                onCompletion: importSelectedFile
            )
            .alert("Backup & Restore", isPresented: errorPresented) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "The operation could not be completed.")
            }
            .onDisappear(perform: cleanup)
        }
    }

    @ViewBuilder
    private func restorePreview(_ staged: StagedScopeBackup) -> some View {
        Label("Backup Validated", systemImage: "checkmark.shield")
            .font(.headline)
        Text(importedFilename)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        LabeledContent("Scopes", value: "\(staged.records.count)")
        LabeledContent("Files", value: "\(staged.assetCount)")
        LabeledContent("Original file size", value: ByteCountFormatter.string(fromByteCount: Int64(staged.totalAssetBytes), countStyle: .file))

        ForEach(Array(staged.records.prefix(8)), id: \.id) { record in
            VStack(alignment: .leading, spacing: 4) {
                Text(record.scopeTitle?.nilIfWhitespaceOnly ?? record.projectInfo.clientName.nilIfWhitespaceOnly ?? "Untitled Scope")
                if conflictingScopeIDs.contains(record.id) {
                    Text("Already on this device")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
        if staged.records.count > 8 {
            Text("And \(staged.records.count - 8) more scopes")
                .foregroundStyle(.secondary)
        }

        if !conflictingScopeIDs.isEmpty {
            LabeledContent("Existing scopes", value: "\(conflictingScopeIDs.count)")
            Picker("When a scope already exists", selection: $conflictPolicy) {
                Text("Skip Existing").tag(ScopeBackupConflictPolicy.skipExisting)
                Text("Keep Both").tag(ScopeBackupConflictPolicy.keepBoth)
            }
            .disabled(isBusy)
            Text("Skip Existing leaves those scopes untouched. Keep Both restores separate copies with new scope identifiers. JobTread records are not changed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        Button(action: restoreBackup) {
            Label("Restore \(restorableCount) \(restorableCount == 1 ? "Scope" : "Scopes")", systemImage: "arrow.down.doc")
                .frame(minHeight: 44)
        }
        .disabled(isBusy || restorableCount == 0)
        .accessibilityHint("Restores the reviewed scopes and their files locally.")

        Button("Cancel Import", role: .cancel) { discardStagedBackup() }
            .frame(minHeight: 44)
            .disabled(isBusy)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func prepareBackup() {
        guard !isBusy, !scopes.isEmpty else { return }
        operationLabel = "Preparing backup…"
        statusMessage = nil
        operationTask = Task { @MainActor in
            defer { operationLabel = nil; operationTask = nil }
            do {
                let url = try await service.export(scopes: exportScopes)
                guard !Task.isCancelled else {
                    service.discardExport(fileURL: url)
                    return
                }
                if let exportURL { service.discardExport(fileURL: exportURL) }
                exportURL = url
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
        }
    }

    private func chooseBackup() {
        guard !isBusy else { return }
        discardStagedBackup()
        statusMessage = nil
        showingImporter = true
    }

    private func importSelectedFile(_ result: Result<URL, Error>) {
        guard !isBusy else { return }
        switch result {
        case .success(let url):
            operationLabel = "Validating backup…"
            operationTask = Task { @MainActor in
                defer { operationLabel = nil; operationTask = nil }
                do {
                    let staged = try await service.stage(fileURL: url)
                    guard !Task.isCancelled else {
                        service.discard(staged)
                        return
                    }
                    do {
                        conflictingScopeIDs = try service.conflicts(in: staged)
                    } catch {
                        service.discard(staged)
                        throw error
                    }
                    stagedBackup = staged
                    importedFilename = url.lastPathComponent
                    conflictPolicy = .skipExisting
                } catch {
                    if !Task.isCancelled { errorMessage = error.localizedDescription }
                }
            }
        case .failure(let error):
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = "The selected backup could not be opened. Choose a locally available file and try again."
            }
        }
    }

    private func restoreBackup() {
        guard !isBusy, let stagedBackup, restorableCount > 0 else { return }
        operationLabel = "Restoring backup…"
        statusMessage = nil
        operationTask = Task { @MainActor in
            defer { operationLabel = nil; operationTask = nil }
            do {
                let result = try await service.restore(stagedBackup, policy: conflictPolicy)
                statusMessage = "Restored \(result.restoredCount) \(result.restoredCount == 1 ? "scope" : "scopes"). Skipped \(result.skippedCount) existing \(result.skippedCount == 1 ? "scope" : "scopes")."
                discardStagedBackup()
            } catch {
                // Require a fresh conflict preview if metadata committed before a recovery error.
                discardStagedBackup()
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
        }
    }

    private func discardStagedBackup() {
        if let stagedBackup { service.discard(stagedBackup) }
        stagedBackup = nil
        conflictingScopeIDs = []
        importedFilename = ""
    }

    private func cleanup() {
        operationTask?.cancel()
        discardStagedBackup()
        if let exportURL { service.discardExport(fileURL: exportURL) }
        exportURL = nil
    }
}
