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

            LabeledContent("Pricing Config") {
                Text("\(snapshot.pricingConfiguration.id) v\(snapshot.pricingConfiguration.version)")
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Config Source") {
                Text(snapshot.pricingConfiguration.sourceKind.rawValue)
                    .multilineTextAlignment(.trailing)
            }

            if let importReport = snapshot.pricingConfiguration.importReport {
                LabeledContent("Import Status") {
                    Text(importReport.status)
                        .multilineTextAlignment(.trailing)
                }
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

    private func aggregateDetail(placeholderKey: String, amount: Double?) -> String {
        if let amount {
            let formatted = proposalInspectorCurrencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "\(placeholderKey) = \(formatted)"
        }
        return placeholderKey
    }
}

private struct ProposalInspectorSectionsView: View {
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Proposal Sections", systemImage: "square.text.square")
                .font(.headline)

            if snapshot.proposal.customerFacingSections.isEmpty {
                Text("No customer-facing proposal sections are currently included.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

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

                    Text(section.inclusionReason)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !section.relatedPricingGroupIDs.isEmpty {
                        Text("Related Pricing Groups: \(section.relatedPricingGroupIDs.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if section.customerFacingValues.isEmpty {
                        Text("No customer-facing values.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        Text("Customer-Facing")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(section.customerFacingValues) { value in
                            ProposalInspectorValueRow(
                                title: value.label,
                                detail: value.displayValue,
                                meta: value.key.rawValue
                            )
                        }
                    }

                    if !section.internalValues.isEmpty {
                        Text("Internal-Only")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(section.internalValues) { value in
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
    }
}

private struct ProposalInspectorPricingView: View {
    let snapshot: ProposalFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pricing Buckets", systemImage: "dollarsign.square")
                .font(.headline)

            if let importReport = snapshot.pricingConfiguration.importReport {
                ProposalInspectorPricingImportReportView(importReport: importReport)
            }

            ProposalInspectorValueRow(
                title: "Proposal Total",
                detail: aggregateDetail(
                    placeholderKey: snapshot.proposal.total.placeholderKey,
                    amount: snapshot.proposal.total.amount
                ),
                meta: snapshot.proposal.total.executionStatus.rawValue
            )

            Text(snapshot.proposal.total.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !snapshot.proposal.total.missingInputs.isEmpty {
                Text("Proposal Missing Inputs: \(snapshot.proposal.total.missingInputs.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !snapshot.proposal.total.trace.isEmpty {
                Text("Proposal Total Trace")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(snapshot.proposal.total.trace) { traceEntry in
                    ProposalInspectorValueRow(
                        title: traceEntry.title,
                        detail: traceEntry.detail,
                        meta: traceEntry.key
                    )
                }
            }

            ForEach(snapshot.proposal.pricingGroups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(group.isIncluded ? "Active" : "Inactive")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(group.isIncluded ? .green : .secondary)
                    }

                    Text("Source: \(group.sourceSections.map(\.title).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Channels: \(group.outputChannels.map(\.rawValue).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ProposalInspectorValueRow(
                        title: "Future Group Total",
                        detail: group.futureTotal.placeholderKey,
                        meta: group.futureTotal.status.rawValue
                    )

                    Text(group.futureTotal.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !group.futureTotal.componentSubtotalKeys.isEmpty {
                        Text("Rolls Up: \(group.futureTotal.componentSubtotalKeys.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProposalInspectorValueRow(
                        title: "Group Total",
                        detail: aggregateDetail(
                            placeholderKey: group.total.placeholderKey,
                            amount: group.total.amount
                        ),
                        meta: group.total.executionStatus.rawValue
                    )

                    Text(group.total.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !group.total.missingInputs.isEmpty {
                        Text("Group Missing Inputs: \(group.total.missingInputs.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !group.total.trace.isEmpty {
                        Text("Group Total Trace")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(group.total.trace) { traceEntry in
                            ProposalInspectorValueRow(
                                title: traceEntry.title,
                                detail: traceEntry.detail,
                                meta: traceEntry.key
                            )
                        }
                    }

                    ForEach(group.components) { component in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(component.title)
                                    .font(.footnote.weight(.semibold))
                                Spacer()
                                Text(component.bucketState.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(component.isCandidate ? .green : .secondary)
                            }

                            Text(component.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(component.inclusionReason)
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

                            Text("Channels: \(component.outputChannels.map(\.rawValue).joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ProposalInspectorSeedConfigView(seedConfig: component.seedConfig)

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

    private func aggregateDetail(placeholderKey: String, amount: Double?) -> String {
        if let amount {
            let formatted = proposalInspectorCurrencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "\(placeholderKey) = \(formatted)"
        }
        return placeholderKey
    }
}

private struct ProposalInspectorPricingImportReportView: View {
    let importReport: PricingConfigurationImportReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pricing Import Boundary")
                .font(.subheadline.weight(.semibold))

            ProposalInspectorValueRow(
                title: "Adapter",
                detail: importReport.adapterID,
                meta: importReport.sourceKind.rawValue
            )

            ProposalInspectorValueRow(
                title: "Rows",
                detail: "\(importReport.appliedRowCount) applied / \(importReport.importedRowCount) imported",
                meta: importReport.issues.isEmpty ? "validated" : "\(importReport.issues.count) issues"
            )

            if let normalizationReport = importReport.normalizationReport {
                ProposalInspectorValueRow(
                    title: "Returned Sheet",
                    detail: "\(normalizationReport.normalizedRowCount) normalized / \(normalizationReport.sourceRowCount) source",
                    meta: "\(normalizationReport.skippedRowCount) skipped • \(normalizationReport.notReadyRowCount) not ready"
                )

                Text(normalizationReport.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(importReport.status)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !importReport.issues.isEmpty {
                ForEach(importReport.issues.prefix(5)) { issue in
                    ProposalInspectorValueRow(
                        title: issue.severity.rawValue.capitalized,
                        detail: issue.message,
                        meta: issueMeta(issue)
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func issueMeta(_ issue: PricingImportIssue) -> String {
        if let rowID = issue.rowID {
            return "\(issue.stage.rawValue) • \(rowID)"
        }
        return issue.stage.rawValue
    }
}

private struct ProposalInspectorSeedConfigView: View {
    let seedConfig: PricingBucketSeedConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Draft Seed / Config")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ProposalInspectorValueRow(
                title: "Bucket ID",
                detail: seedConfig.bucketID,
                meta: "bucket_id"
            )

            ProposalInspectorValueRow(
                title: "Group ID",
                detail: seedConfig.groupID,
                meta: "group_id"
            )

            ProposalInspectorValueRow(
                title: "Display Name",
                detail: seedConfig.displayName,
                meta: "display_name"
            )

            ProposalInspectorValueRow(
                title: "Quantity Basis",
                detail: seedConfig.quantityBasisLabel ?? "Not seeded",
                meta: seedConfig.quantitySource?.rawValue ?? "quantity_basis"
            )

            ProposalInspectorValueRow(
                title: "Quantity Seed",
                detail: seedConfig.quantitySeed.map {
                    proposalInspectorNumberFormatter.string(from: NSNumber(value: $0)) ?? "\($0)"
                } ?? "Not seeded",
                meta: seedConfig.unitLabel ?? "quantity_seed"
            )

            ProposalInspectorValueRow(
                title: "Draft Unit Cost Slot",
                detail: configuredSlotDetail(
                    placeholderKey: seedConfig.draftUnitCost.placeholderKey,
                    amount: seedConfig.draftUnitCost.amount,
                    unitLabel: seedConfig.unitLabel
                ),
                meta: seedConfig.draftUnitCost.status
            )

            ProposalInspectorValueRow(
                title: "Draft Unit Price Slot",
                detail: configuredSlotDetail(
                    placeholderKey: seedConfig.draftUnitPrice.placeholderKey,
                    amount: seedConfig.draftUnitPrice.amount,
                    unitLabel: seedConfig.unitLabel
                ),
                meta: seedConfig.draftUnitPrice.status
            )

            ProposalInspectorValueRow(
                title: "Rule Placeholder",
                detail: seedConfig.draftRuleKey ?? "None",
                meta: "rule_key"
            )

            ProposalInspectorValueRow(
                title: "Formula Placeholder",
                detail: seedConfig.draftFormulaKey ?? "None",
                meta: "formula_key"
            )

            ProposalInspectorValueRow(
                title: "Subtotal Placeholder",
                detail: configuredSlotDetail(
                    placeholderKey: seedConfig.subtotal.placeholderKey,
                    amount: seedConfig.subtotal.amount
                ),
                meta: seedConfig.subtotal.status
            )

            ProposalInspectorValueRow(
                title: "Subtotal Readiness",
                detail: seedConfig.subtotal.executionStatus.rawValue,
                meta: seedConfig.subtotal.source.rawValue
            )

            if let derivationKind = seedConfig.subtotal.derivationKind {
                ProposalInspectorValueRow(
                    title: "Subtotal Derivation Kind",
                    detail: derivationKind.rawValue,
                    meta: seedConfig.subtotal.formulaStrategy?.rawValue ?? "no_formula_strategy"
                )
            }

            Text(seedConfig.subtotal.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !seedConfig.subtotal.missingInputs.isEmpty {
                Text("Missing Inputs: \(seedConfig.subtotal.missingInputs.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !seedConfig.subtotal.trace.isEmpty {
                Text("Subtotal Trace")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(seedConfig.subtotal.trace) { traceEntry in
                    ProposalInspectorValueRow(
                        title: traceEntry.title,
                        detail: traceEntry.detail,
                        meta: traceEntry.key
                    )
                }
            }

            if let lookupAdjustment = seedConfig.subtotal.lookupAdjustment {
                ProposalInspectorValueRow(
                    title: "Lookup Contract",
                    detail: lookupAdjustment.status.rawValue,
                    meta: lookupAdjustment.supportedAdjustments.joined(separator: ", ").nilIfBlank ?? "no_supported_adjustments"
                )

                ProposalInspectorValueRow(
                    title: "Lookup Execution Path",
                    detail: lookupAdjustment.executionPath.rawValue,
                    meta: lookupAdjustment.typedExecution?.family.rawValue ?? "generic_lookup"
                )

                Text(lookupAdjustment.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let typedExecution = lookupAdjustment.typedExecution {
                    ProposalInspectorValueRow(
                        title: "Typed Lookup Family",
                        detail: typedExecution.family.rawValue,
                        meta: typedExecution.status.rawValue
                    )

                    ProposalInspectorValueRow(
                        title: "Typed Schedule Input",
                        detail: typedExecution.scheduleInputKey,
                        meta: typedExecution.scheduleValue ?? "no_schedule_value"
                    )

                    if let matchedContractID = typedExecution.matchedContractID {
                        ProposalInspectorValueRow(
                            title: "Matched Contract",
                            detail: matchedContractID,
                            meta: "typed_lookup_contract"
                        )
                    }

                    Text(typedExecution.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(Array(typedExecution.normalizedInputDetails.enumerated()), id: \.offset) { item in
                        Text(item.element)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !lookupAdjustment.supportedBaseComponents.isEmpty {
                    Text("Supported Base Components: \(lookupAdjustment.supportedBaseComponents.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !lookupAdjustment.observedScheduleInputKeys.isEmpty {
                    Text("Observed Schedule Keys: \(lookupAdjustment.observedScheduleInputKeys.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !lookupAdjustment.deferredScheduleInputKeys.isEmpty {
                    Text("Deferred Schedule Keys: \(lookupAdjustment.deferredScheduleInputKeys.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProposalInspectorResolvedRuleView(resolvedRule: seedConfig.resolvedRule)
            ProposalInspectorResolvedConfigurationView(resolvedConfiguration: seedConfig.resolvedConfiguration)

            Text(seedConfig.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !seedConfig.notes.isEmpty {
                Text("Notes: \(seedConfig.notes.joined(separator: " | "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !seedConfig.assumptions.isEmpty {
                Text("Assumptions: \(seedConfig.assumptions.joined(separator: " | "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Output Hints: \(seedConfig.outputChannelHints.map(\.rawValue).joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct ProposalInspectorResolvedConfigurationView: View {
    let resolvedConfiguration: ResolvedPricingConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProposalInspectorValueRow(
                title: "Pricing Config Source",
                detail: resolvedConfiguration.profileID ?? resolvedConfiguration.snapshotID,
                meta: resolvedConfiguration.status
            )

            if let profileSourceKind = resolvedConfiguration.profileSourceKind {
                ProposalInspectorValueRow(
                    title: "Profile Source",
                    detail: profileSourceKind.rawValue,
                    meta: resolvedConfiguration.profileSourceDescription ?? resolvedConfiguration.sourceDescription
                )
            }

            if let profileTitle = resolvedConfiguration.profileTitle {
                ProposalInspectorValueRow(
                    title: "Config Profile",
                    detail: profileTitle,
                    meta: resolvedConfiguration.sourceDescription
                )
            }

            ForEach(configuredValues) { value in
                ProposalInspectorValueRow(
                    title: value.title,
                    detail: configuredValueDetail(value),
                    meta: value.kind.rawValue
                )
            }

            if !resolvedConfiguration.scheduleInputs.isEmpty {
                Text("Schedule Inputs")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(resolvedConfiguration.scheduleInputs) { input in
                    ProposalInspectorValueRow(
                        title: input.title,
                        detail: input.displayValue,
                        meta: input.key
                    )
                }
            }

            if !resolvedConfiguration.importedValueKinds.isEmpty {
                Text("Imported Value Kinds: \(resolvedConfiguration.importedValueKinds.map(\.rawValue).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !resolvedConfiguration.importedScheduleInputKeys.isEmpty {
                Text("Imported Schedule Keys: \(resolvedConfiguration.importedScheduleInputKeys.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !resolvedConfiguration.notes.isEmpty {
                Text("Config Notes: \(resolvedConfiguration.notes.joined(separator: " | "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var configuredValues: [PricingConfiguredNumericValue] {
        [
            resolvedConfiguration.draftUnitCost,
            resolvedConfiguration.draftUnitPrice,
            resolvedConfiguration.allowanceAmount,
            resolvedConfiguration.feeAmount,
            resolvedConfiguration.markupPercent
        ].compactMap { $0 }
    }

    private func configuredValueDetail(_ value: PricingConfiguredNumericValue) -> String {
        let formatted = proposalInspectorCurrencyFormatter.string(from: NSNumber(value: value.amount)) ?? "\(value.amount)"
        if value.kind == .markupPercent {
            return "\(proposalInspectorNumberFormatter.string(from: NSNumber(value: value.amount)) ?? "\(value.amount)")%"
        }

        if let unitLabel = value.unitLabel?.nilIfBlank,
           value.kind == .draftUnitCost || value.kind == .draftUnitPrice {
            return "\(formatted) / \(unitLabel)"
        }

        return formatted
    }

    private func aggregateDetail(placeholderKey: String, amount: Double?) -> String {
        if let amount {
            let formatted = proposalInspectorCurrencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "\(placeholderKey) = \(formatted)"
        }
        return placeholderKey
    }
}

private struct ProposalInspectorResolvedRuleView: View {
    let resolvedRule: ResolvedPricingRule

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProposalInspectorValueRow(
                title: "Requested Rule",
                detail: resolvedRule.requestedRuleKey ?? "None",
                meta: resolvedRule.status
            )

            if let definition = resolvedRule.definition {
                ProposalInspectorValueRow(
                    title: "Resolved Rule ID",
                    detail: definition.id,
                    meta: definition.kind.rawValue
                )

                Text(definition.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let formula = definition.formula {
                    ProposalInspectorValueRow(
                        title: "Formula",
                        detail: formula.title,
                        meta: "\(formula.key) • \(formula.strategy.rawValue)"
                    )

                    Text(formula.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !formula.rateSlots.isEmpty {
                        Text("Rate Slots: \(formula.rateSlots.map(\.slotKey).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !formula.inputReferences.isEmpty {
                        Text("Formula Inputs")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(formula.inputReferences) { input in
                            ProposalInspectorValueRow(
                                title: input.title,
                                detail: input.detail,
                                meta: input.key
                            )
                        }
                    }
                }

                ProposalInspectorValueRow(
                    title: "Subtotal Derivation",
                    detail: definition.subtotalDerivation.placeholderKey,
                    meta: definition.subtotalDerivation.kind.rawValue
                )

                Text(definition.subtotalDerivation.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProposalInspectorValueRow(
                    title: "Future Group Rollup",
                    detail: definition.futureGroupRollup.placeholderKey,
                    meta: definition.futureGroupRollup.status.rawValue
                )

                Text(definition.futureGroupRollup.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !definition.notes.isEmpty {
                    Text("Rule Notes: \(definition.notes.joined(separator: " | "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

private let proposalInspectorCurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
}()

private func configuredSlotDetail(
    placeholderKey: String,
    amount: Double?,
    unitLabel: String? = nil
) -> String {
    guard let amount else { return placeholderKey }
    let formatted = proposalInspectorCurrencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    if let unitLabel = unitLabel?.nilIfBlank {
        return "\(placeholderKey) = \(formatted) / \(unitLabel)"
    }
    return "\(placeholderKey) = \(formatted)"
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
#endif
