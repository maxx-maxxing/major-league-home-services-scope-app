import SwiftUI
import SwiftData

#if DEBUG
private let jobTreadDebugViewWindowID = "jobtread-debug-window"
private let jobTreadDebugSelectedScopeStorageKey = "debug.selected-scope-id"

struct JobTreadDebugView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @AppStorage(jobTreadDebugSelectedScopeStorageKey) private var debugSelectedScopeIDStorage = ""
    @Query(sort: \JobScope.updatedAt, order: .reverse) private var scopes: [JobScope]

    @State private var statusMessage = "Idle"
    @State private var isLoading = false
    @State private var resultText: String = ""
    @State private var errorText: String = ""
    @State private var selectedScopeID: UUID?

    private let client = JobTreadClient()

    private var selectedScope: JobScope? {
        guard let selectedScopeID else { return scopes.first }
        return scopes.first(where: { $0.id == selectedScopeID }) ?? scopes.first
    }

    private var selectedSnapshot: ProposalFoundationSnapshot? {
        selectedScope?.proposalFoundationSnapshot
    }

    var body: some View {
        NavigationStack {
            List {
                connectivitySection
                proposalInspectorSection
            }
            .navigationTitle("JobTread Debug")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close Debug") {
                        dismissWindow(id: jobTreadDebugViewWindowID)
                    }
                    .fontWeight(.semibold)
                    .accessibilityHint("Closes the internal debug window and returns focus to the main app.")
                }
            }
            .task {
                syncSelectedScope()
            }
            .onChange(of: scopes.map(\.id)) { _, _ in
                syncSelectedScope()
            }
        }
    }

    private var connectivitySection: some View {
        Section("Connectivity Test") {
            Text("Runs the JobTread `currentGrant` query using the Info.plist-backed debug configuration.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                runConnectivityTest()
            } label: {
                Label("Fetch Current Grant", systemImage: "network")
            }
            .disabled(isLoading)

            HStack {
                Text("Status")
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if !resultText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result")
                        .font(.headline)

                    Text(resultText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }

            if !errorText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error")
                        .font(.headline)

                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var proposalInspectorSection: some View {
        Section("Proposal Foundation Inspector") {
            Text("Internal read-only inspector for the pricing/proposal foundation. It reads the composed snapshot from the current scope without changing the production workflow.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if scopes.isEmpty {
                Text("No scopes available to inspect.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Scope", selection: $selectedScopeID) {
                    ForEach(scopes, id: \.id) { scope in
                        Text(scope.displayName)
                            .tag(Optional(scope.id))
                    }
                }
                .pickerStyle(.menu)

                if let scope = selectedScope,
                   let snapshot = selectedSnapshot {
                    ProposalInspectorSummary(scope: scope, snapshot: snapshot)
                    ProposalInspectorInputsView(snapshot: snapshot)
                    ProposalInspectorSectionsView(snapshot: snapshot)
                    ProposalInspectorPricingView(snapshot: snapshot)
                    ProposalInspectorSyncView(snapshot: snapshot)
                }
            }
        }
    }

    private func syncSelectedScope() {
        guard !scopes.isEmpty else {
            selectedScopeID = nil
            return
        }

        if let preferredScopeID = UUID(uuidString: debugSelectedScopeIDStorage),
           scopes.contains(where: { $0.id == preferredScopeID }) {
            selectedScopeID = preferredScopeID
            return
        }

        if let selectedScopeID,
           scopes.contains(where: { $0.id == selectedScopeID }) {
            return
        }

        selectedScopeID = scopes.first?.id
    }

    private func runConnectivityTest() {
        isLoading = true
        statusMessage = "Loading..."
        resultText = ""
        errorText = ""

        Task {
            do {
                let currentGrant = try await client.fetchCurrentGrant()
                let formattedResult = formatCurrentGrant(currentGrant)
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Success"
                    resultText = formattedResult
                }
                logCurrentGrant(currentGrant)
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Failed"
                    errorText = error.localizedDescription
                }
                print("[JobTread] currentGrant request failed: \(error.localizedDescription)")
            }
        }
    }

    private func formatCurrentGrant(_ currentGrant: JobTreadCurrentGrant) -> String {
        var lines: [String] = [
            "Grant ID: \(currentGrant.id)",
            "User ID: \(currentGrant.user.id)",
            "User Name: \(currentGrant.user.name)",
            "Organizations:"
        ]

        if currentGrant.user.memberships.nodes.isEmpty {
            lines.append("- none")
        } else {
            for membership in currentGrant.user.memberships.nodes {
                lines.append("- \(membership.organization.name) (\(membership.organization.id))")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func logCurrentGrant(_ currentGrant: JobTreadCurrentGrant) {
        print("[JobTread] currentGrant.id: \(currentGrant.id)")
        print("[JobTread] user.id: \(currentGrant.user.id)")
        print("[JobTread] user.name: \(currentGrant.user.name)")

        if currentGrant.user.memberships.nodes.isEmpty {
            print("[JobTread] memberships: none")
            return
        }

        for (index, membership) in currentGrant.user.memberships.nodes.enumerated() {
            print("[JobTread] membership[\(index)].organization.id: \(membership.organization.id)")
            print("[JobTread] membership[\(index)].organization.name: \(membership.organization.name)")
        }
    }
}

private struct ProposalInspectorSummary: View {
    let scope: JobScope
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Scope") {
                Text(scope.displayName)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Template") {
                Text("\(snapshot.template.name) v\(snapshot.template.version)")
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Proposal Title") {
                Text(snapshot.proposal.proposalTitle)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Captured") {
                Text(snapshot.input.capturedAt.formatted(date: .abbreviated, time: .standard))
                    .multilineTextAlignment(.trailing)
            }
        }
        .font(.footnote)
    }
}

private struct ProposalInspectorInputsView: View {
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Normalized Inputs", systemImage: "slider.horizontal.3")
                .font(.headline)

            ForEach(snapshot.input.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.section.title)
                        .font(.subheadline.weight(.semibold))

                    ForEach(section.values) { value in
                        ProposalInspectorValueRow(
                            title: value.label,
                            detail: value.displayValue,
                            meta: value.key.rawValue
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ProposalInspectorSectionsView: View {
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Proposal Sections", systemImage: "square.text.square")
                .font(.headline)

            ForEach(snapshot.proposal.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(section.isIncluded ? "Included" : "Excluded")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(section.isIncluded ? .green : .secondary)
                    }

                    Text("Source: \(section.sourceSections.map(\.title).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if section.highlights.isEmpty {
                        Text("No mapped highlights.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(section.highlights, id: \.self) { highlight in
                            Text(highlight)
                                .font(.footnote)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ProposalInspectorPricingView: View {
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pricing Groups", systemImage: "dollarsign.square")
                .font(.headline)

            ForEach(snapshot.proposal.pricingGroups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.title)
                        .font(.subheadline.weight(.semibold))

                    Text("Source: \(group.sourceSections.map(\.title).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(group.components) { component in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(component.title)
                                    .font(.footnote.weight(.semibold))
                                Spacer()
                                Text(component.isCandidate ? "Candidate" : "Empty")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(component.isCandidate ? .green : .secondary)
                            }

                            Text(component.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Text("Strategy: \(component.strategy.rawValue)")
                                if let quantitySource = component.quantitySource {
                                    Text("Qty Source: \(quantitySource.rawValue)")
                                }
                                if let quantityValue = component.quantityValue {
                                    Text("Qty: \(proposalInspectorNumberFormatter.string(from: NSNumber(value: quantityValue)) ?? "\(quantityValue)")")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if component.mappedValues.isEmpty {
                                Text("No mapped values.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(component.mappedValues) { value in
                                    ProposalInspectorValueRow(
                                        title: value.label,
                                        detail: value.displayValue,
                                        meta: value.key.rawValue
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ProposalInspectorSyncView: View {
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Future Sync Preview", systemImage: "arrow.triangle.branch")
                .font(.headline)

            if snapshot.syncPreview.candidates.isEmpty {
                Text("No sync candidates composed for this scope.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.syncPreview.candidates) { candidate in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(candidate.blueprint.title)
                            .font(.subheadline.weight(.semibold))

                        Text("\(candidate.blueprint.kind.rawValue) -> \(candidate.blueprint.targetKey)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let notes = candidate.blueprint.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if candidate.previewValues.isEmpty {
                            Text("No preview values.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(candidate.previewValues, id: \.self) { previewValue in
                                Text(previewValue)
                                    .font(.footnote)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct ProposalInspectorValueRow: View {
    let title: String
    let detail: String
    let meta: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.footnote)
                Spacer(minLength: 12)
                Text(detail)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            Text(meta)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
        }
    }
}

private let proposalInspectorNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 0
    return formatter
}()
#endif
