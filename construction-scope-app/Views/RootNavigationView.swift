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

struct RootNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JobScope.updatedAt, order: .reverse) private var scopes: [JobScope]

    @State private var selectedScopeID: UUID?
    @State private var selectedSection: ScopeSection = .projectInfo
    @StateObject private var autosave = DebouncedAutosave()

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
    }

    private var useCompactNavigation: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
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
                        createNewScope: createNewScope,
                        renameScope: renameScope,
                        deleteScope: deleteScope
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
        .onAppear {
            autosave.configure(with: modelContext)
            selectFirstScopeIfNeeded()
        }
        .onChange(of: scopes.map(\.id)) { _, _ in
            selectFirstScopeIfNeeded()
        }
    }

    private func createNewScope() {
        let newScope = ScopeTemplate.makeNewScope()
        modelContext.insert(newScope)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save new scope: \(error)")
        }

        selectedScopeID = newScope.id
        selectedSection = .projectInfo
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
    let renameScope: (JobScope, String) -> Void
    let deleteScope: (JobScope) -> Void

    @State private var scopePendingRename: JobScope?
    @State private var renameDraft = ""
    @State private var scopePendingDelete: JobScope?

    private var selectedScope: JobScope? {
        scopes.first(where: { $0.id == selectedScopeID })
    }

    var body: some View {
        List {
            Section {
                Button(action: createNewScope) {
                    Label("New Scope", systemImage: "plus.circle.fill")
                        .font(.body)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Section("Scopes") {
                ForEach(scopes) { scope in
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
                            scopePendingRename = scope
                            renameDraft = scope.displayName
                        }

                        Button("Delete Scope", role: .destructive) {
                            scopePendingDelete = scope
                        }
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
        .alert("Rename Scope", isPresented: renameAlertPresented) {
            TextField("Scope Name", text: $renameDraft)
            Button("Cancel", role: .cancel) {
                scopePendingRename = nil
                renameDraft = ""
            }
            Button("Save") {
                guard let scope = scopePendingRename else { return }
                renameScope(scope, renameDraft)
                scopePendingRename = nil
                renameDraft = ""
            }
        } message: {
            Text("Update the project name shown in your scope list.")
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

    private var renameAlertPresented: Binding<Bool> {
        Binding(
            get: { scopePendingRename != nil },
            set: { isPresented in
                if !isPresented {
                    scopePendingRename = nil
                    renameDraft = ""
                }
            }
        )
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
}

private struct PhoneScopesListView: View {
    let scopes: [JobScope]
    let createNewScope: () -> Void
    @ObservedObject var autosave: DebouncedAutosave
    let renameScope: (JobScope, String) -> Void
    let deleteScope: (JobScope) -> Void

    @State private var scopePendingRename: JobScope?
    @State private var renameDraft = ""
    @State private var scopePendingDelete: JobScope?

    var body: some View {
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
                    Button(action: createNewScope) {
                        Label("New Scope", systemImage: "plus")
                    }
                }
            }
        }
        .alert("Rename Scope", isPresented: renameAlertPresented) {
            TextField("Scope Name", text: $renameDraft)
            Button("Cancel", role: .cancel) {
                scopePendingRename = nil
                renameDraft = ""
            }
            Button("Save") {
                guard let scope = scopePendingRename else { return }
                renameScope(scope, renameDraft)
                scopePendingRename = nil
                renameDraft = ""
            }
        } message: {
            Text("Update the project name shown in your scope list.")
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

    private var renameAlertPresented: Binding<Bool> {
        Binding(
            get: { scopePendingRename != nil },
            set: { isPresented in
                if !isPresented {
                    scopePendingRename = nil
                    renameDraft = ""
                }
            }
        )
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
                case .enclosure:
                    EnclosureEditorView(scope: scope, autosave: autosave)
                case .windowsAndGlass:
                    WindowsAndGlassEditorView(scope: scope, autosave: autosave)
                case .attachmentConditions:
                    AttachmentConditionsEditorView(scope: scope, autosave: autosave)
                case .productionNotes:
                    ProductionNotesEditorView(scope: scope, autosave: autosave)
                case .signatureAndExport:
                    PDFPreviewStubView(scope: scope)
                default:
                    PlaceholderSectionView(section: section)
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
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .accessibilityLabel("Preview")

                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export")

                Button {
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
    }
}

private struct PlaceholderSectionView: View {
    let section: ScopeSection

    var body: some View {
        CardGroup(title: section.rawValue) {
            Label("Section editor is scaffolded for a later milestone.", systemImage: "hammer")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
