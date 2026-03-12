import SwiftUI
import SwiftData

enum ScopeSection: String, CaseIterable, Identifiable {
    case projectInfo = "Project Information"
    case existingConditions = "Existing Conditions"
    case dimensions = "Dimensions"
    case structuralSystem = "Structural System"
    case enclosure = "Enclosure"
    case windowsAndGlass = "Windows & Glass"
    case electrical = "Electrical"
    case drainage = "Drainage"
    case attachmentConditions = "Attachment Conditions"
    case finishes = "Finishes"
    case permitsHOA = "Permits / HOA"
    case productionNotes = "Production Notes"
    case signatureAndExport = "Signature & Export"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .projectInfo: return "person.text.rectangle"
        case .existingConditions: return "house"
        case .dimensions: return "ruler"
        case .structuralSystem: return "building.columns"
        case .enclosure: return "rectangle.3.group"
        case .windowsAndGlass: return "window.casement"
        case .electrical: return "bolt"
        case .drainage: return "drop"
        case .attachmentConditions: return "link"
        case .finishes: return "paintbrush"
        case .permitsHOA: return "doc.text"
        case .productionNotes: return "note.text"
        case .signatureAndExport: return "signature"
        }
    }
}

private enum SidebarRenamePromptMode {
    case newScope
    case existingScope
}

private struct ProjectTypeScopeGroup: Identifiable {
    let projectType: ProjectType
    let scopes: [JobScope]

    var id: ProjectType { projectType }
}

private func groupedScopesByProjectType(_ scopes: [JobScope]) -> [ProjectTypeScopeGroup] {
    ProjectType.allCases.compactMap { projectType in
        let matchingScopes = scopes.filter { $0.projectInfo.projectType == projectType }
        guard !matchingScopes.isEmpty else { return nil }
        return ProjectTypeScopeGroup(projectType: projectType, scopes: matchingScopes)
    }
}

private let rootNavigationCoordinateSpace = "RootNavigationCoordinateSpace"
struct RootNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JobScope.updatedAt, order: .reverse) private var scopes: [JobScope]

    @State private var selectedScopeID: UUID?
    @State private var selectedSection: ScopeSection = .projectInfo
    @State private var sidebarRenameScope: JobScope?
    @State private var sidebarRenameDraft = ""
    @State private var sidebarRenameMode: SidebarRenamePromptMode = .existingScope
    @State private var sidebarRenameDepositing = false
    @State private var sidebarFolderPulseToken = 0
    @State private var sidebarRenameOrigin = CGPoint(x: 28, y: 28)
    @StateObject private var autosave = DebouncedAutosave()

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
    }

    private var groupedScopes: [ProjectTypeScopeGroup] {
        groupedScopesByProjectType(scopes)
    }

    private var useCompactNavigation: Bool {
        horizontalSizeClass == .compact
    }

    private var detailTransitionKey: String {
        "\(selectedScopeID?.uuidString ?? "none")-\(selectedSection.rawValue)"
    }

    var body: some View {
        ZStack {
            Group {
                if useCompactNavigation {
                    PhoneScopesListView(
                        scopes: scopes,
                        createNewScope: createNewScope,
                        autosave: autosave,
                        renameScope: renameScope,
                        deleteScope: deleteScope
                    )
                } else {
                    NavigationSplitView {
                        ScopeSidebarView(
                            scopes: scopes,
                            selectedScopeID: $selectedScopeID,
                            selectedSection: $selectedSection,
                            createNewScope: handleSidebarCreateScope,
                            requestRename: { beginSidebarRename(for: $0, mode: .existingScope) },
                            deleteScope: deleteScope,
                            folderPulseToken: sidebarFolderPulseToken,
                            newScopeTapPoint: $sidebarRenameOrigin
                        )
                    } detail: {
                        ZStack {
                            if let scope = selectedScope {
                                SectionEditorView(
                                    scope: scope,
                                    section: selectedSection,
                                    autosave: autosave,
                                    sketchAction: {
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
        }
        .coordinateSpace(name: rootNavigationCoordinateSpace)
        .onAppear {
            autosave.configure(with: modelContext)
            selectFirstScopeIfNeeded()
        }
        .onChange(of: scopes.map(\.id)) { _, _ in
            selectFirstScopeIfNeeded()
        }
    }

    private func handleSidebarCreateScope() {
        let newScope = createNewScope()
        beginSidebarRename(for: newScope, mode: .newScope)
    }

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
        let newScope = ScopeTemplate.makeNewScope()
        modelContext.insert(newScope)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save new scope: \(error)")
        }

        selectedScopeID = newScope.id
        selectedSection = .projectInfo
        return newScope
    }

    private func renameScope(_ scope: JobScope, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var projectInfo = scope.projectInfo
        projectInfo.clientName = trimmed
        scope.projectInfo = projectInfo
        scope.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to rename scope: \(error)")
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
                assertionFailure("Failed to delete scope: \(error)")
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

        selectedScopeID = scopes.first?.id
        selectedSection = .projectInfo
    }
}

private struct ScopeSidebarView: View {
    let scopes: [JobScope]
    @Binding var selectedScopeID: UUID?
    @Binding var selectedSection: ScopeSection
    let createNewScope: () -> Void
    let requestRename: (JobScope) -> Void
    let deleteScope: (JobScope) -> Void
    let folderPulseToken: Int
    @Binding var newScopeTapPoint: CGPoint

    @State private var scopesExpanded = false
    @State private var scopePendingDelete: JobScope?
    @State private var newScopeRowFrame: CGRect = .zero

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
    }

    private var groupedScopes: [ProjectTypeScopeGroup] {
        groupedScopesByProjectType(scopes)
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
            }

            Section {
                if !scopes.isEmpty {
                    DisclosureGroup(isExpanded: $scopesExpanded) {
                        groupedScopeList
                    } label: {
                        Label("Scopes", systemImage: "folder")
                            .font(.headline)
                            .symbolEffect(.bounce.byLayer, value: folderPulseToken)
                    }
                }
            }

            if let selectedScope {
                Section {
                    GlassChromePanel(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Current Scope")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Text(selectedScope.displayName)
                                .font(.headline)

                            StatusPill(status: selectedScope.status)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
                    .accessibilityElement(children: .combine)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                }

                Section("Sections") {
                    ForEach(ScopeSection.allCases) { section in
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
                        .accessibilityValue(selectedSection == section ? "Selected" : "")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: scopes.map(\.id))
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
    private var groupedScopeList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(groupedScopes) { group in
                VStack(alignment: .leading, spacing: 6) {
                    projectTypeGroupHeader(for: group.projectType, count: group.scopes.count)

                    ForEach(group.scopes) { scope in
                        scopeRow(for: scope)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sidebarSectionLabel(for section: ScopeSection) -> some View {
        let isSelected = selectedSection == section

        // Keep selection pooled into the sidebar row itself so it reads like
        // integrated system chrome rather than a floating sticker.
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.8) : .clear)
                .frame(width: 3, height: 26)

            Label(section.rawValue, systemImage: section.symbol)
                .font(.body.weight(isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))

            Spacer(minLength: 0)
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

    @ViewBuilder
    private func projectTypeGroupHeader(for projectType: ProjectType, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(projectType.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Circle()
                .fill(.secondary.opacity(0.2))
                .frame(width: 4, height: 4)

            Text(count == 1 ? "1 scope" : "\(count) scopes")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    @ViewBuilder
    private func scopeRow(for scope: JobScope) -> some View {
        let isSelected = selectedScopeID == scope.id

        Button {
            withAnimation(.snappy(duration: 0.26, extraBounce: 0)) {
                selectedScopeID = scope.id
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
                    Text(scope.projectInfo.address.isEmpty ? "No address" : scope.projectInfo.address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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

private struct PhoneScopesListView: View {
    let scopes: [JobScope]
    let createNewScope: () -> JobScope
    @ObservedObject var autosave: DebouncedAutosave
    let renameScope: (JobScope, String) -> Void
    let deleteScope: (JobScope) -> Void

    @State private var scopePendingRename: JobScope?
    @State private var renamePromptMode: SidebarRenamePromptMode = .existingScope
    @State private var renameDraft = ""
    @State private var scopePendingDelete: JobScope?

    private var groupedScopes: [ProjectTypeScopeGroup] {
        groupedScopesByProjectType(scopes)
    }

    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(groupedScopes) { group in
                        Section {
                            ForEach(group.scopes) { scope in
                                NavigationLink {
                                    PhoneSectionListView(scope: scope, autosave: autosave)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(scope.displayName)
                                                .font(.body)
                                            Text(scope.projectInfo.address.isEmpty ? "No address" : scope.projectInfo.address)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                        StatusPill(status: scope.status)
                                    }
                                    .frame(minHeight: 44)
                                }
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
                        } header: {
                            PhoneProjectTypeHeader(projectType: group.projectType, count: group.scopes.count)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(LiquidGlassBackdrop())
                .navigationTitle("Scopes")
                .toolbar {
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
                    message: "Update the project name shown in your scope list.",
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
        let newScope = createNewScope()
        scopePendingRename = newScope
        renameDraft = ""
        renamePromptMode = .newScope
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
}

private struct PhoneProjectTypeHeader: View {
    let projectType: ProjectType
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(projectType.displayName)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)

            Text(count == 1 ? "1 scope" : "\(count) scopes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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

                TextField("Name", text: $text)
                    .liquidGlassInput()
                    .focused($nameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !saveDisabled {
                            handleSave()
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

                    TextField("Scope Name", text: $text)
                        .liquidGlassInput()
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if !saveDisabled {
                                onSave()
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

    var body: some View {
        List {
            Section {
                ForEach(ScopeSection.allCases) { section in
                    NavigationLink {
                        SectionEditorView(scope: scope, section: section, autosave: autosave, sketchAction: nil)
                    } label: {
                        Label(section.rawValue, systemImage: section.symbol)
                            .font(.body)
                            .frame(minHeight: 44)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(LiquidGlassBackdrop())
        .navigationTitle(scope.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionEditorView: View {
    let scope: JobScope
    let section: ScopeSection
    @ObservedObject var autosave: DebouncedAutosave
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassChromePanel(cornerRadius: 24) {
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

                            Text(section.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .contentTransition(.opacity)
                        }

                        Spacer(minLength: 12)

                        StatusPill(status: scope.status)
                    }
                }
                .padding(.bottom, 4)

                switch section {
                case .projectInfo:
                    ProjectInfoEditorView(scope: scope, autosave: autosave)
                case .existingConditions:
                    ExistingConditionsEditorView(scope: scope, autosave: autosave)
                case .dimensions:
                    DimensionsEditorView(scope: scope, autosave: autosave)
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
            shareURL = result.fileURL
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
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
