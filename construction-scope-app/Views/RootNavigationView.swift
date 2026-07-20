import SwiftUI
import SwiftData

#if DEBUG
private let rootNavigationJobTreadDebugWindowID = "jobtread-debug-window"
private let rootNavigationDebugSelectedScopeStorageKey = "debug.selected-scope-id"
#endif

enum ScopeSection: String, CaseIterable, Identifiable {
    case projectInfo = "Project Information"
    case existingConditions = "Existing Conditions"
    case structuralSystem = "Structural System"
    case enclosure = "Screen Enclosure"
    case windowsAndGlass = "Sunroom"
    case electrical = "Electrical"
    case drainage = "Drainage"
    case attachmentConditions = "Attachment Conditions"
    case documents = "Documents"
    case finishes = "Finishes"
    case permitsHOA = "Permits / HOA"
    case productionNotes = "Production Notes"
    case signatureAndExport = "Signature & Export"

    var id: String { rawValue }

    var reviewStateKey: String {
        switch self {
        case .projectInfo: return "project_info"
        case .existingConditions: return "existing_conditions"
        case .structuralSystem: return "structural_system"
        case .enclosure: return "screen_enclosure"
        case .windowsAndGlass: return "sunroom"
        case .electrical: return "electrical"
        case .drainage: return "drainage"
        case .attachmentConditions: return "attachment_conditions"
        case .documents: return "documents"
        case .finishes: return "finishes"
        case .permitsHOA: return "permits_hoa"
        case .productionNotes: return "production_notes"
        case .signatureAndExport: return "signature_and_export"
        }
    }

    static func section(reviewStateKey: String) -> ScopeSection? {
        allCases.first { section in
            section.reviewStateKey == reviewStateKey || section.rawValue == reviewStateKey
        }
    }

    var symbol: String {
        switch self {
        case .projectInfo: return "person.text.rectangle"
        case .existingConditions: return "house"
        case .structuralSystem: return "building.columns"
        case .enclosure: return "rectangle.3.group"
        case .windowsAndGlass: return "window.casement"
        case .electrical: return "bolt"
        case .drainage: return "drop"
        case .attachmentConditions: return "link"
        case .documents: return "paperclip"
        case .finishes: return "paintbrush"
        case .permitsHOA: return "doc.text"
        case .productionNotes: return "note.text"
        case .signatureAndExport: return "signature"
        }
    }
}

extension ScopeSection {
    private static let sharedSectionsAfterProjectType: [ScopeSection] = [
        .existingConditions,
        .documents,
        .permitsHOA,
        .productionNotes,
        .signatureAndExport
    ]

    private static let structuralWorkSections: [ScopeSection] = [
        .structuralSystem,
        .electrical,
        .drainage,
        .attachmentConditions,
        .finishes
    ]

    private static let projectTypeSectionMap: [ProjectType: [ScopeSection]] = [
        .patioCover: sharedSectionsAfterProjectType + structuralWorkSections,
        .screenRoom: sharedSectionsAfterProjectType + [
            .structuralSystem,
            .enclosure,
            .electrical,
            .drainage,
            .attachmentConditions,
            .finishes
        ],
        .sunroom: sharedSectionsAfterProjectType + [
            .structuralSystem,
            .windowsAndGlass,
            .electrical,
            .drainage,
            .attachmentConditions,
            .finishes
        ],
        .deck: sharedSectionsAfterProjectType + structuralWorkSections,
        .pergola: sharedSectionsAfterProjectType + structuralWorkSections,
        .concrete: sharedSectionsAfterProjectType + [
            .drainage,
            .finishes
        ],
        .other: sharedSectionsAfterProjectType + structuralWorkSections
    ]

    static func visibleSections(for projectTypes: [ProjectType]) -> [ScopeSection] {
        let activeTypes = ProjectType.selectableCases.filter { projectTypes.contains($0) }
        guard !activeTypes.isEmpty else { return [.projectInfo] }

        var visibleSections: Set<ScopeSection> = [.projectInfo]
        for type in activeTypes {
            visibleSections.formUnion(projectTypeSectionMap[type] ?? sharedSectionsAfterProjectType)
        }

        return allCases.filter { visibleSections.contains($0) }
    }

    static func visibleSections(for projectInfo: ProjectInfo) -> [ScopeSection] {
        visibleSections(for: projectInfo.activeProjectTypes)
    }

    static func visibleSections(for scope: JobScope) -> [ScopeSection] {
        visibleSections(for: scope.projectInfo)
    }

    static func visibleSectionSet(for scope: JobScope) -> Set<ScopeSection> {
        Set(visibleSections(for: scope))
    }

    func isVisible(in scope: JobScope) -> Bool {
        Self.visibleSectionSet(for: scope).contains(self)
    }
}

private enum ScopeSortOption: String, CaseIterable, Identifiable {
    case alphabetical
    case jobStatus
    case createdAt
    case recentActivity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .alphabetical: return "Alphabetical"
        case .jobStatus: return "Status"
        case .createdAt: return "Created Date"
        case .recentActivity: return "Recently Edited"
        }
    }

    var systemImage: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .jobStatus: return "checklist"
        case .createdAt: return "calendar"
        case .recentActivity: return "clock.arrow.circlepath"
        }
    }
}

private enum ScopeSortDirection {
    case ascending
    case descending

    var label: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}

private enum SidebarRenamePromptMode {
    case newScope
    case existingScope
}

private func statusRank(for status: JobStatus) -> Int {
    switch status {
    case .draft: return 0
    case .sold: return 1
    case .inProduction: return 2
    case .closed: return 3
    case .other: return 4
    }
}

private func activityDate(for scope: JobScope) -> Date {
    max(scope.updatedAt, scope.lastOpenedAt ?? .distantPast)
}

private func sortedScopes(
    _ scopes: [JobScope],
    option: ScopeSortOption,
    direction: ScopeSortDirection
) -> [JobScope] {
    let sorted = scopes.sorted { lhs, rhs in
        switch option {
        case .alphabetical:
            let comparison = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
            if comparison == .orderedSame {
                return lhs.createdAt < rhs.createdAt
            }
            return comparison == .orderedAscending
        case .jobStatus:
            let lhsRank = statusRank(for: lhs.status)
            let rhsRank = statusRank(for: rhs.status)
            if lhsRank == rhsRank {
                let comparison = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
                if comparison == .orderedSame {
                    return lhs.createdAt < rhs.createdAt
                }
                return comparison == .orderedAscending
            }
            return lhsRank < rhsRank
        case .createdAt:
            if lhs.createdAt == rhs.createdAt {
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
            return lhs.createdAt < rhs.createdAt
        case .recentActivity:
            let lhsActivity = activityDate(for: lhs)
            let rhsActivity = activityDate(for: rhs)
            if lhsActivity == rhsActivity {
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
            return lhsActivity < rhsActivity
        }
    }

    return direction == .ascending ? sorted : sorted.reversed()
}

private let rootNavigationCoordinateSpace = "RootNavigationCoordinateSpace"
struct RootNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
#if DEBUG
    @Environment(\.openWindow) private var openWindow
    @AppStorage(rootNavigationDebugSelectedScopeStorageKey) private var debugSelectedScopeIDStorage = ""
#endif
    @Query private var scopes: [JobScope]

    @State private var selectedScopeID: UUID?
    @State private var selectedSection: ScopeSection = .projectInfo
    @State private var selectedSortOption: ScopeSortOption? = .recentActivity
    @State private var sortDirection: ScopeSortDirection? = .descending
    @State private var sidebarRenameScope: JobScope?
    @State private var sidebarRenameDraft = ""
    @State private var sidebarRenameMode: SidebarRenamePromptMode = .existingScope
    @State private var sidebarRenameDepositing = false
    @State private var sidebarFolderPulseToken = 0
    @State private var sidebarRenameOrigin = CGPoint(x: 28, y: 28)
    @State private var showingScopeCreationSheet = false
    @StateObject private var autosave = DebouncedAutosave()
    @StateObject private var sectionReviewStore = SectionReviewStore()

    private let customerDetailFetcher: JobTreadCustomerDetailFetching = JobTreadClient()

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
    }

    private var activitySortedScopes: [JobScope] {
        sortedScopes(scopes, option: .recentActivity, direction: .descending)
    }

    private var visibleScopes: [JobScope] {
        guard let selectedSortOption else { return scopes }
        return sortedScopes(scopes, option: selectedSortOption, direction: sortDirection ?? .descending)
    }

    private var useCompactNavigation: Bool {
        horizontalSizeClass == .compact
    }

    private var selectedScopeProjectTypes: [ProjectType] {
        selectedScope?.projectInfo.activeProjectTypes ?? []
    }

    private var effectiveSelectedSection: ScopeSection {
        guard let selectedScope else { return .projectInfo }
        return selectedSection.isVisible(in: selectedScope) ? selectedSection : .projectInfo
    }

    private var detailTransitionKey: String {
        "\(selectedScopeID?.uuidString ?? "none")-\(effectiveSelectedSection.rawValue)"
    }

    var body: some View {
        ZStack {
            Group {
                if useCompactNavigation {
                    PhoneScopesListView(
                        scopes: visibleScopes,
                        selectedSortOption: $selectedSortOption,
                        sortDirection: $sortDirection,
                        createNewScope: createNewScope,
                        createScopeFromCustomer: createScopeFromCustomer,
                        onOpenScope: recordScopeOpened,
                        autosave: autosave,
                        sectionReviewStore: sectionReviewStore,
                        renameScope: renameScope,
                        deleteScope: deleteScope
                    )
                } else {
                    NavigationSplitView {
                        ScopeSidebarView(
                            scopes: visibleScopes,
                            selectedSortOption: $selectedSortOption,
                            sortDirection: $sortDirection,
                            selectedScopeID: $selectedScopeID,
                            selectedSection: $selectedSection,
                            createNewScope: handleSidebarCreateScope,
                            onSelectScope: handleScopeSelection,
                            requestRename: { beginSidebarRename(for: $0, mode: .existingScope) },
                            deleteScope: deleteScope,
                            sectionReviewStore: sectionReviewStore,
                            folderPulseToken: sidebarFolderPulseToken,
                            newScopeTapPoint: $sidebarRenameOrigin
                        )
                    } detail: {
                        ZStack {
                            if let scope = selectedScope {
                                let effectiveSection = effectiveSelectedSection
                                SectionEditorView(
                                    scope: scope,
                                    section: effectiveSection,
                                    autosave: autosave,
                                    sectionReviewStore: sectionReviewStore,
                                    sketchAction: {
                                        guard ScopeSection.signatureAndExport.isVisible(in: scope) else { return }
                                        withAnimation(.snappy(duration: 0.26, extraBounce: 0)) {
                                            selectedSection = .signatureAndExport
                                        }
                                    }
                                )
                                    .id(detailTransitionKey)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                ContentUnavailableView(
                                    "No Scope Selected",
                                    systemImage: "doc.badge.plus",
                                    description: Text("Create a new scope to begin.")
                                )
                                .id("no-scope-selected")
                                .transition(.opacity)
                            }
                        }
                        .animation(.snappy(duration: 0.28, extraBounce: 0), value: detailTransitionKey)
                    }
                    .navigationSplitViewStyle(.balanced)
                }
            }
            // Experimental: keep the entire shell floating above a luminous glass backdrop.
            .background(LiquidGlassBackdrop())

            if !useCompactNavigation, let sidebarRenameScope {
                SidebarRenameOverlay(
                    text: $sidebarRenameDraft,
                    isDepositing: sidebarRenameDepositing,
                    saveDisabled: sidebarRenameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    origin: sidebarRenameOrigin,
                    onCancel: cancelSidebarRename,
                    onSave: { saveSidebarRename(sidebarRenameScope) }
                )
                .zIndex(10)
            }

#if DEBUG
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        openWindow(id: rootNavigationJobTreadDebugWindowID)
                    } label: {
                        Label("Internal Debug", systemImage: "ladybug.fill")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                    .accessibilityHint("Opens the internal JobTread and proposal foundation debug window.")
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .zIndex(20)
#endif
        }
        .coordinateSpace(name: rootNavigationCoordinateSpace)
        .onAppear {
            autosave.configure(with: modelContext)
            selectFirstScopeIfNeeded()
#if DEBUG
            syncDebugSelectedScopeID()
#endif
        }
        .onChange(of: scopes.map(\.id)) { _, _ in
            selectFirstScopeIfNeeded()
        }
        .onChange(of: selectedScopeID) { _, _ in
            ensureSelectedSectionIsVisible()
#if DEBUG
            syncDebugSelectedScopeID()
#endif
        }
        .onChange(of: selectedScopeProjectTypes) { _, _ in
            ensureSelectedSectionIsVisible()
        }
        .sheet(isPresented: $showingScopeCreationSheet) {
            ScopeCreationSheet(
                onCreateBlankScope: {
                    let newScope = createNewScope()
                    if !useCompactNavigation {
                        beginSidebarRename(for: newScope, mode: .newScope)
                    }
                },
                onCreateScopeFromCustomer: { customer in
                    _ = createScopeFromCustomer(customer)
                }
            )
        }
    }

    private func handleSidebarCreateScope() {
        showingScopeCreationSheet = true
    }

#if DEBUG
    private func syncDebugSelectedScopeID() {
        debugSelectedScopeIDStorage = selectedScopeID?.uuidString ?? ""
    }
#endif

    private func beginSidebarRename(for scope: JobScope, mode: SidebarRenamePromptMode) {
        sidebarRenameScope = scope
        sidebarRenameDraft = mode == .newScope ? "" : scope.displayName
        sidebarRenameMode = mode
        sidebarRenameDepositing = false
    }

    private func cancelSidebarRename() {
        if sidebarRenameMode == .newScope, let sidebarRenameScope {
            deleteScope(sidebarRenameScope)
        }

        dismissSidebarRename()
    }

    private func dismissSidebarRename() {
        sidebarRenameScope = nil
        sidebarRenameDraft = ""
        sidebarRenameDepositing = false
        sidebarRenameMode = .existingScope
    }

    private func saveSidebarRename(_ scope: JobScope) {
        let trimmedName = sidebarRenameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        renameScope(scope, newName: trimmedName)

        guard sidebarRenameMode == .newScope else {
            dismissSidebarRename()
            return
        }

        sidebarRenameDepositing = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if !scopes.isEmpty {
                sidebarFolderPulseToken += 1
            }

            try? await Task.sleep(for: .milliseconds(140))
            dismissSidebarRename()
        }
    }

    @discardableResult
    private func createNewScope() -> JobScope {
        persistNewScope(ScopeTemplate.makeNewScope())
    }

    @discardableResult
    private func createScopeFromCustomer(_ customer: JobTreadCustomerLookupResult) -> JobScope {
        let newScope = persistNewScope(ScopeTemplate.makeScope(linkedCustomer: customer))
        hydrateScopeFromSelectedCustomer(scopeID: newScope.id, customerID: customer.customerID)
        return newScope
    }

    @discardableResult
    private func persistNewScope(_ newScope: JobScope) -> JobScope {
        modelContext.insert(newScope)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save new scope")
        }

        selectedScopeID = newScope.id
        selectedSection = .projectInfo
        recordScopeOpened(newScope)
        return newScope
    }

    private func renameScope(_ scope: JobScope, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        scope.setLocalScopeTitle(trimmed)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to rename scope")
        }
    }

    private func deleteScope(_ scope: JobScope) {
        withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
            if selectedScopeID == scope.id {
                selectedScopeID = nil
            }

            modelContext.delete(scope)
            do {
                try modelContext.save()
            } catch {
                assertionFailure("Failed to delete scope")
            }

            selectFirstScopeIfNeeded()
        }
    }

    private func selectFirstScopeIfNeeded() {
        guard !scopes.isEmpty else {
            selectedScopeID = nil
            return
        }

        if let selectedScopeID, scopes.contains(where: { $0.id == selectedScopeID }) {
            return
        }

        guard let firstScope = visibleScopes.first else { return }
        selectedScopeID = firstScope.id
        selectedSection = .projectInfo
        recordScopeOpened(firstScope)
    }

    private func handleScopeSelection(_ scope: JobScope) {
        selectedScopeID = scope.id
        ensureSelectedSectionIsVisible(for: scope)
        recordScopeOpened(scope)
    }

    private func ensureSelectedSectionIsVisible(for scope: JobScope? = nil) {
        guard let scope = scope ?? selectedScope else {
            selectedSection = .projectInfo
            return
        }

        guard !selectedSection.isVisible(in: scope) else { return }
        selectedSection = .projectInfo
    }

    private func recordScopeOpened(_ scope: JobScope) {
        scope.lastOpenedAt = .now

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to record scope access")
        }
    }

    private func hydrateScopeFromSelectedCustomer(scopeID: UUID, customerID: String) {
        Task {
            do {
                guard let detail = try await customerDetailFetcher.fetchCustomerDetails(customerID: customerID) else {
                    return
                }

                await MainActor.run {
                    guard let scope = scopes.first(where: { $0.id == scopeID }) else {
                        return
                    }

                    scope.applyLinkedCustomerHydration(detail)

                    do {
                        try modelContext.save()
                    } catch {
                        assertionFailure("Failed to save hydrated customer details")
                    }
                }
            } catch {
                assertionFailure("JobTread customer detail hydration failed")
            }
        }
    }
}

private struct ScopeSidebarView: View {
    let scopes: [JobScope]
    @Binding var selectedSortOption: ScopeSortOption?
    @Binding var sortDirection: ScopeSortDirection?
    @Binding var selectedScopeID: UUID?
    @Binding var selectedSection: ScopeSection
    let createNewScope: () -> Void
    let onSelectScope: (JobScope) -> Void
    let requestRename: (JobScope) -> Void
    let deleteScope: (JobScope) -> Void
    @ObservedObject var sectionReviewStore: SectionReviewStore
    let folderPulseToken: Int
    @Binding var newScopeTapPoint: CGPoint

    @State private var scopesExpanded = false
    @State private var scopePendingDelete: JobScope?
    @State private var newScopeRowFrame: CGRect = .zero
    @Namespace private var scopesHeaderChevronNamespace

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
    }

    private var visibleSections: [ScopeSection] {
        guard let selectedScope else { return [] }
        return ScopeSection.visibleSections(for: selectedScope)
    }

    var body: some View {
        List {
            Section {
                Label("New Scope", systemImage: "plus.circle.fill")
                    .font(.body)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                newScopeTapPoint = CGPoint(
                                    x: newScopeRowFrame.minX + value.location.x,
                                    y: newScopeRowFrame.minY + value.location.y
                                )
                                scopesExpanded = false
                                createNewScope()
                            }
                    )
                    .accessibilityLabel("New Scope")
                    .accessibilityHint("Creates a new scope from the template.")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        newScopeTapPoint = CGPoint(
                            x: newScopeRowFrame.minX + 28,
                            y: newScopeRowFrame.midY
                        )
                        scopesExpanded = false
                        createNewScope()
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    newScopeRowFrame = proxy.frame(in: .named(rootNavigationCoordinateSpace))
                                }
                                .onChange(of: proxy.frame(in: .named(rootNavigationCoordinateSpace))) { _, frame in
                                    newScopeRowFrame = frame
                                }
                        }
                    )

                if !scopes.isEmpty {
                    ScopeSidebarHeaderRow(
                        isExpanded: $scopesExpanded,
                        selectedSortOption: $selectedSortOption,
                        sortDirection: $sortDirection,
                        folderPulseToken: folderPulseToken,
                        chevronNamespace: scopesHeaderChevronNamespace
                    )

                    if scopesExpanded {
                        scopesListContent
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                )
                            )
                    }
                }
            }

            if let selectedScope {
                Section {
                    GlassChromePanel(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Scope")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Text(selectedScope.displayName)
                                .font(.headline)

                            if selectedScope.showsSeparateCustomerIdentity,
                               let customerName = selectedScope.resolvedCustomerDisplayName {
                                Text("Customer: \(customerName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(scopeAddressSummary(for: selectedScope))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let metadata = scopeMetadataSummary(for: selectedScope) {
                                Text(metadata)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
                    .accessibilityElement(children: .combine)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                }

                Section("Sections") {
                    ForEach(visibleSections) { section in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedSection = section
                            }
                        } label: {
                            sidebarSectionLabel(for: section)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .accessibilityLabel(section.rawValue)
                        .accessibilityValue(sidebarSectionAccessibilityValue(for: section))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: scopes.map(\.id))
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: visibleSections.map(\.id))
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: scopesExpanded)
        .navigationTitle("Scopes")
        .alert("Delete Scope?", isPresented: deleteAlertPresented) {
            Button("Cancel", role: .cancel) {
                scopePendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                guard let scope = scopePendingDelete else { return }
                deleteScope(scope)
                scopePendingDelete = nil
            }
        } message: {
            Text("This permanently removes the scope and its entered details.")
        }
    }

    @ViewBuilder
    private var scopesListContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(scopes) { scope in
                scopeRow(for: scope)
            }
        }
    }

    @ViewBuilder
    private func sidebarSectionLabel(for section: ScopeSection) -> some View {
        let isSelected = selectedSection == section
        let isComplete = isSectionComplete(section)

        // Keep selection pooled into the sidebar row itself so it reads like
        // integrated system chrome rather than a floating sticker.
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.8) : .clear)
                .frame(width: 3, height: 26)

            Label(section.rawValue, systemImage: section.symbol)
                .font(.body.weight(isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))

            Spacer(minLength: 0)

            SectionReviewNavigationIndicator(isComplete: isComplete)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
                    .opacity(0.5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor.opacity(0.05))
                    }
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            .blur(radius: 3)
                            .mask {
                                Rectangle()
                                    .frame(height: 10)
                            }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: selectedSection)
    }

    private func isSectionComplete(_ section: ScopeSection) -> Bool {
        guard let selectedScope else { return false }
        return sectionReviewStore.isComplete(section, in: selectedScope)
    }

    private func sidebarSectionAccessibilityValue(for section: ScopeSection) -> String {
        [
            selectedSection == section ? "Selected" : nil,
            isSectionComplete(section) ? "Completed" : "Needs Review"
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    private var deleteAlertPresented: Binding<Bool> {
        Binding(
            get: { scopePendingDelete != nil },
            set: { isPresented in
                if !isPresented {
                    scopePendingDelete = nil
                }
            }
        )
    }

    private func scopeAddressSummary(for scope: JobScope) -> String {
        scope.projectInfo.formattedAddressLine ?? "No address"
    }

    private func scopeMetadataSummary(for scope: JobScope) -> String? {
        scope.projectInfo.activeProjectTypes.isEmpty ? "No Project Type" : scope.projectInfo.projectTypeDisplaySummary
    }

    @ViewBuilder
    private func scopeRow(for scope: JobScope) -> some View {
        let isSelected = selectedScopeID == scope.id

        Button {
            withAnimation(.snappy(duration: 0.26, extraBounce: 0)) {
                onSelectScope(scope)
            }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.78) : .clear)
                    .frame(width: 3, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.displayName)
                        .font(.body.weight(isSelected ? .medium : .regular))
                        .foregroundStyle(.primary)

                    Text(scopeAddressSummary(for: scope))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let metadata = scopeMetadataSummary(for: scope) {
                        Text(metadata)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.thinMaterial)
                        .opacity(0.52)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor.opacity(0.05))
                        }
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                .blur(radius: 3)
                                .mask {
                                    Rectangle()
                                        .frame(height: 10)
                                }
                        }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scope.displayName)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint("Opens this scope.")
        .contextMenu {
            Button("Rename Scope") {
                requestRename(scope)
            }

            Button("Delete Scope", role: .destructive) {
                scopePendingDelete = scope
            }
        }
        .id(scope.id)
    }
}

private struct ScopeSidebarHeaderRow: View {
    private let controlsRevealDelay: TimeInterval = 0.125

    @Binding var isExpanded: Bool
    @Binding var selectedSortOption: ScopeSortOption?
    @Binding var sortDirection: ScopeSortDirection?
    let folderPulseToken: Int
    let chevronNamespace: Namespace.ID
    @State private var controlsVisible = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingScopesCluster

            if isExpanded {
                if controlsVisible {
                    ScopeListControlGroup(
                        selectedSortOption: $selectedSortOption,
                        sortDirection: $sortDirection
                    )
                    .padding(.leading, 12)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        )
                    )
                    .animation(.snappy(duration: 0.22, extraBounce: 0), value: controlsVisible)
                }

                Spacer(minLength: 0)

                disclosureButton
            } else {
                disclosureButton
                    .padding(.leading, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .onAppear {
            controlsVisible = isExpanded
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + controlsRevealDelay) {
                    guard isExpanded else { return }
                    controlsVisible = true
                }
            } else {
                controlsVisible = false
            }
        }
    }

    private var disclosureButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.24, extraBounce: 0)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .frame(width: 28, height: 44)
                .contentShape(Rectangle())
                .matchedGeometryEffect(id: "scopes-disclosure", in: chevronNamespace)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Collapse scopes" : "Expand scopes")
        .accessibilityHint("Shows or hides the scopes list.")
    }

    private var leadingScopesCluster: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.headline)
                .offset(y: -0.5)

            Text("Scopes")
                .font(.headline)
        }
        .symbolEffect(.bounce.byLayer, value: folderPulseToken)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(2)
    }
}

private struct PhoneScopesListView: View {
    let scopes: [JobScope]
    @Binding var selectedSortOption: ScopeSortOption?
    @Binding var sortDirection: ScopeSortDirection?
    let createNewScope: () -> JobScope
    let createScopeFromCustomer: (JobTreadCustomerLookupResult) -> JobScope
    let onOpenScope: (JobScope) -> Void
    @ObservedObject var autosave: DebouncedAutosave
    @ObservedObject var sectionReviewStore: SectionReviewStore
    let renameScope: (JobScope, String) -> Void
    let deleteScope: (JobScope) -> Void

    @State private var scopePendingRename: JobScope?
    @State private var renamePromptMode: SidebarRenamePromptMode = .existingScope
    @State private var renameDraft = ""
    @State private var scopePendingDelete: JobScope?
    @State private var showingScopeCreationSheet = false

    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    Section {
                        ForEach(scopes) { scope in
                            phoneScopeRow(for: scope)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(LiquidGlassBackdrop())
                .navigationTitle("Scopes")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ScopeListControlGroup(
                            selectedSortOption: $selectedSortOption,
                            sortDirection: $sortDirection
                        )
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: handleCreateScope) {
                            Label("New Scope", systemImage: "plus")
                        }
                    }
                }
            }

            if scopePendingRename != nil {
                ScopeRenameOverlay(
                    title: "Rename Scope",
                    message: "Update the local scope title shown in your scope list.",
                    text: $renameDraft,
                    isSaving: false,
                    saveDisabled: renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    onCancel: cancelRenamePrompt,
                    onSave: saveRenamePrompt
                )
            }
        }
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: scopes.map(\.id))
        .alert("Delete Scope?", isPresented: deleteAlertPresented) {
            Button("Cancel", role: .cancel) {
                scopePendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                guard let scope = scopePendingDelete else { return }
                deleteScope(scope)
                scopePendingDelete = nil
            }
        } message: {
            Text("This permanently removes the scope and its entered details.")
        }
        .sheet(isPresented: $showingScopeCreationSheet) {
            ScopeCreationSheet(
                onCreateBlankScope: {
                    let newScope = createNewScope()
                    scopePendingRename = newScope
                    renameDraft = ""
                    renamePromptMode = .newScope
                },
                onCreateScopeFromCustomer: { customer in
                    _ = createScopeFromCustomer(customer)
                }
            )
        }
    }

    private var deleteAlertPresented: Binding<Bool> {
        Binding(
            get: { scopePendingDelete != nil },
            set: { isPresented in
                if !isPresented {
                    scopePendingDelete = nil
                }
            }
        )
    }

    private func handleCreateScope() {
        showingScopeCreationSheet = true
    }

    private func cancelRenamePrompt() {
        if renamePromptMode == .newScope, let scopePendingRename {
            deleteScope(scopePendingRename)
        }

        scopePendingRename = nil
        renameDraft = ""
        renamePromptMode = .existingScope
    }

    private func saveRenamePrompt() {
        guard let scope = scopePendingRename else { return }
        let trimmedName = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        renameScope(scope, trimmedName)
        scopePendingRename = nil
        renameDraft = ""
        renamePromptMode = .existingScope
    }

    @ViewBuilder
    private func phoneScopeRow(for scope: JobScope) -> some View {
        NavigationLink {
            PhoneSectionListView(scope: scope, autosave: autosave, sectionReviewStore: sectionReviewStore)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.displayName)
                        .font(.body)
                    Text(scope.projectInfo.formattedAddressLine ?? "No address")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                StatusPill(status: scope.status)
            }
            .frame(minHeight: 44)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                onOpenScope(scope)
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                scopePendingDelete = scope
            }

            Button("Rename") {
                scopePendingRename = scope
                renameDraft = scope.displayName
                renamePromptMode = .existingScope
            }
            .tint(.blue)
        }
    }
}

private struct ScopeListControlGroup: View {
    @Binding var selectedSortOption: ScopeSortOption?
    @Binding var sortDirection: ScopeSortDirection?

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(ScopeSortOption.allCases) { option in
                    Button {
                        if selectedSortOption == option {
                            selectedSortOption = nil
                            sortDirection = nil
                        } else {
                            selectedSortOption = option
                        }
                    } label: {
                        ScopeMenuSelectionLabel(
                            title: option.label,
                            systemImage: option.systemImage,
                            isSelected: selectedSortOption == option
                        )
                    }
                }

                Divider()

                Button {
                    guard selectedSortOption != nil else { return }
                    sortDirection = sortDirection == .ascending ? nil : .ascending
                } label: {
                    ScopeMenuSelectionLabel(
                        title: "Ascending",
                        systemImage: "arrow.up",
                        isSelected: sortDirection == .ascending
                    )
                }
                .disabled(selectedSortOption == nil)

                Button {
                    guard selectedSortOption != nil else { return }
                    sortDirection = sortDirection == .descending ? nil : .descending
                } label: {
                    ScopeMenuSelectionLabel(
                        title: "Descending",
                        systemImage: "arrow.down",
                        isSelected: sortDirection == .descending
                    )
                }
                .disabled(selectedSortOption == nil)
            } label: {
                ScopeListToolbarLabel(
                    title: "Sort",
                    systemImage: "arrow.up.arrow.down",
                    tint: selectedSortOption == nil ? .secondary : .accentColor,
                    contentOffsetX: -6
                )
            }
            .accessibilityLabel(selectedSortLabel)
            .accessibilityHint("Choose how scopes are organized in the list and whether the order is ascending or descending.")
        }
        .padding(.trailing, 8)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var selectedSortLabel: String {
        if let selectedSortOption {
            let directionLabel = sortDirection?.label ?? "no order"
            return "Sort options, current \(selectedSortOption.label), \(directionLabel)"
        }

        return "Sort options, no active sort"
    }
}

private struct ScopeListToolbarLabel: View {
    let title: String
    let systemImage: String
    let tint: Color
    var contentOffsetX: CGFloat = 0

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .offset(x: contentOffsetX)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(minWidth: 44, minHeight: 36, alignment: .center)
    }
}

private struct ScopeMenuSelectionLabel: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        Label(displayTitle, systemImage: systemImage)
    }

    private var displayTitle: String {
        isSelected ? "\(title)  ✓" : title
    }
}

private struct SidebarRenameOverlay: View {
    @Binding var text: String
    let isDepositing: Bool
    let saveDisabled: Bool
    let origin: CGPoint
    let onCancel: () -> Void
    let onSave: () -> Void

    @FocusState private var nameFieldFocused: Bool
    @State private var hasExpandedFromButton = false
    @State private var cardSize: CGSize = CGSize(width: 380, height: 280)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(0.06))
                    .ignoresSafeArea()
                    .transition(.opacity)

                renameCard
                    .frame(width: 380)
                    .scaleEffect(cardScale, anchor: .center)
                    .offset(cardDepositOffset)
                    .opacity(cardOpacity)
                    .position(cardCenter(in: proxy.size))
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: hasExpandedFromButton)
                    .animation(.easeIn(duration: 0.2), value: isDepositing)
            }
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
        .onAppear {
            hasExpandedFromButton = false
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                hasExpandedFromButton = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(40))
                nameFieldFocused = true
            }
        }
        .transition(.opacity)
    }

    private var renameCard: some View {
        GlassChromePanel(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Scope")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("This scope will be saved in Scopes.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Scope Name")
                        .font(.body)
                    TextField("Name", text: $text)
                        .liquidGlassInput()
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if !saveDisabled {
                                handleSave()
                            }
                        }
                }

                HStack(spacing: 12) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .frame(maxWidth: .infinity, minHeight: 44)

                    Button("Create", action: handleSave)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(saveDisabled)
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        cardSize = proxy.size
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        cardSize = newSize
                    }
            }
        )
    }

    private func cardCenter(in containerSize: CGSize) -> CGPoint {
        let expandedCenter = CGPoint(
            x: min(max(220, 224), containerSize.width - 210),
            y: min(max(240, 272), containerSize.height - 180)
        )

        if hasExpandedFromButton {
            return expandedCenter
        }

        return origin
    }

    private var cardScale: CGFloat {
        if isDepositing { return 0.02 }
        return hasExpandedFromButton ? 1 : 0.06
    }

    private var cardOpacity: Double {
        if isDepositing { return 0 }
        return hasExpandedFromButton ? 1 : 0.2
    }

    private var cardDepositOffset: CGSize {
        guard isDepositing else { return .zero }

        let scale = cardScale
        let targetPoint = CGPoint(x: 42, y: 52)
        let center = CGPoint(x: cardSize.width / 2, y: cardSize.height / 2)
        let vectorToTarget = CGSize(
            width: targetPoint.x - center.x,
            height: targetPoint.y - center.y
        )

        return CGSize(
            width: vectorToTarget.width * (1 - scale),
            height: vectorToTarget.height * (1 - scale)
        )
    }

    private func handleSave() {
        nameFieldFocused = false
        onSave()
    }
}

private struct ScopeRenameOverlay: View {
    let title: String
    let message: String
    @Binding var text: String
    let isSaving: Bool
    let saveDisabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.08))
                .ignoresSafeArea()
                .transition(.opacity)

            GlassChromePanel(cornerRadius: 28) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Scope Name")
                            .font(.body)
                        TextField("Scope Name", text: $text)
                            .liquidGlassInput()
                            .focused($nameFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                if !saveDisabled {
                                    onSave()
                                }
                            }
                    }

                    HStack(spacing: 12) {
                        Button("Cancel", action: onCancel)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .frame(maxWidth: .infinity, minHeight: 44)

                        Button("Save", action: onSave)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .disabled(saveDisabled)
                    }
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .scaleEffect(isSaving ? 0.24 : 1)
            .offset(x: isSaving ? -170 : 0, y: isSaving ? -210 : 0)
            .opacity(isSaving ? 0.04 : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.72), value: isSaving)
        }
        .onAppear {
            nameFieldFocused = true
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

private struct PhoneSectionListView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave
    @ObservedObject var sectionReviewStore: SectionReviewStore

    private var visibleSections: [ScopeSection] {
        ScopeSection.visibleSections(for: scope)
    }

    var body: some View {
        List {
            Section {
                ForEach(visibleSections) { section in
                    NavigationLink {
                        SectionEditorView(
                            scope: scope,
                            section: section,
                            autosave: autosave,
                            sectionReviewStore: sectionReviewStore,
                            sketchAction: nil
                        )
                    } label: {
                        HStack(spacing: 10) {
                            Label(section.rawValue, systemImage: section.symbol)
                                .font(.body)

                            Spacer(minLength: 8)

                            SectionReviewNavigationIndicator(
                                isComplete: sectionReviewStore.isComplete(section, in: scope)
                            )
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityValue(sectionReviewStore.isComplete(section, in: scope) ? "Completed" : "Needs Review")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(LiquidGlassBackdrop())
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: visibleSections.map(\.id))
        .navigationTitle(scope.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SectionReviewNavigationIndicator: View {
    let isComplete: Bool

    var body: some View {
        Group {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Completed")
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("Needs Review")
            }
        }
        .font(.subheadline.weight(.semibold))
        .symbolRenderingMode(.hierarchical)
    }
}

private struct SectionReviewControl: View {
    let isComplete: Bool
    let completedAt: Date?
    let markComplete: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                statusCluster

                Spacer(minLength: 12)

                actionButton
            }

            VStack(alignment: .leading, spacing: 10) {
                statusCluster
                actionButton
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isComplete ? "Section completed" : "Section needs review")
    }

    private var statusCluster: some View {
        HStack(alignment: .center, spacing: 8) {
            Label(statusTitle, systemImage: statusSymbol)
                .font(.subheadline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isComplete ? Color.green : Color.secondary)
                .contentTransition(.opacity)

            if isComplete, let completedAt {
                Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
        }
    }

    private var statusTitle: String {
        isComplete ? "Completed" : "Needs Review"
    }

    private var statusSymbol: String {
        isComplete ? "checkmark.circle.fill" : "circle"
    }

    @ViewBuilder
    private var actionButton: some View {
        if isComplete {
            Button {
                markComplete()
            } label: {
                Label("Reconfirm", systemImage: "checkmark.circle")
                    .frame(minHeight: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(.green)
            .accessibilityHint("Marks this section complete again.")
        } else {
            Button {
                markComplete()
            } label: {
                Label("Mark Complete", systemImage: "checkmark.circle")
                    .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .accessibilityHint("Marks this section complete for now.")
        }
    }
}

private struct ScopeSectionContentFingerprint: Equatable {
    let payload: Data

    init(scope: JobScope, section: ScopeSection) {
        payload = Self.payload(for: scope, section: section)
    }

    private static func payload(for scope: JobScope, section: ScopeSection) -> Data {
        switch section {
        case .projectInfo:
            return encode(
                ProjectInfoSectionContent(
                    scopeTitle: scope.scopeTitle,
                    jobTreadCustomer: scope.jobTreadCustomer,
                    projectInfo: scope.projectInfo
                )
            )
        case .existingConditions:
            return encode(
                ExistingConditionsSectionContent(
                    existingConditions: scope.existingConditions,
                    checklistPhotos: checklistPhotoFingerprints(scopeID: scope.id)
                )
            )
        case .structuralSystem:
            return encode(scope.structuralSystem)
        case .enclosure:
            return encode(ScreenEnclosureSectionContent(enclosure: scope.enclosure))
        case .windowsAndGlass:
            return encode(SunroomSectionContent(enclosure: scope.enclosure))
        case .electrical:
            return encode(scope.electrical)
        case .drainage:
            return encode(scope.drainage)
        case .attachmentConditions:
            return encode(scope.attachment)
        case .documents:
            return encode(scope.documents)
        case .finishes:
            return encode(scope.finishes)
        case .permitsHOA:
            return encode(scope.permitsHOA)
        case .productionNotes:
            return encode(
                ProductionNotesSectionContent(
                    status: scope.status,
                    jobNumber: scope.jobNumber,
                    production: scope.production,
                    optionsConfirmedText: scope.customerApproval?.optionsConfirmedText
                )
            )
        case .signatureAndExport:
            return encode(
                SignatureSectionContent(
                    signedDate: scope.customerApproval?.signedDate,
                    customerSignature: fileFingerprint(path: scope.customerApproval?.signaturePNGPath),
                    sketches: sketchFingerprints(scope.sketches)
                )
            )
        }
    }

    private static func encode<Value: Encodable>(_ value: Value) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        do {
            return try encoder.encode(value)
        } catch {
            assertionFailure("Failed to encode section content fingerprint")
            return Data(String(describing: Value.self).utf8)
        }
    }

    private static func checklistPhotoFingerprints(scopeID: UUID) -> [CategorizedSectionFileFingerprints] {
        PhotoChecklistCategory.allCases.map { category in
            CategorizedSectionFileFingerprints(
                categoryKey: category.rawValue,
                files: ChecklistPhotoAssetStore.photos(scopeID: scopeID, category: category)
                    .map { SectionFileFingerprint(path: $0.filePath) }
            )
        }
    }

    private static func sketchFingerprints(_ sketches: [SketchAttachment]?) -> [SketchSectionFingerprint]? {
        sketches?.map { sketch in
            SketchSectionFingerprint(
                id: sketch.id,
                title: sketch.title,
                drawing: SectionFileFingerprint(path: sketch.drawingDataPath),
                preview: SectionFileFingerprint(path: sketch.previewPNGPath),
                createdAt: sketch.createdAt
            )
        }
    }

    private static func fileFingerprint(path: String?) -> SectionFileFingerprint? {
        guard let path else { return nil }
        return SectionFileFingerprint(path: path)
    }
}

private struct ProjectInfoSectionContent: Codable {
    var scopeTitle: String?
    var jobTreadCustomer: JobTreadCustomerRef?
    var projectInfo: ProjectInfo
}

private struct ExistingConditionsSectionContent: Codable {
    var existingConditions: ExistingConditions?
    var checklistPhotos: [CategorizedSectionFileFingerprints]
}

private struct ScreenEnclosureSectionContent: Codable {
    var enclosureTypes: [EnclosureType]?
    var screenWallType: ScreenWallType?
    var screenTint: ScreenTintOption?
    var screenFrameSize: ScreenFrameSizeOption?
    var screenFrameColor: EnclosureScreenFrameColorOption?
    var screenFrameColorCustom: String?
    var screenEnclosureNotes: String?
    var screenMeasurements: MeasurementsBlock?
    var kneeWall: KneeWall?
    var doors: DoorOptions?

    init(enclosure: Enclosure?) {
        self.enclosureTypes = enclosure?.enclosureTypes
        self.screenWallType = enclosure?.screenWallType
        self.screenTint = enclosure?.screenTint
        self.screenFrameSize = enclosure?.screenFrameSize
        self.screenFrameColor = enclosure?.screenFrameColor
        self.screenFrameColorCustom = enclosure?.screenFrameColorCustom
        self.screenEnclosureNotes = enclosure?.screenEnclosureNotes
        self.screenMeasurements = enclosure?.screenMeasurements
        self.kneeWall = enclosure?.kneeWall
        self.doors = enclosure?.doors
    }
}

private struct SunroomSectionContent: Codable {
    var windowSystem: WindowSystem?
    var sunroomMeasurements: MeasurementsBlock?

    init(enclosure: Enclosure?) {
        self.windowSystem = enclosure?.windowSystem
        self.sunroomMeasurements = enclosure?.sunroomMeasurements
    }
}

private struct CategorizedSectionFileFingerprints: Codable {
    var categoryKey: String
    var files: [SectionFileFingerprint]
}

private struct SectionFileFingerprint: Codable {
    var path: String
    var modifiedAt: Date?
    var fileSize: UInt64?

    init(path: String) {
        self.path = path

        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        self.modifiedAt = attributes?[.modificationDate] as? Date
        self.fileSize = (attributes?[.size] as? NSNumber)?.uint64Value
    }
}

private struct ProductionNotesSectionContent: Codable {
    var status: JobStatus
    var jobNumber: String?
    var production: ProductionOrderMeta?
    var optionsConfirmedText: String?
}

private struct SignatureSectionContent: Codable {
    var signedDate: Date?
    var customerSignature: SectionFileFingerprint?
    var sketches: [SketchSectionFingerprint]?
}

private struct SketchSectionFingerprint: Codable {
    var id: UUID
    var title: String?
    var drawing: SectionFileFingerprint
    var preview: SectionFileFingerprint
    var createdAt: Date
}

struct SectionEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let scope: JobScope
    let section: ScopeSection
    @ObservedObject var autosave: DebouncedAutosave
    @ObservedObject var sectionReviewStore: SectionReviewStore
    let sketchAction: (() -> Void)?
    @State private var showingPreview = false
    @State private var showingPhotos = false
    @State private var showingSketchSheet = false
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    @State private var previewActionToken = 0
    @State private var exportActionToken = 0
    @State private var photoActionToken = 0
    @State private var isRefreshingLinkedCustomer = false
    @State private var linkedCustomerRefreshMessage: String?
    @State private var linkedCustomerRefreshErrorMessage: String?

    private let customerDetailFetcher: JobTreadCustomerDetailFetching = JobTreadClient()

    private var isCurrentSectionComplete: Bool {
        sectionReviewStore.isComplete(section, in: scope)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassChromePanel(cornerRadius: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current Scope")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text(scope.displayName)
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                                    .contentTransition(.opacity)

                                if scope.showsSeparateCustomerIdentity,
                                   let customerName = scope.resolvedCustomerDisplayName {
                                    Text("Customer: \(customerName)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.opacity)
                                }

                                Text(section.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.opacity)
                            }

                            Spacer(minLength: 12)

                            StatusPill(status: scope.status)
                        }

                        Divider()
                            .opacity(0.45)

                        SectionReviewControl(
                            isComplete: isCurrentSectionComplete,
                            completedAt: sectionReviewStore.completedAt(for: section, in: scope),
                            markComplete: markCurrentSectionComplete
                        )
                    }
                }
                .padding(.bottom, 4)

                switch section {
                case .projectInfo:
                    ProjectInfoEditorView(
                        scope: scope,
                        autosave: autosave,
                        refreshLinkedCustomer: refreshLinkedCustomer,
                        isRefreshingLinkedCustomer: isRefreshingLinkedCustomer,
                        linkedCustomerRefreshMessage: linkedCustomerRefreshMessage,
                        linkedCustomerRefreshErrorMessage: linkedCustomerRefreshErrorMessage
                    )
                case .existingConditions:
                    ExistingConditionsEditorView(scope: scope, autosave: autosave)
                case .structuralSystem:
                    StructuralSystemEditorView(scope: scope, autosave: autosave)
                case .enclosure:
                    EnclosureEditorView(scope: scope, autosave: autosave)
                case .windowsAndGlass:
                    WindowsAndGlassEditorView(scope: scope, autosave: autosave)
                case .electrical:
                    ElectricalEditorView(scope: scope, autosave: autosave)
                case .drainage:
                    DrainageEditorView(scope: scope, autosave: autosave)
                case .attachmentConditions:
                    AttachmentConditionsEditorView(scope: scope, autosave: autosave)
                case .documents:
                    DocumentsEditorView(scope: scope, autosave: autosave)
                case .finishes:
                    FinishesEditorView(scope: scope, autosave: autosave)
                case .permitsHOA:
                    PermitsHOAEditorView(scope: scope, autosave: autosave)
                case .productionNotes:
                    ProductionNotesEditorView(scope: scope, autosave: autosave)
                case .signatureAndExport:
                    SignatureAndSketchEditorView(scope: scope, autosave: autosave)
                }
            }
            .padding(16)
            .frame(maxWidth: 900, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(LiquidGlassBackdrop())
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: scope.displayName)
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: scope.status)
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: section)
        .animation(.snappy(duration: 0.22, extraBounce: 0), value: isCurrentSectionComplete)
        .onChange(of: sectionContentFingerprints) { oldValue, newValue in
            invalidateChangedCompletedSections(oldValue: oldValue, newValue: newValue)
        }
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ControlGroup {
                    Button {
                        previewActionToken += 1
                        showingPreview = true
                    } label: {
                        ChromeActionIcon(systemName: "doc.text.magnifyingglass")
                    }
                    .symbolEffect(.bounce, value: previewActionToken)
                    .accessibilityLabel("Preview")
                    .accessibilityHint("Shows a PDF preview and missing required fields.")

                    Button {
                        exportActionToken += 1
                        exportPDF()
                    } label: {
                        ChromeActionIcon(systemName: "square.and.arrow.up")
                    }
                    .symbolEffect(.bounce, value: exportActionToken)
                    .accessibilityLabel("Export")
                    .accessibilityHint("Generates a flattened PDF and opens the share sheet.")

                    Button {
                        photoActionToken += 1
                        showingPhotos = true
                    } label: {
                        ChromeActionIcon(systemName: "photo.on.rectangle")
                    }
                    .symbolEffect(.bounce, value: photoActionToken)
                    .accessibilityLabel("Photos")
                    .accessibilityHint("Manage photo attachments for this scope.")

                    Button {
                        openSketchWorkspace()
                    } label: {
                        ChromeActionIcon(systemName: "pencil.and.scribble")
                    }
                    .accessibilityLabel(section == .signatureAndExport ? "Sketch tools" : "Open sketch tools")
                    .accessibilityHint("Opens signature and site diagram tools.")
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            NavigationStack {
                ScopePDFPreviewSheet(scope: scope)
            }
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingPhotos) {
            ScopePhotosSheet(scope: scope, autosave: autosave)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingSketchSheet) {
            NavigationStack {
                SignatureAndSketchSheet(scope: scope, autosave: autosave)
            }
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareURL {
                ActivityShareSheet(items: [shareURL])
            }
        }
        .alert("PDF Export Failed", isPresented: exportErrorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown export error occurred.")
        }
    }

    private var sectionContentFingerprints: [ScopeSection: ScopeSectionContentFingerprint] {
        Dictionary(
            uniqueKeysWithValues: ScopeSection.allCases.map { section in
                (section, ScopeSectionContentFingerprint(scope: scope, section: section))
            }
        )
    }

    private func markCurrentSectionComplete() {
        sectionReviewStore.markComplete(section, in: scope)
    }

    private func invalidateChangedCompletedSections(
        oldValue: [ScopeSection: ScopeSectionContentFingerprint],
        newValue: [ScopeSection: ScopeSectionContentFingerprint]
    ) {
        for section in ScopeSection.allCases where oldValue[section] != newValue[section] {
            sectionReviewStore.invalidate(section, in: scope)
        }
    }

    private func openSketchWorkspace() {
        if section == .signatureAndExport {
            return
        }

        if let sketchAction {
            sketchAction()
        } else {
            showingSketchSheet = true
        }
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func exportPDF() {
        do {
            let result = try ScopePDFExporter.generate(scope: scope)
            autosave.scheduleSave(for: scope)
            shareURL = result.fileURL
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshLinkedCustomer() {
        guard let linkedCustomer = scope.jobTreadCustomer else { return }

        linkedCustomerRefreshMessage = nil
        linkedCustomerRefreshErrorMessage = nil
        isRefreshingLinkedCustomer = true

        Task {
            do {
                guard let detail = try await customerDetailFetcher.fetchCustomerDetails(customerID: linkedCustomer.customerID) else {
                    await MainActor.run {
                        linkedCustomerRefreshErrorMessage = "JobTread did not return customer details for this linked scope."
                        isRefreshingLinkedCustomer = false
                    }
                    return
                }

                await MainActor.run {
                    scope.applyLinkedCustomerHydration(detail)
                    autosave.scheduleSave(for: scope)

                    do {
                        try modelContext.save()
                        linkedCustomerRefreshMessage = "Verified customer and contact fields refreshed from JobTread."
                    } catch {
                        assertionFailure("Failed to save refreshed customer details")
                        linkedCustomerRefreshErrorMessage = "Refreshed customer details could not be saved locally."
                    }

                    isRefreshingLinkedCustomer = false
                }
            } catch {
                await MainActor.run {
                    linkedCustomerRefreshErrorMessage = error.localizedDescription
                    isRefreshingLinkedCustomer = false
                }
            }
        }
    }
}

private struct SignatureAndSketchSheet: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            SignatureAndSketchEditorView(scope: scope, autosave: autosave)
                .padding(16)
        }
        .background(LiquidGlassBackdrop())
        .navigationTitle("Sketch Tools")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
