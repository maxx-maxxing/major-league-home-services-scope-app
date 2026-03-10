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

    private var useCompactNavigation: Bool {
        horizontalSizeClass == .compact
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
                        if let scope = selectedScope {
                            SectionEditorView(scope: scope, section: selectedSection, autosave: autosave)
                        } else {
                            ContentUnavailableView(
                                "No Scope Selected",
                                systemImage: "doc.badge.plus",
                                description: Text("Create a new scope to begin.")
                            )
                        }
                    }
                    .navigationSplitViewStyle(.balanced)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))

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
            cancelSidebarRename()
            return
        }

        sidebarRenameDepositing = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(170))
            if scopes.count > 1 {
                sidebarFolderPulseToken += 1
            }

            try? await Task.sleep(for: .milliseconds(360))
            cancelSidebarRename()
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
    @State private var animateScopesFolder = false
    @State private var scopePendingDelete: JobScope?
    @State private var newScopeRowFrame: CGRect = .zero

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
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
                if scopes.count > 1 {
                    DisclosureGroup(isExpanded: $scopesExpanded) {
                        ForEach(scopes) { scope in
                            scopeRow(for: scope)
                        }
                    } label: {
                        Label("Scopes", systemImage: "folder")
                            .font(.headline)
                            .scaleEffect(animateScopesFolder ? 1.08 : 1)
                            .symbolEffect(.bounce.byLayer, value: animateScopesFolder)
                            .animation(.spring(response: 0.32, dampingFraction: 0.58), value: animateScopesFolder)
                    }
                } else {
                    ForEach(scopes) { scope in
                        scopeRow(for: scope)
                    }
                }
            }

            if let selectedScope {
                Section("Current Scope") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedScope.displayName)
                            .font(.headline)
                        StatusPill(status: selectedScope.status)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }

                Section("Sections") {
                    ForEach(ScopeSection.allCases) { section in
                        Button {
                            selectedSection = section
                        } label: {
                            Label(section.rawValue, systemImage: section.symbol)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(selectedSection == section ? Color.secondary.opacity(0.14) : Color.clear)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Scopes")
        .onChange(of: folderPulseToken) { _, _ in
            guard scopes.count > 1 else { return }

            withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
                animateScopesFolder = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(420))
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    animateScopesFolder = false
                }
            }
        }
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

    @ViewBuilder
    private func scopeRow(for scope: JobScope) -> some View {
        Button {
            selectedScopeID = scope.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(scope.projectInfo.address.isEmpty ? "No address" : scope.projectInfo.address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedScopeID == scope.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename Scope") {
                requestRename(scope)
            }

            Button("Delete Scope", role: .destructive) {
                scopePendingDelete = scope
            }
        }
    }
}

private struct PhoneScopesListView: View {
    let scopes: [JobScope]
    let createNewScope: () -> JobScope
    @ObservedObject var autosave: DebouncedAutosave
    let renameScope: (JobScope, String) -> Void
    let deleteScope: (JobScope) -> Void

    @State private var scopePendingRename: JobScope?
    @State private var renameDraft = ""
    @State private var scopePendingDelete: JobScope?

    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    Section {
                        ForEach(scopes) { scope in
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
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
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
    }

    private func cancelRenamePrompt() {
        scopePendingRename = nil
        renameDraft = ""
    }

    private func saveRenamePrompt() {
        guard let scope = scopePendingRename else { return }
        let trimmedName = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        renameScope(scope, trimmedName)
        scopePendingRename = nil
        renameDraft = ""
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

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.16)
                    .ignoresSafeArea()
                    .transition(.opacity)

                renameCard
                    .frame(width: 380)
                    .position(cardCenter(in: proxy.size))
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: hasExpandedFromButton)
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: isDepositing)
            }
        }
        .ignoresSafeArea()
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
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name New Scope")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("This scope will be saved inside the Scopes folder.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            TextField("Scope Name", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 44)
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
                    .frame(maxWidth: .infinity, minHeight: 44)

                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(saveDisabled)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 18)
    }

    private func cardCenter(in containerSize: CGSize) -> CGPoint {
        if isDepositing {
            return CGPoint(x: 118, y: 150)
        }

        if hasExpandedFromButton {
            return CGPoint(
                x: min(max(220, 224), containerSize.width - 210),
                y: min(max(240, 272), containerSize.height - 180)
            )
        }

        return origin
    }

    private var cardScale: CGFloat {
        if isDepositing { return 0.14 }
        return hasExpandedFromButton ? 1 : 0.06
    }

    private var cardOpacity: Double {
        if isDepositing { return 0.1 }
        return hasExpandedFromButton ? 1 : 0.2
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
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .transition(.opacity)

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
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: 44)
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
                        .frame(maxWidth: .infinity, minHeight: 44)

                    Button("Save", action: onSave)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(saveDisabled)
                }
            }
            .padding(24)
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 18)
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
    @Bindable var scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        List {
            Section {
                ForEach(ScopeSection.allCases) { section in
                    NavigationLink {
                        SectionEditorView(scope: scope, section: section, autosave: autosave)
                    } label: {
                        Label(section.rawValue, systemImage: section.symbol)
                            .font(.body)
                            .frame(minHeight: 44)
                    }
                }
            }
        }
        .navigationTitle(scope.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionEditorView: View {
    @Bindable var scope: JobScope
    let section: ScopeSection
    @ObservedObject var autosave: DebouncedAutosave
    @State private var showingPreview = false
    @State private var showingPhotos = false
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scope.displayName)
                            .font(.title3)
                            .foregroundStyle(.primary)
                        Text(section.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    StatusPill(status: scope.status)
                }

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
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingPreview = true
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .accessibilityLabel("Preview")

                Button {
                    exportPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export")

                Button {
                    showingPhotos = true
                } label: {
                    Image(systemName: "photo.on.rectangle")
                }
                .accessibilityLabel("Photos")

                Button {
                } label: {
                    Image(systemName: "pencil.and.scribble")
                }
                .accessibilityLabel("Sketch")
            }
        }
        .sheet(isPresented: $showingPreview) {
            NavigationStack {
                ScopePDFPreviewSheet(scope: scope)
            }
        }
        .sheet(isPresented: $showingPhotos) {
            ScopePhotosSheet(scope: scope, autosave: autosave)
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
