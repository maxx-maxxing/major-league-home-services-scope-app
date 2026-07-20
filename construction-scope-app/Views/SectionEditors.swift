
import SwiftUI
import SwiftData
import PencilKit
import PhotosUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct ProjectInfoEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave
    let refreshLinkedCustomer: (() -> Void)?
    let isRefreshingLinkedCustomer: Bool
    let linkedCustomerRefreshMessage: String?
    let linkedCustomerRefreshErrorMessage: String?

    private var hasLinkedCustomer: Bool {
        scope.hasLinkedJobTreadCustomer
    }

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Scope") {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledTextField("Scope Title", text: scopeTitleBinding, prompt: "Enter scope title")

                    Text("This local title is shown in the scope list and editor headers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let linkedCustomerName = scope.resolvedLinkedCustomerName {
                CardGroup(title: "Linked Customer") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(linkedCustomerName)
                                    .font(.body.weight(.medium))

                                Text(
                                    JobTreadConfig.isDirectAccessEnabled
                                        ? "Verified JobTread-owned customer fields below are read-only and refresh from JobTread."
                                        : "Verified JobTread-owned customer fields below are read-only. Direct refresh is unavailable in this build."
                                )
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let fetchedAt = scope.jobTreadCustomer?.fetchedAt {
                                    Text("Customer details refreshed \(fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 12)

                            if JobTreadConfig.isDirectAccessEnabled, let refreshLinkedCustomer {
                                Button {
                                    refreshLinkedCustomer()
                                } label: {
                                    if isRefreshingLinkedCustomer {
                                        ProgressView()
                                            .frame(minWidth: 120, minHeight: 44)
                                    } else {
                                        Label("Refresh from JobTread", systemImage: "arrow.clockwise")
                                            .frame(minHeight: 44)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(isRefreshingLinkedCustomer)
                            } else if !JobTreadConfig.isDirectAccessEnabled {
                                Label("Refresh unavailable", systemImage: "lock.shield")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let linkedCustomerRefreshMessage {
                            Text(linkedCustomerRefreshMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let linkedCustomerRefreshErrorMessage {
                            Text(linkedCustomerRefreshErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            CardGroup(title: hasLinkedCustomer ? "Customer (JobTread)" : "Customer") {
                VStack(spacing: 12) {
                    if hasLinkedCustomer {
                        ReadOnlyProjectField(title: "Customer Name", value: scope.projectInfo.clientName, placeholder: "No customer name")

                        HStack(spacing: 12) {
                            ReadOnlyProjectField(title: "Address", value: scope.projectInfo.address, placeholder: "No street address")
                            ReadOnlyProjectField(title: "Unit Number", value: scope.projectInfo.unitNumber, placeholder: "Not provided")
                        }

                        if scope.shouldShowMissingLinkedStreetAddressHint {
                            Text("JobTread provided city/state/ZIP, but no usable street address line.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            ReadOnlyProjectField(title: "City", value: scope.projectInfo.city, placeholder: "Not provided")
                            ReadOnlyProjectField(title: "State", value: scope.projectInfo.state, placeholder: "Not provided")
                            ReadOnlyProjectField(title: "ZIP", value: scope.projectInfo.zip, placeholder: "Not provided")
                        }

                        ReadOnlyContactProjectField(
                            title: "Phone",
                            value: scope.projectInfo.phone,
                            displayValue: formattedUSPhoneNumber(scope.projectInfo.phone),
                            placeholder: "Not provided",
                            kind: .phone
                        )

                        ReadOnlyContactProjectField(
                            title: "Email",
                            value: scope.projectInfo.email,
                            placeholder: "Not provided",
                            kind: .email
                        )
                    } else {
                        LabeledTextField("Customer Name", text: requiredStringBinding(\.clientName), prompt: "Enter customer name", isRequired: true)
                        LabeledTextField("Address", text: requiredStringBinding(\.address), prompt: "Street address", isRequired: true)
                        LabeledTextField("Unit Number", text: optionalStringBinding(\.unitNumber), prompt: "Apartment, suite, etc.")

                        HStack(spacing: 12) {
                            LabeledTextField("City", text: optionalStringBinding(\.city))

                            LabeledTextField("State", text: optionalStringBinding(\.state))
                                .textInputAutocapitalization(.characters)

                            LabeledTextField("ZIP", text: constrainedOptionalStringBinding(\.zip))
                                .keyboardType(.numberPad)
                        }
                    }
                }
            }

            CardGroup(title: hasLinkedCustomer ? "Project Team" : "Contact") {
                VStack(spacing: 12) {
                    if !hasLinkedCustomer {
                        LabeledTextField("Phone", text: constrainedOptionalStringBinding(\.phone))
                            .keyboardType(.phonePad)

                        LabeledTextField("Email", text: constrainedOptionalStringBinding(\.email))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }

                    LabeledTextField("Salesperson", text: optionalStringBinding(\.salesperson))
                    LabeledTextField("Estimator", text: optionalStringBinding(\.estimator))
                }
            }

            CardGroup(title: "Project") {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project Type")
                            .font(.body)

                        Text(projectTypeSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(ProjectType.selectableCases, id: \.self) { type in
                            MultiSelectOptionRow(
                                title: type.displayName,
                                isSelected: isProjectTypeSelected(type)
                            ) {
                                toggleProjectType(type)
                            }
                        }
                    }

                    Toggle("Include Site Visit Date", isOn: includesSiteVisitDateBinding)
                        .frame(minHeight: 44)

                    if scope.projectInfo.siteVisitDate != nil {
                        DatePicker(
                            "Site Visit Date",
                            selection: siteVisitDateBinding,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.body)
                        TextEditor(text: notesBinding)
                            .frame(minHeight: 140)
                            .padding(8)
                            .liquidGlassInputBackground(cornerRadius: 14)
                    }
                }
            }
        }
        .animation(.formReveal, value: scope.projectInfo.siteVisitDate != nil)
    }

    private var projectTypeSummary: String {
        scope.projectInfo.activeProjectTypes.isEmpty ? "No project types selected" : scope.projectInfo.projectTypeDisplaySummary
    }

    private func isProjectTypeSelected(_ type: ProjectType) -> Bool {
        scope.projectInfo.activeProjectTypes.contains(type)
    }

    private func toggleProjectType(_ type: ProjectType) {
        updateProjectInfo { info in
            info.setProjectType(type, isSelected: !info.activeProjectTypes.contains(type))
        }
    }

    private var scopeTitleBinding: Binding<String> {
        Binding(
            get: { scope.editableScopeTitle },
            set: { newValue in
                scope.setEditableScopeTitle(newValue)
                autosave.scheduleSave(for: scope)
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.projectInfo.notes ?? "" },
            set: { newValue in
                updateProjectInfo { $0.notes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var includesSiteVisitDateBinding: Binding<Bool> {
        Binding(
            get: { scope.projectInfo.siteVisitDate != nil },
            set: { newValue in
                updateProjectInfo { info in
                    info.siteVisitDate = newValue ? (info.siteVisitDate ?? .now) : nil
                }
            }
        )
    }

    private var siteVisitDateBinding: Binding<Date> {
        Binding(
            get: { scope.projectInfo.siteVisitDate ?? .now },
            set: { newValue in
                updateProjectInfo { $0.siteVisitDate = newValue }
            }
        )
    }

    private func requiredStringBinding(_ keyPath: WritableKeyPath<ProjectInfo, String>) -> Binding<String> {
        Binding(
            get: { scope.projectInfo[keyPath: keyPath] },
            set: { newValue in
                updateProjectInfo { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private func optionalStringBinding(_ keyPath: WritableKeyPath<ProjectInfo, String?>) -> Binding<String> {
        Binding(
            get: { scope.projectInfo[keyPath: keyPath] ?? "" },
            set: { newValue in
                updateProjectInfo { $0[keyPath: keyPath] = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func constrainedOptionalStringBinding(_ keyPath: WritableKeyPath<ProjectInfo, String?>) -> Binding<String> {
        Binding(
            get: { scope.projectInfo[keyPath: keyPath] ?? "" },
            set: { newValue in
                updateProjectInfo { $0[keyPath: keyPath] = newValue.nilIfBlank }
            }
        )
    }

    private func updateProjectInfo(_ update: (inout ProjectInfo) -> Void) {
        var info = scope.projectInfo
        update(&info)
        scope.projectInfo = info
        autosave.scheduleSave(for: scope)
    }
}

private struct ReadOnlyProjectField: View {
    let title: String
    let value: String?
    let placeholder: String

    init(title: String, value: String?, placeholder: String) {
        self.title = title
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.value = (trimmed?.isEmpty == true) ? nil : trimmed
        self.placeholder = placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body)

            HStack(spacing: 8) {
                Text(value ?? placeholder)
                    .foregroundStyle(value == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .liquidGlassInputBackground(cornerRadius: 14)
        }
    }
}

private enum ReadOnlyContactFieldKind {
    case phone
    case email
}

private struct ReadOnlyContactProjectField: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let value: String?
    let displayValue: String?
    let placeholder: String
    let kind: ReadOnlyContactFieldKind

    init(
        title: String,
        value: String?,
        displayValue: String? = nil,
        placeholder: String,
        kind: ReadOnlyContactFieldKind
    ) {
        self.title = title
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.value = (trimmed?.isEmpty == true) ? nil : trimmed

        let trimmedDisplay = displayValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayValue = (trimmedDisplay?.isEmpty == true) ? nil : trimmedDisplay
        self.placeholder = placeholder
        self.kind = kind
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body)

            HStack(spacing: 8) {
                Text(displayValue ?? value ?? placeholder)
                    .foregroundStyle(value == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(kind == .email ? .middle : .tail)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                if value != nil {
                    Menu {
                        actionMenuItems
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("\(title) actions")
                }

                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .liquidGlassInputBackground(cornerRadius: 14)
        }
    }

    @ViewBuilder
    private var actionMenuItems: some View {
        switch kind {
        case .phone:
            if let phoneURL {
                Button {
                    openURL(phoneURL)
                } label: {
                    Label("Call", systemImage: "phone")
                }
            }

            if let copyValue = displayValue ?? value {
                Button {
                    copyToPasteboard(copyValue)
                } label: {
                    Label("Copy Number", systemImage: "doc.on.doc")
                }
            }
        case .email:
            if let emailURL {
                Button {
                    openURL(emailURL)
                } label: {
                    Label("Email", systemImage: "envelope")
                }
            }

            if let value {
                Button {
                    copyToPasteboard(value)
                } label: {
                    Label("Copy Email", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private var phoneURL: URL? {
        guard case .phone = kind,
              let value,
              let dialableDigits = normalizedUSPhoneDigits(value) else { return nil }

        return URL(string: "tel:\(dialableDigits)")
    }

    private var emailURL: URL? {
        guard case .email = kind, let value else { return nil }
        return URL(string: "mailto:\(value)")
    }

    private func copyToPasteboard(_ value: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        #endif
    }
}

private func formattedUSPhoneNumber(_ value: String?) -> String? {
    guard let value,
          let localDigits = normalizedUSPhoneDigits(value) else {
        return value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    let digits = Array(localDigits)
    return "(\(String(digits[0..<3]))) \(String(digits[3..<6]))-\(String(digits[6..<10]))"
}

private func normalizedUSPhoneDigits(_ value: String) -> String? {
    let digits = value.filter(\.isNumber)

    if digits.count == 10 {
        return digits
    }

    if digits.count == 11, digits.first == "1" {
        return String(digits.dropFirst())
    }

    return nil
}

struct ExistingConditionsEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    @State private var activePhotoChecklistCategory: PhotoChecklistCategory?
    @State private var showingChecklistFileImporter = false
    @State private var selectedChecklistPhotoItem: PhotosPickerItem?
    @State private var showingChecklistPhotoPicker = false
    @State private var showingChecklistCameraPicker = false
    @State private var checklistImportError: String?
    @State private var expandedChecklistCategories: Set<PhotoChecklistCategory> = []
    @State private var previewingChecklistPhoto: PhotoChecklistPreviewItem?
    @State private var checklistRefreshToken = UUID()

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Site Snapshot") {
                VStack(alignment: .leading, spacing: 12) {
                    FieldHeader("House Stories")
                    Picker("House Stories", selection: houseStoriesBinding) {
                        Text("Not Set").tag(nil as HouseStories?)
                        ForEach(HouseStories.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    FieldHeader("Exterior Finish")
                    Text(exteriorFinishSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(ExteriorFinishArea.allCases, id: \.self) { area in
                        MultiSelectOptionRow(
                            title: area.displayName,
                            isSelected: isExteriorFinishAreaSelected(area)
                        ) {
                            toggleExteriorFinishArea(area)
                        }
                    }

                    if isExteriorFinishAreaSelected(.postsColumns) {
                        VStack(alignment: .leading, spacing: 12) {
                            FieldHeader("Posts/Columns Material")
                            Text(postsColumnsMaterialsSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(PostsColumnsMaterial.allCases, id: \.self) { material in
                                MultiSelectOptionRow(
                                    title: material.displayName,
                                    isSelected: isPostsColumnsMaterialSelected(material)
                                ) {
                                    togglePostsColumnsMaterial(material)
                                }
                            }

                            OptionalBoolPicker(title: "Post Trim", selection: postTrimBinding)

                            LabeledTextField("Trim Thickness", text: trimThicknessBinding, prompt: "Enter trim thickness")
                        }
                        .padding(.leading, 16)
                        .formRevealTransition()
                    }

                    if isExteriorFinishAreaSelected(.exteriorHouseWall) {
                        VStack(alignment: .leading, spacing: 12) {
                            FieldHeader("Exterior House Wall Material")
                            Text(exteriorHouseWallMaterialsSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(ExteriorHouseWallMaterial.allCases, id: \.self) { material in
                                MultiSelectOptionRow(
                                    title: material.displayName,
                                    isSelected: isExteriorHouseWallMaterialSelected(material)
                                ) {
                                    toggleExteriorHouseWallMaterial(material)
                                }
                            }

                            if isExteriorHouseWallOtherSelected {
                                LabeledTextField(
                                    "Exterior House Wall -> Other",
                                    text: exteriorHouseWallOtherBinding,
                                    prompt: "Describe Exterior House Wall -> Other",
                                    helperText: "Required when Exterior House Wall -> Other is selected.",
                                    isRequired: true
                                )
                                .formRevealTransition()
                            }
                        }
                        .padding(.leading, 16)
                        .formRevealTransition()
                    }

                    FieldHeader("Existing Structure")
                    Text(existingStructureSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(ExistingStructure.allCases, id: \.self) { value in
                        MultiSelectOptionRow(
                            title: value.displayName,
                            isSelected: isExistingStructureSelected(value)
                        ) {
                            toggleExistingStructure(value)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Existing Structure Notes")
                            .font(.body)
                        NotesField(
                            title: "Existing Structure Notes",
                            text: existingStructureNotesBinding,
                            minHeight: 100,
                            showInlineTitle: false,
                            prompt: "Add notes specific to existing structure"
                        )
                    }
                    .padding(.top, 4)
                }
            }

            CardGroup(title: "Field Notes") {
                VStack(spacing: 12) {
                    NotesField(title: "Obstacles", text: obstaclesNotesBinding, minHeight: 100)
                    NotesField(title: "Utilities", text: utilitiesNotesBinding, minHeight: 100)
                    NotesField(title: "HOA Notes", text: hoaNotesBinding, minHeight: 100)
                }
            }

            CardGroup(title: "Photo Checklist") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Capture labeled Existing Conditions evidence directly inside each checklist category.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(photoChecklistSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(PhotoChecklistCategory.allCases, id: \.self) { category in
                        PhotoChecklistCategoryRow(
                            category: category,
                            photos: checklistPhotos(for: category),
                            isExpanded: expandedChecklistCategories.contains(category),
                            presentImporter: { source in
                                presentPhotoChecklistImporter(source, for: category)
                            },
                            toggleExpanded: {
                                toggleChecklistCategoryExpansion(category)
                            },
                            previewPhoto: { photo in
                                previewingChecklistPhoto = PhotoChecklistPreviewItem(
                                    category: category,
                                    attachment: photo
                                )
                            },
                            removePhoto: { photo in
                                removeChecklistPhoto(photo, from: category)
                            }
                        )

                        if category != PhotoChecklistCategory.allCases.last {
                            Divider()
                        }
                    }
                }
            }

            if shouldRenderChecklistImportPresenter {
                DocumentImportPresenter(
                    showingFileImporter: $showingChecklistFileImporter,
                    selectedPhotoItem: $selectedChecklistPhotoItem,
                    showingPhotoPicker: $showingChecklistPhotoPicker,
                    showingCameraPicker: $showingChecklistCameraPicker,
                    importError: $checklistImportError,
                    allowedContentTypes: [.image],
                    errorTitle: "Checklist Photo Import Failed",
                    errorFallbackMessage: "Unable to import the selected checklist photo.",
                    handleFileImportResult: handleChecklistFileImportResult,
                    importSelectedPhotoItem: importSelectedChecklistPhotoItem,
                    importCameraImage: importChecklistCameraImage,
                    resetImportPresentation: resetChecklistImportPresentation
                )
            }
        }
        .animation(.formReveal, value: exteriorFinishSelectionToken)
        .animation(.formReveal, value: existingStructureSelectionToken)
        .animation(.formReveal, value: photoChecklistAnimationToken)
        .sheet(item: $previewingChecklistPhoto) { item in
            ChecklistPhotoPreviewSheet(
                item: item,
                onRemove: {
                    removeChecklistPhoto(item.attachment, from: item.category)
                    previewingChecklistPhoto = nil
                }
            )
        }
    }

    private var houseStoriesBinding: Binding<HouseStories?> {
        Binding(
            get: { scope.existingConditions?.houseStories },
            set: { newValue in
                updateExistingConditions { $0.houseStories = newValue }
            }
        )
    }

    private var obstaclesNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.obstaclesNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.obstaclesNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var existingStructureNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.existingStructureNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.existingStructureNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var utilitiesNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.utilitiesNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.utilitiesNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var hoaNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.hoaNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.hoaNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var postTrimBinding: Binding<Bool?> {
        Binding(
            get: { scope.existingConditions?.exteriorFinish?.postTrim },
            set: { newValue in
                updateExistingConditions { conditions in
                    var finish = conditions.exteriorFinish ?? ExistingConditionsExteriorFinish()
                    finish.postTrim = newValue
                    conditions.exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
                }
            }
        )
    }

    private var trimThicknessBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.exteriorFinish?.trimThickness ?? "" },
            set: { newValue in
                updateExistingConditions { conditions in
                    var finish = conditions.exteriorFinish ?? ExistingConditionsExteriorFinish()
                    finish.trimThickness = newValue.nilIfWhitespaceOnly
                    conditions.exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
                }
            }
        )
    }

    private var exteriorHouseWallOtherBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.exteriorFinish?.exteriorHouseWallOther ?? "" },
            set: { newValue in
                updateExistingConditions { conditions in
                    var finish = conditions.exteriorFinish ?? ExistingConditionsExteriorFinish()
                    finish.exteriorHouseWallOther = newValue.nilIfWhitespaceOnly
                    conditions.exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
                }
            }
        )
    }

    private var exteriorFinishSummary: String {
        scope.existingConditions?.exteriorFinish?.displaySummary ?? "Select one or both finish areas."
    }

    private var postsColumnsMaterialsSummary: String {
        scope.existingConditions?.exteriorFinish?.postsColumnsMaterialDisplaySummary ?? "Select one or more materials."
    }

    private var exteriorHouseWallMaterialsSummary: String {
        scope.existingConditions?.exteriorFinish?.exteriorHouseWallMaterialDisplaySummary ?? "Select one or more materials."
    }

    private var existingStructureSummary: String {
        scope.existingConditions?.existingStructureDisplaySummary ?? "Select any existing structure conditions that apply."
    }

    private var isExteriorHouseWallOtherSelected: Bool {
        scope.existingConditions?.exteriorFinish?.hasExteriorHouseWallOtherSelection == true
    }

    private var exteriorFinishSelectionToken: String {
        let finish = scope.existingConditions?.exteriorFinish
        let selectedAreas = finish?.activeSelectedAreas.map(\.rawValue).joined(separator: "|") ?? ""
        let posts = finish?.postsColumnsMaterials?.map(\.rawValue).joined(separator: "|") ?? ""
        let wall = finish?.exteriorHouseWallMaterials?.map(\.rawValue).joined(separator: "|") ?? ""
        let postTrim = finish?.postTrim.map { String($0) } ?? ""
        return "\(selectedAreas)#\(posts)#\(wall)#\(postTrim)"
    }

    private var existingStructureSelectionToken: String {
        scope.existingConditions?.activeExistingStructures.map(\.rawValue).joined(separator: "|") ?? ""
    }

    private var photoChecklistAnimationToken: String {
        PhotoChecklistCategory.allCases.map { category in
            let photos = checklistPhotos(for: category)
            let ids = photos.map { $0.id.uuidString }.joined(separator: ",")
            let expanded = expandedChecklistCategories.contains(category) ? "1" : "0"
            return "\(category.rawValue):\(ids):\(expanded)"
        }.joined(separator: "|") + "#\(checklistRefreshToken.uuidString)"
    }

    private var photoChecklistSummary: String {
        ChecklistPhotoAssetStore.summary(scopeID: scope.id) ?? "No checklist photos attached yet."
    }

    private func isExteriorFinishAreaSelected(_ area: ExteriorFinishArea) -> Bool {
        scope.existingConditions?.exteriorFinish?.activeSelectedAreas.contains(area) == true
    }

    private func isPostsColumnsMaterialSelected(_ material: PostsColumnsMaterial) -> Bool {
        scope.existingConditions?.exteriorFinish?.postsColumnsMaterials?.contains(material) == true
    }

    private func isExteriorHouseWallMaterialSelected(_ material: ExteriorHouseWallMaterial) -> Bool {
        scope.existingConditions?.exteriorFinish?.exteriorHouseWallMaterials?.contains(material) == true
    }

    private func isExistingStructureSelected(_ value: ExistingStructure) -> Bool {
        scope.existingConditions?.activeExistingStructures.contains(value) == true
    }

    private func toggleExteriorFinishArea(_ area: ExteriorFinishArea) {
        updateExistingConditions { conditions in
            var finish = conditions.exteriorFinish ?? ExistingConditionsExteriorFinish()
            finish.setArea(area, isSelected: !finish.activeSelectedAreas.contains(area))
            conditions.exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
        }
    }

    private func togglePostsColumnsMaterial(_ material: PostsColumnsMaterial) {
        updateExistingConditions { conditions in
            var finish = conditions.exteriorFinish ?? ExistingConditionsExteriorFinish()
            finish.setPostsColumnsMaterial(
                material,
                isSelected: !(finish.postsColumnsMaterials?.contains(material) == true)
            )
            conditions.exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
        }
    }

    private func toggleExteriorHouseWallMaterial(_ material: ExteriorHouseWallMaterial) {
        updateExistingConditions { conditions in
            var finish = conditions.exteriorFinish ?? ExistingConditionsExteriorFinish()
            finish.setExteriorHouseWallMaterial(
                material,
                isSelected: !(finish.exteriorHouseWallMaterials?.contains(material) == true)
            )
            conditions.exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
        }
    }

    private func toggleExistingStructure(_ value: ExistingStructure) {
        updateExistingConditions { $0.setExistingStructure(value, isSelected: !($0.activeExistingStructures.contains(value))) }
    }

    private var shouldRenderChecklistImportPresenter: Bool {
        activePhotoChecklistCategory != nil ||
        showingChecklistFileImporter ||
        showingChecklistPhotoPicker ||
        showingChecklistCameraPicker ||
        checklistImportError != nil
    }

    private func checklistPhotos(for category: PhotoChecklistCategory) -> [DocumentAttachmentFile] {
        ChecklistPhotoAssetStore.photos(scopeID: scope.id, category: category)
    }

    private func toggleChecklistCategoryExpansion(_ category: PhotoChecklistCategory) {
        if expandedChecklistCategories.contains(category) {
            expandedChecklistCategories.remove(category)
        } else {
            expandedChecklistCategories.insert(category)
        }
    }

    private func presentPhotoChecklistImporter(_ source: DocumentImportSource, for category: PhotoChecklistCategory) {
        activePhotoChecklistCategory = category
        selectedChecklistPhotoItem = nil

        switch source {
        case .files:
            showingChecklistFileImporter = true
        case .photoLibrary:
            showingChecklistPhotoPicker = true
        case .camera:
            showingChecklistCameraPicker = true
        }
    }

    private func resetChecklistImportPresentation(_ clearActiveCategory: Bool) {
        showingChecklistFileImporter = false
        showingChecklistPhotoPicker = false
        showingChecklistCameraPicker = false
        selectedChecklistPhotoItem = nil

        if clearActiveCategory {
            activePhotoChecklistCategory = nil
        }
    }

    private func handleChecklistFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                resetChecklistImportPresentation(true)
                return
            }

            let category = activePhotoChecklistCategory
            let scopeID = scope.id

            Task {
                do {
                    _ = try await Task.detached(priority: .userInitiated) {
                        try ChecklistPhotoAssetStore.importFile(from: url, scopeID: scopeID, category: category)
                    }.value

                    await MainActor.run {
                        persistImportedChecklistPhoto(for: category)
                        resetChecklistImportPresentation(true)
                    }
                } catch {
                    await MainActor.run {
                        checklistImportError = error.localizedDescription
                        resetChecklistImportPresentation(true)
                    }
                }
            }
        case .failure(let error):
            checklistImportError = error.localizedDescription
            resetChecklistImportPresentation(true)
        }
    }

    private func importSelectedChecklistPhotoItem(_ item: PhotosPickerItem) {
        Task {
            do {
                let category = activePhotoChecklistCategory
                _ = try await ChecklistPhotoAssetStore.importPhotoLibraryItem(
                    item,
                    scopeID: scope.id,
                    category: category
                )

                await MainActor.run {
                    persistImportedChecklistPhoto(for: category)
                    resetChecklistImportPresentation(true)
                }
            } catch {
                await MainActor.run {
                    checklistImportError = error.localizedDescription
                    resetChecklistImportPresentation(true)
                }
            }
        }
    }

    #if canImport(UIKit)
    private func importChecklistCameraImage(_ image: UIImage) {
        do {
            _ = try ChecklistPhotoAssetStore.saveCameraImage(
                image,
                scopeID: scope.id,
                category: activePhotoChecklistCategory
            )
            persistImportedChecklistPhoto(for: activePhotoChecklistCategory)
            resetChecklistImportPresentation(true)
        } catch {
            checklistImportError = error.localizedDescription
            resetChecklistImportPresentation(true)
        }
    }
    #endif

    private func persistImportedChecklistPhoto(for category: PhotoChecklistCategory?) {
        guard let category else { return }

        expandedChecklistCategories.insert(category)
        activePhotoChecklistCategory = nil
        recordChecklistFilesystemMutation()
    }

    private func removeChecklistPhoto(_ attachment: DocumentAttachmentFile, from category: PhotoChecklistCategory) {
        _ = category
        ChecklistPhotoAssetStore.removePhoto(at: attachment.filePath)
        recordChecklistFilesystemMutation()
    }

    private func recordChecklistFilesystemMutation() {
        checklistRefreshToken = UUID()
        scope.updatedAt = .now
        autosave.flush(scope: scope)
    }

    private func updateExistingConditions(_ update: (inout ExistingConditions) -> Void) {
        var conditions = scope.existingConditions ?? emptyExistingConditions()
        update(&conditions)
        scope.existingConditions = conditions.isEffectivelyEmpty ? nil : conditions
        autosave.scheduleSave(for: scope)
    }
}

private struct PhotoChecklistPreviewItem: Identifiable {
    let category: PhotoChecklistCategory
    let attachment: DocumentAttachmentFile

    var id: UUID { attachment.id }
}

private struct PhotoChecklistCategoryRow: View {
    let category: PhotoChecklistCategory
    let photos: [DocumentAttachmentFile]
    let isExpanded: Bool
    let presentImporter: (DocumentImportSource) -> Void
    let toggleExpanded: () -> Void
    let previewPhoto: (DocumentAttachmentFile) -> Void
    let removePhoto: (DocumentAttachmentFile) -> Void

    private var summaryText: String {
        if photos.isEmpty {
            return "No checklist photos attached."
        }

        return photos.count == 1 ? "1 photo attached" : "\(photos.count) photos attached"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: toggleExpanded) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(summaryText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Menu {
                    Button("Files") {
                        presentImporter(.files)
                    }

                    Button("Photo Library") {
                        presentImporter(.photoLibrary)
                    }

                    #if canImport(UIKit)
                    if DocumentCameraPicker.isCameraAvailable {
                        Button("Camera") {
                            presentImporter(.camera)
                        }
                    }
                    #endif
                } label: {
                    Label(photos.isEmpty ? "Add" : "Add More", systemImage: photos.isEmpty ? "plus.circle.fill" : "plus")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .frame(minHeight: 44)
            }

            if photos.isEmpty {
                Button(action: toggleExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.on.rectangle")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            Text("Capture, choose, or attach images for \(category.displayName.lowercased()).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.thinMaterial)
                    }
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos) { photo in
                            PhotoChecklistThumbnailView(
                                attachment: photo,
                                size: isExpanded ? CGSize(width: 140, height: 106) : CGSize(width: 88, height: 72),
                                showsRemoveOverlay: isExpanded,
                                previewPhoto: {
                                    previewPhoto(photo)
                                },
                                removePhoto: {
                                    removePhoto(photo)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleExpanded()
                }
            }

            if isExpanded {
                Text("Tap a photo to preview it. Long-press for more actions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .formRevealTransition()
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PhotoChecklistThumbnailView: View {
    let attachment: DocumentAttachmentFile
    let size: CGSize
    let showsRemoveOverlay: Bool
    let previewPhoto: () -> Void
    let removePhoto: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ChecklistThumbnailImage(path: attachment.filePath)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onTapGesture {
                    previewPhoto()
                }

            if showsRemoveOverlay {
                Button(role: .destructive, action: removePhoto) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.65))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
        .contextMenu {
            Button("Preview") {
                previewPhoto()
            }

            Button("Remove", role: .destructive) {
                removePhoto()
            }
        }
    }
}

private struct ChecklistThumbnailImage: View {
    let path: String

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)

            Image(systemName: "photo")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ChecklistPhotoPreviewSheet: View {
    let item: PhotoChecklistPreviewItem
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PhotoPreviewImage(path: item.attachment.filePath)
                        .frame(maxWidth: .infinity)

                    CardGroup(title: item.category.displayName) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(item.attachment.originalFilename)
                                .font(.body.weight(.medium))
                                .textSelection(.enabled)

                            Text("\(item.attachment.source.displayName) • \(item.attachment.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(LiquidGlassBackdrop())
            .navigationTitle("Checklist Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Remove", role: .destructive) {
                        onRemove()
                    }
                }
            }
        }
    }
}

struct StructuralSystemEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Structural System") {
                VStack(spacing: 12) {
                    FieldHeader("Structural System")
                    Picker("Structural System", selection: systemTypeBinding) {
                        Text("Not Set").tag(nil as StructuralSystemType?)
                        ForEach(StructuralSystemType.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    if showsSystemOtherField {
                        LabeledTextField("Other Structural System", text: systemTypeOtherBinding)
                            .formRevealTransition()
                    }
                }
            }

            if showsLegacyFlatSummary {
                CardGroup(title: "Legacy Structural Data") {
                    Text("This scope contains older flat structural fields from a previous build. Select a Structural System above to replace them with the new branching workflow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let legacySummary = scope.structuralSystem?.legacyFlatSummary {
                        Text(legacySummary)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if showsInsulatedAluminumPatioCoverFields {
                CardGroup(title: "Insulated Aluminum Patio Cover") {
                    VStack(spacing: 12) {
                        MeasurementTextField(title: "Width", text: patioCoverWidthBinding)

                        Text("Typically handled in 4-foot increments.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        MeasurementTextField(title: "Projection", text: patioCoverProjectionBinding)

                        Text("Typically handled in 2-foot increments.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LabeledTextField(
                            "Number of Posts",
                            text: patioCoverNumberOfPostsBinding,
                            helperText: "Client guidance: 20 feet or less usually uses 2 posts; 20+ feet typically uses 3 or more."
                        )

                        FieldHeader("Roof Type")
                        Picker("Roof Type", selection: patioCoverRoofTypeBinding) {
                            Text("Not Set").tag(nil as PatioCoverRoofType?)
                            ForEach(PatioCoverRoofType.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                .formRevealTransition()
            }

            if showsPergolaFields {
                CardGroup(title: "Pergola") {
                    VStack(spacing: 12) {
                        FieldHeader("Pergola Type")
                        Picker("Pergola Type", selection: pergolaTypeBinding) {
                            Text("Not Set").tag(nil as PergolaType?)
                            ForEach(PergolaType.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                .formRevealTransition()
            }

            if showsMotorizedPergolaFields {
                CardGroup(title: "Motorized Louvered Pergola") {
                    pergolaDimensionFields(
                        width: motorizedPergolaWidthBinding,
                        length: motorizedPergolaLengthBinding,
                        height: motorizedPergolaHeightBinding,
                        notes: motorizedPergolaNotesBinding
                    )
                }
                .formRevealTransition()
            }

            if showsManualPergolaFields {
                CardGroup(title: "Manually Retractable Louvered Pergola") {
                    pergolaDimensionFields(
                        width: manualPergolaWidthBinding,
                        length: manualPergolaLengthBinding,
                        height: manualPergolaHeightBinding,
                        notes: manualPergolaNotesBinding
                    )
                }
                .formRevealTransition()
            }

            if showsCedarPergolaFields {
                CardGroup(title: "Cedar Pergola") {
                    VStack(spacing: 12) {
                        FieldHeader("Post Size")
                        Picker("Post Size", selection: cedarPostSizeBinding) {
                            Text("Not Set").tag(nil as CedarPergolaPostSize?)
                            ForEach(CedarPergolaPostSize.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsCedarPostSizeOtherField {
                            LabeledTextField("Other Post Size", text: cedarPostSizeOtherBinding)
                                .formRevealTransition()
                        }

                        FieldHeader("Beam Size")
                        Picker("Beam Size", selection: cedarBeamSizeBinding) {
                            Text("Not Set").tag(nil as CedarPergolaBeamSize?)
                            ForEach(CedarPergolaBeamSize.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsCedarBeamSizeOtherField {
                            LabeledTextField("Other Beam Size", text: cedarBeamSizeOtherBinding)
                                .formRevealTransition()
                        }

                        FieldHeader("Rafter Size")
                        Picker("Rafter Size", selection: cedarRafterSizeBinding) {
                            Text("Not Set").tag(nil as CedarPergolaRafterSize?)
                            ForEach(CedarPergolaRafterSize.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsCedarRafterSizeOtherField {
                            LabeledTextField("Other Rafter Size", text: cedarRafterSizeOtherBinding)
                                .formRevealTransition()
                        }

                        FieldHeader("Lattice")
                        Picker("Lattice", selection: cedarLatticeBinding) {
                            Text("Not Set").tag(nil as CedarPergolaLattice?)
                            ForEach(CedarPergolaLattice.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Hardware")
                        Picker("Hardware", selection: cedarHardwareBinding) {
                            Text("Not Set").tag(nil as CedarPergolaHardware?)
                            ForEach(CedarPergolaHardware.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Finish")
                        Picker("Finish", selection: cedarFinishBinding) {
                            Text("Not Set").tag(nil as CedarPergolaFinish?)
                            ForEach(CedarPergolaFinish.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        LabeledTextField("Product Code", text: cedarProductCodeBinding)
                    }
                }
                .formRevealTransition()
            }

            if showsAlumawoodPergolaFields {
                CardGroup(title: "Alumawood Pergola") {
                    VStack(spacing: 12) {
                        FieldHeader("Mount Type")
                        Picker("Mount Type", selection: alumawoodMountTypeBinding) {
                            Text("Not Set").tag(nil as AlumawoodPergolaMountType?)
                            ForEach(AlumawoodPergolaMountType.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        MeasurementTextField(title: "Width", text: alumawoodWidthBinding)
                        MeasurementTextField(title: "Length", text: alumawoodLengthBinding)
                        MeasurementTextField(title: "Height", text: alumawoodHeightBinding)

                        FieldHeader("Attachment Type")
                        Picker("Attachment Type", selection: alumawoodAttachmentTypeBinding) {
                            Text("Not Set").tag(nil as AlumawoodPergolaAttachmentType?)
                            ForEach(AlumawoodPergolaAttachmentType.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Color")
                        Picker("Color", selection: alumawoodColorBinding) {
                            Text("Not Set").tag(nil as AlumawoodPergolaColor?)
                            ForEach(AlumawoodPergolaColor.allCases, id: \.self) { value in
                                Text(value.displayName).tag(Optional(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        OptionalBoolPicker(title: "Privacy Wall", selection: alumawoodPrivacyWallBinding)
                    }
                }
                .formRevealTransition()
            }

            MeasurementsBlockEditor(
                block: scope.structuralSystem?.measurements,
                preset: .structuralSystem,
                setBlock: updateMeasurements
            )

            CardGroup(title: "Structural Notes") {
                VStack(spacing: 12) {
                    NotesField(title: "Structural Notes", text: notesBinding, minHeight: 140, showInlineTitle: false)
                }
            }
        }
    }

    private var showsLegacyFlatSummary: Bool {
        scope.structuralSystem?.systemType == nil && scope.structuralSystem?.hasLegacyFlatValues == true
    }

    private var showsSystemOtherField: Bool {
        scope.structuralSystem?.systemType == .other
    }

    private var showsInsulatedAluminumPatioCoverFields: Bool {
        scope.structuralSystem?.systemType == .insulatedAluminumPatioCover
    }

    private var showsPergolaFields: Bool {
        scope.structuralSystem?.systemType == .pergola
    }

    private var showsMotorizedPergolaFields: Bool {
        scope.structuralSystem?.systemType == .pergola && scope.structuralSystem?.pergolaType == .motorizedLouveredPergola
    }

    private var showsManualPergolaFields: Bool {
        scope.structuralSystem?.systemType == .pergola && scope.structuralSystem?.pergolaType == .manuallyRetractableLouveredPergola
    }

    private var showsCedarPergolaFields: Bool {
        scope.structuralSystem?.systemType == .pergola && scope.structuralSystem?.pergolaType == .cedarPergola
    }

    private var showsAlumawoodPergolaFields: Bool {
        scope.structuralSystem?.systemType == .pergola && scope.structuralSystem?.pergolaType == .alumawoodPergola
    }

    private var showsCedarPostSizeOtherField: Bool {
        scope.structuralSystem?.cedarPergola?.postSize == .other
    }

    private var showsCedarBeamSizeOtherField: Bool {
        scope.structuralSystem?.cedarPergola?.beamSize == .other
    }

    private var showsCedarRafterSizeOtherField: Bool {
        scope.structuralSystem?.cedarPergola?.rafterSize == .other
    }

    private var systemTypeBinding: Binding<StructuralSystemType?> {
        Binding(
            get: { scope.structuralSystem?.systemType },
            set: { newValue in
                updateStructuralSystem { $0.systemType = newValue }
            }
        )
    }

    private var systemTypeOtherBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.systemTypeOther ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.systemTypeOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var patioCoverWidthBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.insulatedAluminumPatioCover?.width ?? "" },
            set: { newValue in
                updatePatioCover { $0.width = newValue.nilIfBlank }
            }
        )
    }

    private var patioCoverProjectionBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.insulatedAluminumPatioCover?.projection ?? "" },
            set: { newValue in
                updatePatioCover { $0.projection = newValue.nilIfBlank }
            }
        )
    }

    private var patioCoverNumberOfPostsBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.insulatedAluminumPatioCover?.numberOfPosts ?? "" },
            set: { newValue in
                updatePatioCover { $0.numberOfPosts = newValue.nilIfBlank }
            }
        )
    }

    private var patioCoverRoofTypeBinding: Binding<PatioCoverRoofType?> {
        Binding(
            get: { scope.structuralSystem?.insulatedAluminumPatioCover?.roofType },
            set: { newValue in
                updatePatioCover { $0.roofType = newValue }
            }
        )
    }

    private var pergolaTypeBinding: Binding<PergolaType?> {
        Binding(
            get: { scope.structuralSystem?.pergolaType },
            set: { newValue in
                updateStructuralSystem { $0.pergolaType = newValue }
            }
        )
    }

    private var motorizedPergolaWidthBinding: Binding<String> { pergolaDimensionBinding(\.motorizedLouveredPergola, \.width) }
    private var motorizedPergolaLengthBinding: Binding<String> { pergolaDimensionBinding(\.motorizedLouveredPergola, \.length) }
    private var motorizedPergolaHeightBinding: Binding<String> { pergolaDimensionBinding(\.motorizedLouveredPergola, \.height) }
    private var motorizedPergolaNotesBinding: Binding<String> {
        pergolaDimensionBinding(\.motorizedLouveredPergola, \.notes, preservesEditingWhitespace: true)
    }
    private var manualPergolaWidthBinding: Binding<String> { pergolaDimensionBinding(\.manuallyRetractableLouveredPergola, \.width) }
    private var manualPergolaLengthBinding: Binding<String> { pergolaDimensionBinding(\.manuallyRetractableLouveredPergola, \.length) }
    private var manualPergolaHeightBinding: Binding<String> { pergolaDimensionBinding(\.manuallyRetractableLouveredPergola, \.height) }
    private var manualPergolaNotesBinding: Binding<String> {
        pergolaDimensionBinding(\.manuallyRetractableLouveredPergola, \.notes, preservesEditingWhitespace: true)
    }

    private var cedarPostSizeBinding: Binding<CedarPergolaPostSize?> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.postSize },
            set: { newValue in
                updateCedarPergola { $0.postSize = newValue }
            }
        )
    }

    private var cedarPostSizeOtherBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.postSizeOther ?? "" },
            set: { newValue in
                updateCedarPergola { $0.postSizeOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var cedarBeamSizeBinding: Binding<CedarPergolaBeamSize?> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.beamSize },
            set: { newValue in
                updateCedarPergola { $0.beamSize = newValue }
            }
        )
    }

    private var cedarBeamSizeOtherBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.beamSizeOther ?? "" },
            set: { newValue in
                updateCedarPergola { $0.beamSizeOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var cedarRafterSizeBinding: Binding<CedarPergolaRafterSize?> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.rafterSize },
            set: { newValue in
                updateCedarPergola { $0.rafterSize = newValue }
            }
        )
    }

    private var cedarRafterSizeOtherBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.rafterSizeOther ?? "" },
            set: { newValue in
                updateCedarPergola { $0.rafterSizeOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var cedarLatticeBinding: Binding<CedarPergolaLattice?> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.lattice },
            set: { newValue in
                updateCedarPergola { $0.lattice = newValue }
            }
        )
    }

    private var cedarHardwareBinding: Binding<CedarPergolaHardware?> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.hardware },
            set: { newValue in
                updateCedarPergola { $0.hardware = newValue }
            }
        )
    }

    private var cedarFinishBinding: Binding<CedarPergolaFinish?> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.finish },
            set: { newValue in
                updateCedarPergola { $0.finish = newValue }
            }
        )
    }

    private var cedarProductCodeBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.cedarPergola?.productCode ?? "" },
            set: { newValue in
                updateCedarPergola { $0.productCode = newValue.nilIfBlank }
            }
        )
    }

    private var alumawoodMountTypeBinding: Binding<AlumawoodPergolaMountType?> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.mountType },
            set: { newValue in
                updateAlumawoodPergola { $0.mountType = newValue }
            }
        )
    }

    private var alumawoodWidthBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.width ?? "" },
            set: { newValue in
                updateAlumawoodPergola { $0.width = newValue.nilIfBlank }
            }
        )
    }

    private var alumawoodLengthBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.length ?? "" },
            set: { newValue in
                updateAlumawoodPergola { $0.length = newValue.nilIfBlank }
            }
        )
    }

    private var alumawoodHeightBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.height ?? "" },
            set: { newValue in
                updateAlumawoodPergola { $0.height = newValue.nilIfBlank }
            }
        )
    }

    private var alumawoodAttachmentTypeBinding: Binding<AlumawoodPergolaAttachmentType?> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.attachmentType },
            set: { newValue in
                updateAlumawoodPergola { $0.attachmentType = newValue }
            }
        )
    }

    private var alumawoodColorBinding: Binding<AlumawoodPergolaColor?> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.color },
            set: { newValue in
                updateAlumawoodPergola { $0.color = newValue }
            }
        )
    }

    private var alumawoodPrivacyWallBinding: Binding<Bool?> {
        Binding(
            get: { scope.structuralSystem?.alumawoodPergola?.privacyWall },
            set: { newValue in
                updateAlumawoodPergola { $0.privacyWall = newValue }
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.notes ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.notes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func updateStructuralSystem(_ update: (inout StructuralSystem) -> Void) {
        var structuralSystem = scope.structuralSystem ?? emptyStructuralSystem()
        update(&structuralSystem)
        scope.structuralSystem = structuralSystem.isEffectivelyEmpty ? nil : structuralSystem
        autosave.scheduleSave(for: scope)
    }

    private func updateMeasurements(_ block: MeasurementsBlock?) {
        updateStructuralSystem { $0.measurements = block }
    }

    private func updatePatioCover(_ update: (inout InsulatedAluminumPatioCoverDetails) -> Void) {
        updateStructuralSystem { structuralSystem in
            var details = structuralSystem.insulatedAluminumPatioCover ?? emptyInsulatedAluminumPatioCoverDetails()
            update(&details)
            structuralSystem.insulatedAluminumPatioCover = details.isEffectivelyEmpty ? nil : details
        }
    }

    private func updateCedarPergola(_ update: (inout CedarPergolaDetails) -> Void) {
        updateStructuralSystem { structuralSystem in
            var details = structuralSystem.cedarPergola ?? emptyCedarPergolaDetails()
            update(&details)
            structuralSystem.cedarPergola = details.isEffectivelyEmpty ? nil : details
        }
    }

    private func updateAlumawoodPergola(_ update: (inout AlumawoodPergolaDetails) -> Void) {
        updateStructuralSystem { structuralSystem in
            var details = structuralSystem.alumawoodPergola ?? emptyAlumawoodPergolaDetails()
            update(&details)
            structuralSystem.alumawoodPergola = details.isEffectivelyEmpty ? nil : details
        }
    }

    private func pergolaDimensionBinding(
        _ keyPath: WritableKeyPath<StructuralSystem, PergolaDimensionDetails?>,
        _ field: WritableKeyPath<PergolaDimensionDetails, String?>,
        preservesEditingWhitespace: Bool = false
    ) -> Binding<String> {
        Binding(
            get: { scope.structuralSystem?[keyPath: keyPath]?[keyPath: field] ?? "" },
            set: { newValue in
                updateStructuralSystem { structuralSystem in
                    var details = structuralSystem[keyPath: keyPath] ?? emptyPergolaDimensionDetails()
                    details[keyPath: field] = preservesEditingWhitespace ? newValue.nilIfWhitespaceOnly : newValue.nilIfBlank
                    structuralSystem[keyPath: keyPath] = details.isEffectivelyEmpty ? nil : details
                }
            }
        )
    }

    @ViewBuilder
    private func pergolaDimensionFields(
        width: Binding<String>,
        length: Binding<String>,
        height: Binding<String>,
        notes: Binding<String>
    ) -> some View {
        VStack(spacing: 12) {
            MeasurementTextField(title: "Width", text: width)
            MeasurementTextField(title: "Length", text: length)
            MeasurementTextField(title: "Height", text: height)
            NotesField(title: "Notes", text: notes, minHeight: 110)
        }
    }
}

struct EnclosureEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Screen Enclosure Type") {
                VStack(alignment: .leading, spacing: 10) {
                    FieldHeader("Types")

                    Text(enclosureTypeSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(EnclosureType.selectableCases, id: \.self) { type in
                        Button {
                            toggleEnclosureType(type)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isEnclosureTypeSelected(type) ? "checkmark.circle.fill" : "circle")
                                    .imageScale(.large)
                                    .foregroundStyle(isEnclosureTypeSelected(type) ? Color.accentColor : Color.secondary)

                                Text(type.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(type.displayName)
                        .accessibilityValue(isEnclosureTypeSelected(type) ? "Selected" : "Not selected")
                        .accessibilityAddTraits(isEnclosureTypeSelected(type) ? .isSelected : [])
                    }
                }
            }

            CardGroup(title: "Screen Enclosure Notes") {
                NotesField(
                    title: "Screen Enclosure Notes",
                    text: screenEnclosureNotesBinding,
                    minHeight: 120,
                    showInlineTitle: false,
                    prompt: "Add notes specific to screen enclosure"
                )
            }

            MeasurementsBlockEditor(
                block: scope.enclosure?.screenMeasurements,
                preset: .screenEnclosure,
                setBlock: updateScreenMeasurements
            )

            if showsScreenOptions {
                CardGroup(title: "Screen Options") {
                    VStack(spacing: 12) {
                        FieldHeader("Screen Type")
                        Picker("Screen Type", selection: screenWallTypeBinding) {
                            Text("Not Set").tag(nil as ScreenWallType?)
                            ForEach(ScreenWallType.allCases, id: \.self) { option in
                                Text(option.displayName).tag(Optional(option))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsScreenTintField {
                            FieldHeader("Tint")
                            Picker("Tint", selection: screenTintBinding) {
                                Text("Not Set").tag(nil as ScreenTintOption?)
                                ForEach(ScreenTintOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(Optional(option))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .formRevealTransition()
                        }

                        FieldHeader("Frame Size")
                        Picker("Frame Size", selection: screenFrameSizeBinding) {
                            Text("Not Set").tag(nil as ScreenFrameSizeOption?)
                            ForEach(ScreenFrameSizeOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(Optional(option))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Screen Frame Color")
                        Picker("Screen Frame Color", selection: screenFrameColorBinding) {
                            Text("Not Set").tag(nil as EnclosureScreenFrameColorOption?)
                            ForEach(screenFrameColorOptions, id: \.self) { color in
                                Text(color.displayName).tag(Optional(color))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsCustomScreenFrameColorField {
                            LabeledTextField("Screen Frame Color", text: screenFrameColorCustomBinding, prompt: "Custom or other screen frame color")
                                .formRevealTransition()
                        }
                    }
                }
                .formRevealTransition()
            }

            CardGroup(title: "Knee Wall + Doors") {
                VStack(spacing: 12) {
                    Toggle("Configure Knee Wall", isOn: includeKneeWallBinding)
                        .frame(minHeight: 44)

                    if scope.enclosure?.kneeWall != nil {
                        Picker("Knee Wall Option", selection: kneeWallOptionBinding) {
                            ForEach(KneeWallOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()

                        if scope.enclosure?.kneeWall?.option != KneeWallOption.none {
                            if showsPanelStyleKneeWallFields {
                                if showsPanelHeightOptions {
                                    FieldHeader("Panel Height")
                                    Picker("Panel Height", selection: kneeWallPanelHeightBinding) {
                                        Text("Not Set").tag(nil as KneeWallPanelHeightOption?)
                                        ForEach(KneeWallPanelHeightOption.allCases, id: \.self) { option in
                                            Text(option.displayName).tag(Optional(option))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .formRevealTransition()
                                }

                                LabeledTextField("Panel Color", text: kneeWallPanelColorBinding, prompt: "Panel color")
                                    .formRevealTransition()

                                LabeledTextField("Linear Footage", text: kneeWallLinearFootageBinding, prompt: "Linear footage")
                                    .formRevealTransition()
                            }

                            if showsFramedKneeWallFields {
                                LabeledTextField("Knee Wall Height", text: kneeWallHeightBinding, prompt: "Height")
                                    .formRevealTransition()

                                FieldHeader("Interior Finish/Color")
                                Picker("Interior Finish/Color", selection: kneeWallInteriorFinishColorBinding) {
                                    Text("Not Set").tag(nil as ScreenFrameColorOption?)
                                    ForEach(ScreenFrameColorOption.allCases, id: \.self) { color in
                                        Text(color.displayName).tag(Optional(color))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .formRevealTransition()

                                FieldHeader("Exterior Finish/Color")
                                Picker("Exterior Finish/Color", selection: kneeWallExteriorFinishColorBinding) {
                                    Text("Not Set").tag(nil as ScreenFrameColorOption?)
                                    ForEach(ScreenFrameColorOption.allCases, id: \.self) { color in
                                        Text(color.displayName).tag(Optional(color))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .formRevealTransition()

                                FieldHeader("Framing")
                                Picker("Framing", selection: kneeWallFramingBinding) {
                                    Text("Not Set").tag(nil as KneeWallFramingOption?)
                                    ForEach(KneeWallFramingOption.allCases, id: \.self) { option in
                                        Text(option.displayName).tag(Optional(option))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .formRevealTransition()
                            }
                        }
                    }

                    Divider()

                    Toggle("Configure Door Options", isOn: includeDoorsBinding)
                        .frame(minHeight: 44)

                    if scope.enclosure?.doors != nil {
                        Picker("Door Type", selection: doorTypeBinding) {
                            ForEach(DoorType.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()

                        if showsHingedScreenStyleOptions {
                            FieldHeader("Style")
                            Picker("Style", selection: doorStyleBinding) {
                                Text("Not Set").tag(nil as DoorStyleOption?)
                                ForEach(DoorStyleOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(Optional(option))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .formRevealTransition()
                        }

                        if showsOperableSideOptions {
                            FieldHeader("Operable Side")
                            Picker("Operable Side", selection: doorOperableSideBinding) {
                                Text("Not Set").tag(nil as DoorOperableSideOption?)
                                ForEach(DoorOperableSideOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(Optional(option))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .formRevealTransition()
                        }

                        if showsDoorHingeSideOptions {
                            FieldHeader("Hinge Side")
                            Picker("Hinge Side", selection: doorHingeSideBinding) {
                                Text("Not Set").tag(nil as DoorHingeSideOption?)
                                ForEach(DoorHingeSideOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(Optional(option))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .formRevealTransition()
                        }

                        if showsCabanaDimensions {
                            LabeledTextField("Door Width", text: doorWidthBinding, prompt: "Width")
                                .formRevealTransition()

                            LabeledTextField("Door Height", text: doorHeightBinding, prompt: "Height")
                                .formRevealTransition()
                        }

                        if showsSlidingGlassFields {
                            FieldHeader("Pull Side")
                            Picker("Pull Side", selection: doorOperableSideBinding) {
                                Text("Not Set").tag(nil as DoorOperableSideOption?)
                                ForEach(DoorOperableSideOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(Optional(option))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .formRevealTransition()

                            LabeledTextField("Door Color", text: doorColorBinding, prompt: "Color")
                                .formRevealTransition()

                            LabeledTextField("Door Dimensions", text: doorDimensionsBinding, prompt: "Dimensions")
                                .formRevealTransition()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Door Notes")
                                .font(.body)
                            TextEditor(text: doorNotesBinding)
                                .frame(minHeight: 100)
                                .padding(8)
                                .liquidGlassInputBackground(cornerRadius: 14)
                        }
                        .formRevealTransition()
                    }
                }
            }
        }
        .animation(.formReveal, value: showsScreenOptions)
        .animation(.formReveal, value: showsCustomScreenFrameColorField)
        .animation(.formReveal, value: scope.enclosure?.kneeWall != nil)
        .animation(.formReveal, value: scope.enclosure?.kneeWall?.option != KneeWallOption.none)
        .animation(.formReveal, value: scope.enclosure?.doors != nil)
        .animation(.formReveal, value: showsHingedScreenStyleOptions)
        .animation(.formReveal, value: showsOperableSideOptions)
        .animation(.formReveal, value: showsDoorHingeSideOptions)
        .animation(.formReveal, value: showsCabanaDimensions)
        .animation(.formReveal, value: showsSlidingGlassFields)
        .animation(.formReveal, value: showsScreenTintField)
    }

    private var showsScreenOptions: Bool {
        scope.enclosure?.hasScreenEnclosureSelection == true
    }

    private var enclosureTypeSummary: String {
        scope.enclosure?.enclosureTypeDisplaySummary ?? "No enclosure types selected"
    }

    private var showsCustomScreenFrameColorField: Bool {
        switch scope.enclosure?.screenFrameColor {
        case .legacyOther:
            return true
        default:
            return false
        }
    }

    private var showsScreenTintField: Bool {
        scope.enclosure?.screenWallType == .suntexSolarScreen
    }

    private func isEnclosureTypeSelected(_ type: EnclosureType) -> Bool {
        scope.enclosure?.activeEnclosureTypes.contains(type) == true
    }

    private func toggleEnclosureType(_ type: EnclosureType) {
        updateEnclosure { enclosure in
            enclosure.setEnclosureType(type, isSelected: !enclosure.activeEnclosureTypes.contains(type))
        }
    }

    private var screenWallTypeBinding: Binding<ScreenWallType?> {
        Binding(
            get: { scope.enclosure?.screenWallType },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.screenWallType = newValue
                    if newValue != .suntexSolarScreen {
                        enclosure.screenTint = nil
                    }
                }
            }
        )
    }

    private var screenTintBinding: Binding<ScreenTintOption?> {
        Binding(
            get: { scope.enclosure?.screenTint },
            set: { newValue in
                updateEnclosure { $0.screenTint = newValue }
            }
        )
    }

    private var screenFrameSizeBinding: Binding<ScreenFrameSizeOption?> {
        Binding(
            get: { scope.enclosure?.screenFrameSize },
            set: { newValue in
                updateEnclosure { $0.screenFrameSize = newValue }
            }
        )
    }

    private var screenFrameColorOptions: [EnclosureScreenFrameColorOption] {
        var options = EnclosureScreenFrameColorOption.allCases
        if let current = scope.enclosure?.screenFrameColor,
           !options.contains(current) {
            options.append(current)
        }
        return options
    }

    private var screenFrameColorBinding: Binding<EnclosureScreenFrameColorOption?> {
        Binding(
            get: { scope.enclosure?.screenFrameColor },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.screenFrameColor = newValue
                    if newValue != .legacyOther {
                        enclosure.screenFrameColorCustom = nil
                    }
                }
            }
        )
    }

    private var screenFrameColorCustomBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.screenFrameColorCustom ?? "" },
            set: { newValue in
                updateEnclosure { $0.screenFrameColorCustom = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var screenEnclosureNotesBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.screenEnclosureNotes ?? "" },
            set: { newValue in
                updateEnclosure { $0.screenEnclosureNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var includeKneeWallBinding: Binding<Bool> {
        Binding(
            get: { scope.enclosure?.kneeWall != nil },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.kneeWall = newValue ? (enclosure.kneeWall ?? emptyKneeWall()) : nil
                }
            }
        )
    }

    private var kneeWallOptionBinding: Binding<KneeWallOption> {
        Binding(
            get: { scope.enclosure?.kneeWall?.option ?? .none },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.option = newValue
                    if newValue == .none {
                        kneeWall.panelHeight = nil
                        kneeWall.panelColor = nil
                        kneeWall.linearFootage = nil
                        kneeWall.height = nil
                        kneeWall.interiorFinishColor = nil
                        kneeWall.exteriorFinishColor = nil
                        kneeWall.framing = nil
                    }

                    if !showsPanelStyleFields(for: newValue) {
                        kneeWall.panelHeight = nil
                        kneeWall.panelColor = nil
                        kneeWall.linearFootage = nil
                    }

                    if !showsFramedFields(for: newValue) {
                        kneeWall.height = nil
                        kneeWall.interiorFinishColor = nil
                        kneeWall.exteriorFinishColor = nil
                        kneeWall.framing = nil
                    }
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var showsPanelStyleKneeWallFields: Bool {
        showsPanelStyleFields(for: scope.enclosure?.kneeWall?.option)
    }

    private var showsPanelHeightOptions: Bool {
        supportsPanelHeight(scope.enclosure?.kneeWall?.option)
    }

    private var showsFramedKneeWallFields: Bool {
        showsFramedFields(for: scope.enclosure?.kneeWall?.option)
    }

    private var kneeWallPanelHeightBinding: Binding<KneeWallPanelHeightOption?> {
        Binding(
            get: { scope.enclosure?.kneeWall?.panelHeight },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.panelHeight = newValue
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallPanelColorBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.kneeWall?.panelColor ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.panelColor = newValue.nilIfWhitespaceOnly
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallLinearFootageBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.kneeWall?.linearFootage ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.linearFootage = newValue.nilIfBlank
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallHeightBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.kneeWall?.height ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.height = newValue.nilIfBlank
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallInteriorFinishColorBinding: Binding<ScreenFrameColorOption?> {
        Binding(
            get: { scope.enclosure?.kneeWall?.interiorFinishColor },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.interiorFinishColor = newValue
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallExteriorFinishColorBinding: Binding<ScreenFrameColorOption?> {
        Binding(
            get: { scope.enclosure?.kneeWall?.exteriorFinishColor },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.exteriorFinishColor = newValue
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallFramingBinding: Binding<KneeWallFramingOption?> {
        Binding(
            get: { scope.enclosure?.kneeWall?.framing },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.framing = newValue
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var includeDoorsBinding: Binding<Bool> {
        Binding(
            get: { scope.enclosure?.doors != nil },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.doors = newValue ? (enclosure.doors ?? emptyDoorOptions()) : nil
                }
            }
        )
    }

    private var doorTypeBinding: Binding<DoorType> {
        Binding(
            get: { scope.enclosure?.doors?.doorType ?? .none },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.doorType = newValue
                    if newValue != .hingedScreen {
                        doors.style = nil
                    }
                    if newValue != .hingedScreen, newValue != .slidingGlass {
                        doors.operableSide = nil
                    }
                    if newValue != .hingedScreen, newValue != .pgtCabanaDoor {
                        doors.hingeSide = nil
                    }
                    if newValue != .pgtCabanaDoor {
                        doors.width = nil
                        doors.height = nil
                    }
                    if newValue != .slidingGlass {
                        doors.color = nil
                        doors.dimensions = nil
                    }
                    enclosure.doors = doors
                }
            }
        )
    }

    private var showsHingedScreenStyleOptions: Bool {
        scope.enclosure?.doors?.doorType == .hingedScreen
    }

    private var showsOperableSideOptions: Bool {
        scope.enclosure?.doors?.doorType == .hingedScreen &&
        scope.enclosure?.doors?.style == .french
    }

    private var showsDoorHingeSideOptions: Bool {
        switch scope.enclosure?.doors?.doorType {
        case .hingedScreen:
            return scope.enclosure?.doors?.style == .single
        case .pgtCabanaDoor:
            return true
        default:
            return false
        }
    }

    private var showsCabanaDimensions: Bool {
        scope.enclosure?.doors?.doorType == .pgtCabanaDoor
    }

    private var showsSlidingGlassFields: Bool {
        scope.enclosure?.doors?.doorType == .slidingGlass
    }

    private var doorStyleBinding: Binding<DoorStyleOption?> {
        Binding(
            get: { scope.enclosure?.doors?.style },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.style = newValue
                    if newValue != .french {
                        doors.operableSide = nil
                    }
                    if newValue != .single, doors.doorType == .hingedScreen {
                        doors.hingeSide = nil
                    }
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorOperableSideBinding: Binding<DoorOperableSideOption?> {
        Binding(
            get: { scope.enclosure?.doors?.operableSide },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.operableSide = newValue
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorHingeSideBinding: Binding<DoorHingeSideOption?> {
        Binding(
            get: { scope.enclosure?.doors?.hingeSide },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.hingeSide = newValue
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorWidthBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.doors?.width ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.width = newValue.nilIfBlank
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorHeightBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.doors?.height ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.height = newValue.nilIfBlank
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorColorBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.doors?.color ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.color = newValue.nilIfWhitespaceOnly
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorDimensionsBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.doors?.dimensions ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.dimensions = newValue.nilIfWhitespaceOnly
                    enclosure.doors = doors
                }
            }
        )
    }

    private var doorNotesBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.doors?.notes ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var doors = enclosure.doors ?? emptyDoorOptions()
                    doors.notes = newValue.nilIfWhitespaceOnly
                    enclosure.doors = doors
                }
            }
        )
    }

    private func updateEnclosure(_ update: (inout Enclosure) -> Void) {
        var enclosure = scope.enclosure ?? emptyEnclosure()
        update(&enclosure)
        scope.enclosure = enclosure.isEffectivelyEmpty ? nil : enclosure
        autosave.scheduleSave(for: scope)
    }

    private func updateScreenMeasurements(_ block: MeasurementsBlock?) {
        updateEnclosure { $0.screenMeasurements = block }
    }

    private func supportsPanelHeight(_ option: KneeWallOption?) -> Bool {
        switch option {
        case .aluminumKickplate, .insulatedAluminumPanel:
            return true
        default:
            return false
        }
    }

    private func showsPanelStyleFields(for option: KneeWallOption?) -> Bool {
        switch option {
        case .aluminumKickplate, .insulatedAluminumPanel:
            return true
        default:
            return false
        }
    }

    private func showsFramedFields(for option: KneeWallOption?) -> Bool {
        option == .framedKneeWall
    }
}

struct WindowsAndGlassEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave
    @State private var isWindowSystemEnabled = false

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Window System") {
                VStack(spacing: 12) {
                    Toggle("Configure Window System", isOn: includeWindowSystemBinding)
                        .frame(minHeight: 44)

                    if isWindowSystemEnabled {
                        FieldHeader("Window Type")
                        Picker("Window Type", selection: windowTypeBinding) {
                            Text("Not Set").tag(nil as WindowType?)
                            ForEach(WindowType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(Optional(type))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()

                        FieldHeader("Frame System")
                        Picker("Frame System", selection: frameSystemBinding) {
                            Text("Not Set").tag(nil as WindowFrameSystem?)
                            ForEach(WindowFrameSystem.allCases, id: \.self) { frame in
                                Text(frame.displayName).tag(Optional(frame))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()
                    }
                }
            }

            MeasurementsBlockEditor(
                block: scope.enclosure?.sunroomMeasurements,
                preset: .sunroom,
                setBlock: updateSunroomMeasurements
            )

            if isWindowSystemEnabled {
                CardGroup(title: "Glass") {
                    VStack(spacing: 12) {
                        FieldHeader("Glass Type")
                        Picker("Glass Type", selection: glassTypeBinding) {
                            Text("Not Set").tag(nil as GlassType?)
                            ForEach(GlassType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(Optional(type))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Glass Safety")
                        Picker("Glass Safety", selection: glassSafetyBinding) {
                            Text("Not Set").tag(nil as GlassSafety?)
                            ForEach(GlassSafety.allCases, id: \.self) { safety in
                                Text(safety.displayName).tag(Optional(safety))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Grid Option")
                        Picker("Grid Option", selection: gridOptionBinding) {
                            Text("Not Set").tag(nil as GridOption?)
                            ForEach(GridOption.allCases, id: \.self) { grid in
                                Text(grid.displayName).tag(Optional(grid))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                .formRevealTransition()

                CardGroup(title: "Frame + Layout") {
                    VStack(spacing: 12) {
                        FieldHeader("Operation")
                        Picker("Operation", selection: operationBinding) {
                            Text("Not Set").tag(nil as WindowOperation?)
                            ForEach(WindowOperation.allCases, id: \.self) { operation in
                                Text(operation.displayName).tag(Optional(operation))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Frame Color")
                        Picker("Frame Color", selection: frameColorBinding) {
                            Text("Not Set").tag(nil as StandardColorOption?)
                            ForEach(StandardColorOption.allCases, id: \.self) { color in
                                Text(color.displayName).tag(Optional(color))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsCustomWindowFrameColorField {
                            LabeledTextField("Frame Color", text: frameColorCustomBinding, prompt: "Custom or other frame color")
                                .formRevealTransition()
                        }

                        LabeledTextField("Window Height", text: windowHeightBinding)
                            .keyboardType(.decimalPad)
                            .frame(minHeight: 44)

                        LabeledTextField("Number of Bays", text: numBaysBinding)
                            .keyboardType(.decimalPad)
                            .frame(minHeight: 44)

                        FieldHeader("Configuration")
                        Picker("Configuration", selection: configurationBinding) {
                            Text("Not Set").tag(nil as WindowConfiguration?)
                            ForEach(WindowConfiguration.allCases, id: \.self) { config in
                                Text(config.displayName).tag(Optional(config))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                .formRevealTransition()

                CardGroup(title: "Window Notes") {
                    NotesField(title: "Window Notes", text: notesBinding, minHeight: 140, showInlineTitle: false)
                }
                .formRevealTransition()
            }
        }
        .onAppear {
            isWindowSystemEnabled = scope.enclosure?.windowSystem != nil
        }
        .animation(.formReveal, value: isWindowSystemEnabled)
        .animation(.formReveal, value: showsCustomWindowFrameColorField)
    }

    private var includeWindowSystemBinding: Binding<Bool> {
        Binding(
            get: { isWindowSystemEnabled },
            set: { newValue in
                isWindowSystemEnabled = newValue
                guard !newValue else { return }
                updateEnclosure { enclosure in
                    enclosure.windowSystem = nil
                }
            }
        )
    }

    private var windowTypeBinding: Binding<WindowType?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.windowType },
            set: { newValue in
                updateWindowSystem { $0.windowType = newValue }
            }
        )
    }

    private var frameSystemBinding: Binding<WindowFrameSystem?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.frameSystem },
            set: { newValue in
                updateWindowSystem { $0.frameSystem = newValue }
            }
        )
    }

    private var glassTypeBinding: Binding<GlassType?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.glassType },
            set: { newValue in
                updateWindowSystem { $0.glassType = newValue }
            }
        )
    }

    private var glassSafetyBinding: Binding<GlassSafety?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.glassSafety },
            set: { newValue in
                updateWindowSystem { $0.glassSafety = newValue }
            }
        )
    }

    private var gridOptionBinding: Binding<GridOption?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.gridOption },
            set: { newValue in
                updateWindowSystem { $0.gridOption = newValue }
            }
        )
    }

    private var operationBinding: Binding<WindowOperation?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.operation },
            set: { newValue in
                updateWindowSystem { $0.operation = newValue }
            }
        )
    }

    private var frameColorBinding: Binding<StandardColorOption?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.color },
            set: { newValue in
                updateWindowSystem { windowSystem in
                    windowSystem.color = newValue
                    if newValue != .custom, newValue != .other {
                        windowSystem.colorCustom = nil
                    }
                }
            }
        )
    }

    private var showsCustomWindowFrameColorField: Bool {
        switch scope.enclosure?.windowSystem?.color {
        case .custom, .other:
            return true
        default:
            return false
        }
    }

    private var frameColorCustomBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.windowSystem?.colorCustom ?? "" },
            set: { newValue in
                updateWindowSystem { $0.colorCustom = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var windowHeightBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.enclosure?.windowSystem?.windowHeight) },
            set: { newValue in
                updateWindowSystem { $0.windowHeight = parseOptionalDouble(newValue) }
            }
        )
    }

    private var numBaysBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.enclosure?.windowSystem?.numBays) },
            set: { newValue in
                updateWindowSystem { $0.numBays = parseOptionalDouble(newValue) }
            }
        )
    }

    private var configurationBinding: Binding<WindowConfiguration?> {
        Binding(
            get: { scope.enclosure?.windowSystem?.configuration },
            set: { newValue in
                updateWindowSystem { $0.configuration = newValue }
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.windowSystem?.notes ?? "" },
            set: { newValue in
                updateWindowSystem { $0.notes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func updateEnclosure(_ update: (inout Enclosure) -> Void) {
        var enclosure = scope.enclosure ?? emptyEnclosure()
        update(&enclosure)
        scope.enclosure = enclosure.isEffectivelyEmpty ? nil : enclosure
        autosave.scheduleSave(for: scope)
    }

    private func updateSunroomMeasurements(_ block: MeasurementsBlock?) {
        updateEnclosure { $0.sunroomMeasurements = block }
    }

    private func updateWindowSystem(_ update: (inout WindowSystem) -> Void) {
        updateEnclosure { enclosure in
            var windowSystem = enclosure.windowSystem ?? emptyWindowSystem()
            update(&windowSystem)
            enclosure.windowSystem = windowSystem.isEffectivelyEmpty ? nil : windowSystem
        }
    }
}

struct ElectricalEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Power Plan") {
                VStack(spacing: 12) {
                    MeasurementTextField(title: "Outlet Count", text: outletCountBinding)

                    FieldHeader("Lighting")
                    Picker("Lighting", selection: lightingBinding) {
                        Text("Not Set").tag(nil as LightingOption?)
                        ForEach(LightingOption.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    OptionalBoolPicker(title: "Fan Install", selection: fanInstallBinding)

                    LabeledTextField("Switch Locations", text: switchLocationsBinding, prompt: "Switch locations")
                }
            }

            CardGroup(title: "Dedicated Circuits") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select all that apply.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(DedicatedCircuitType.allCases, id: \.self) { circuit in
                        Toggle(circuit.displayName, isOn: dedicatedCircuitBinding(for: circuit))
                            .frame(minHeight: 44)
                    }
                }
            }

            MeasurementsBlockEditor(
                block: scope.electrical?.measurements,
                preset: .electrical,
                setBlock: updateMeasurements
            )

            CardGroup(title: "Electrical Notes") {
                NotesField(title: "Electrical Notes", text: notesBinding, minHeight: 140, showInlineTitle: false)
            }
        }
    }

    private var outletCountBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.electrical?.outletCount) },
            set: { newValue in
                updateElectrical { $0.outletCount = parseOptionalDouble(newValue) }
            }
        )
    }

    private var lightingBinding: Binding<LightingOption?> {
        Binding(
            get: { scope.electrical?.lighting },
            set: { newValue in
                updateElectrical { $0.lighting = newValue }
            }
        )
    }

    private var fanInstallBinding: Binding<Bool?> {
        Binding(
            get: { scope.electrical?.fanInstall },
            set: { newValue in
                updateElectrical { $0.fanInstall = newValue }
            }
        )
    }

    private var switchLocationsBinding: Binding<String> {
        Binding(
            get: { scope.electrical?.switchLocations ?? "" },
            set: { newValue in
                updateElectrical { $0.switchLocations = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.electrical?.notes ?? "" },
            set: { newValue in
                updateElectrical { $0.notes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func dedicatedCircuitBinding(for circuit: DedicatedCircuitType) -> Binding<Bool> {
        Binding(
            get: { scope.electrical?.dedicatedCircuits?.contains(circuit) ?? false },
            set: { isEnabled in
                updateElectrical { electrical in
                    var values = electrical.dedicatedCircuits ?? []
                    if isEnabled {
                        if !values.contains(circuit) {
                            values.append(circuit)
                        }
                    } else {
                        values.removeAll { $0 == circuit }
                    }
                    electrical.dedicatedCircuits = values.isEmpty ? nil : values
                }
            }
        )
    }

    private func updateElectrical(_ update: (inout Electrical) -> Void) {
        var electrical = scope.electrical ?? emptyElectrical()
        update(&electrical)
        scope.electrical = electrical.isEffectivelyEmpty ? nil : electrical
        autosave.scheduleSave(for: scope)
    }

    private func updateMeasurements(_ block: MeasurementsBlock?) {
        updateElectrical { $0.measurements = block }
    }
}

struct DrainageEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Drainage Setup") {
                VStack(spacing: 12) {
                    OptionalBoolPicker(title: "Include Gutters", selection: guttersBinding)

                    LabeledTextField("Downspout Locations", text: downspoutLocationsBinding, prompt: "Downspout locations")

                    OptionalBoolPicker(title: "Drain Tie-In", selection: drainTieInBinding)
                }
            }

            CardGroup(title: "Slope Notes") {
                NotesField(title: "Slope Notes", text: slopeNotesBinding, minHeight: 140, showInlineTitle: false)
            }

            MeasurementsBlockEditor(
                block: scope.drainage?.measurements,
                preset: .drainage,
                setBlock: updateMeasurements
            )
        }
    }

    private var guttersBinding: Binding<Bool?> {
        Binding(
            get: { scope.drainage?.gutters },
            set: { newValue in
                updateDrainage { $0.gutters = newValue }
            }
        )
    }

    private var downspoutLocationsBinding: Binding<String> {
        Binding(
            get: { scope.drainage?.downspoutLocations ?? "" },
            set: { newValue in
                updateDrainage { $0.downspoutLocations = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var drainTieInBinding: Binding<Bool?> {
        Binding(
            get: { scope.drainage?.drainTieIn },
            set: { newValue in
                updateDrainage { $0.drainTieIn = newValue }
            }
        )
    }

    private var slopeNotesBinding: Binding<String> {
        Binding(
            get: { scope.drainage?.slopeNotes ?? "" },
            set: { newValue in
                updateDrainage { $0.slopeNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func updateDrainage(_ update: (inout Drainage) -> Void) {
        var drainage = scope.drainage ?? emptyDrainage()
        update(&drainage)
        scope.drainage = drainage.isEffectivelyEmpty ? nil : drainage
        autosave.scheduleSave(for: scope)
    }

    private func updateMeasurements(_ block: MeasurementsBlock?) {
        updateDrainage { $0.measurements = block }
    }
}

struct AttachmentConditionsEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "House Attachment") {
                VStack(spacing: 12) {
                    FieldHeader("House Wall Material")
                    Picker("House Wall Material", selection: houseWallMaterialBinding) {
                        Text("Not Set").tag(nil as HouseWallMaterial?)
                        ForEach(HouseWallMaterial.allCases, id: \.self) { material in
                            Text(material.displayName).tag(Optional(material))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    if scope.attachment?.houseWallMaterial == .other {
                        LabeledTextField("Wall Material", text: houseWallOtherBinding, prompt: "Describe wall material")
                            .formRevealTransition()
                    }

                    FieldHeader("House Mounting Type")
                    Picker("House Mounting Type", selection: houseMountingTypeBinding) {
                        Text("Not Set").tag(nil as HouseMountingType?)
                        ForEach(HouseMountingType.allCases, id: \.self) { mountingType in
                            Text(mountingType.displayName).tag(Optional(mountingType))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    FieldHeader("Mount Condition")
                    Picker("Mount Condition", selection: mountConditionBinding) {
                        Text("Not Set").tag(nil as MountCondition?)
                        ForEach(MountCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(Optional(condition))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
            }

            CardGroup(title: "Posts + Trim") {
                VStack(spacing: 12) {
                    FieldHeader("Post / Column Material")
                    Picker("Post / Column Material", selection: postMaterialBinding) {
                        Text("Not Set").tag(nil as PostColumnMaterial?)
                        ForEach(PostColumnMaterial.allCases, id: \.self) { material in
                            Text(material.displayName).tag(Optional(material))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    if scope.attachment?.postColumnMaterial == .other {
                        LabeledTextField("Post / Column Material", text: postMaterialOtherBinding, prompt: "Describe post/column material")
                            .formRevealTransition()
                    }

                    LabeledTextField("Post Size", text: postSizeBinding, prompt: "Post size")

                    LabeledTextField("Post Spacing", text: postSpacingBinding, prompt: "Post spacing")

                    Toggle("Trim Present", isOn: trimPresentBinding)
                        .frame(minHeight: 44)

                    if scope.attachment?.trimPresent == true {
                        FieldHeader("Trim Material")
                        Picker("Trim Material", selection: trimMaterialBinding) {
                            Text("Not Set").tag(nil as TrimMaterial?)
                            ForEach(TrimMaterial.allCases, id: \.self) { material in
                                Text(material.displayName).tag(Optional(material))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()

                        if scope.attachment?.trimMaterial == .other {
                            LabeledTextField("Trim Material", text: trimMaterialOtherBinding, prompt: "Describe trim material")
                                .formRevealTransition()
                        }

                        FieldHeader("Trim Thickness")
                        Picker("Trim Thickness", selection: trimThicknessBinding) {
                            Text("Not Set").tag(nil as TrimThickness?)
                            ForEach(TrimThickness.allCases, id: \.self) { thickness in
                                Text(thickness.displayName).tag(Optional(thickness))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .formRevealTransition()

                        if showsCustomTrimThicknessField {
                            LabeledTextField("Trim Thickness", text: trimThicknessCustomBinding, prompt: "Custom or other trim thickness")
                                .keyboardType(.decimalPad)
                                .frame(minHeight: 44)
                                .formRevealTransition()
                        }
                    }
                }
            }

            CardGroup(title: "Fastener Plan") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select all that apply")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(FastenerType.allCases, id: \.self) { fastener in
                        Toggle(fastener.displayName, isOn: fastenerBinding(for: fastener))
                            .frame(minHeight: 44)
                    }
                }
            }

            MeasurementsBlockEditor(
                block: scope.attachment?.measurements,
                preset: .attachmentConditions,
                setBlock: updateMeasurements
            )

            CardGroup(title: "Attachment Notes") {
                TextEditor(text: attachmentNotesBinding)
                    .frame(minHeight: 120)
                    .padding(8)
                    .liquidGlassInputBackground(cornerRadius: 14)
            }
        }
        .animation(.formReveal, value: scope.attachment?.houseWallMaterial == .other)
        .animation(.formReveal, value: scope.attachment?.postColumnMaterial == .other)
        .animation(.formReveal, value: scope.attachment?.trimPresent == true)
        .animation(.formReveal, value: scope.attachment?.trimMaterial == .other)
        .animation(.formReveal, value: showsCustomTrimThicknessField)
    }

    private var houseWallMaterialBinding: Binding<HouseWallMaterial?> {
        Binding(
            get: { scope.attachment?.houseWallMaterial },
            set: { newValue in
                updateAttachment { attachment in
                    attachment.houseWallMaterial = newValue
                    if newValue != .other {
                        attachment.houseWallOther = nil
                    }
                }
            }
        )
    }

    private var houseWallOtherBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.houseWallOther ?? "" },
            set: { newValue in
                updateAttachment { $0.houseWallOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var houseMountingTypeBinding: Binding<HouseMountingType?> {
        Binding(
            get: { scope.attachment?.houseMountingType },
            set: { newValue in
                updateAttachment { $0.houseMountingType = newValue }
            }
        )
    }

    private var mountConditionBinding: Binding<MountCondition?> {
        Binding(
            get: { scope.attachment?.mountCondition },
            set: { newValue in
                updateAttachment { $0.mountCondition = newValue }
            }
        )
    }

    private var postMaterialBinding: Binding<PostColumnMaterial?> {
        Binding(
            get: { scope.attachment?.postColumnMaterial },
            set: { newValue in
                updateAttachment { attachment in
                    attachment.postColumnMaterial = newValue
                    if newValue != .other {
                        attachment.postColumnOther = nil
                    }
                }
            }
        )
    }

    private var postMaterialOtherBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.postColumnOther ?? "" },
            set: { newValue in
                updateAttachment { $0.postColumnOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var postSizeBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.postSize ?? "" },
            set: { newValue in
                updateAttachment { $0.postSize = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var postSpacingBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.postSpacing ?? "" },
            set: { newValue in
                updateAttachment { $0.postSpacing = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var trimPresentBinding: Binding<Bool> {
        Binding(
            get: { scope.attachment?.trimPresent ?? false },
            set: { newValue in
                updateAttachment { attachment in
                    attachment.trimPresent = newValue
                    if !newValue {
                        attachment.trimMaterial = nil
                        attachment.trimMaterialOther = nil
                        attachment.trimThickness = nil
                        attachment.trimThicknessCustom = nil
                    }
                }
            }
        )
    }

    private var trimMaterialBinding: Binding<TrimMaterial?> {
        Binding(
            get: { scope.attachment?.trimMaterial },
            set: { newValue in
                updateAttachment { attachment in
                    attachment.trimMaterial = newValue
                    if newValue != .other {
                        attachment.trimMaterialOther = nil
                    }
                }
            }
        )
    }

    private var trimMaterialOtherBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.trimMaterialOther ?? "" },
            set: { newValue in
                updateAttachment { $0.trimMaterialOther = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var trimThicknessBinding: Binding<TrimThickness?> {
        Binding(
            get: { scope.attachment?.trimThickness },
            set: { newValue in
                updateAttachment { attachment in
                    attachment.trimThickness = newValue
                    if newValue != .custom, newValue != .other {
                        attachment.trimThicknessCustom = nil
                    }
                }
            }
        )
    }

    private var showsCustomTrimThicknessField: Bool {
        switch scope.attachment?.trimThickness {
        case .custom, .other:
            return true
        default:
            return false
        }
    }

    private var trimThicknessCustomBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.attachment?.trimThicknessCustom) },
            set: { newValue in
                updateAttachment { $0.trimThicknessCustom = parseOptionalDouble(newValue) }
            }
        )
    }

    private var attachmentNotesBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.notes ?? "" },
            set: { newValue in
                updateAttachment { $0.notes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func fastenerBinding(for fastener: FastenerType) -> Binding<Bool> {
        Binding(
            get: { scope.attachment?.fastenerPlan?.contains(fastener) ?? false },
            set: { isEnabled in
                updateAttachment { attachment in
                    var selection = attachment.fastenerPlan ?? []
                    if isEnabled {
                        if !selection.contains(fastener) {
                            selection.append(fastener)
                        }
                    } else {
                        selection.removeAll { $0 == fastener }
                    }
                    attachment.fastenerPlan = selection.isEmpty ? nil : selection
                }
            }
        )
    }

    private func updateAttachment(_ update: (inout AttachmentConditions) -> Void) {
        var attachment = scope.attachment ?? emptyAttachmentConditions()
        update(&attachment)
        scope.attachment = attachment
        autosave.scheduleSave(for: scope)
    }

    private func updateMeasurements(_ block: MeasurementsBlock?) {
        updateAttachment { $0.measurements = block }
    }
}

struct DocumentsEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    @State private var activeSlot: DocumentSlotTarget?
    @State private var showingFileImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var showingCameraPicker = false
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 16) {
            commonAttachmentsCard
            additionalAttachmentsCard

            if shouldRenderImportPresenter {
                DocumentImportPresenter(
                    showingFileImporter: $showingFileImporter,
                    selectedPhotoItem: $selectedPhotoItem,
                    showingPhotoPicker: $showingPhotoPicker,
                    showingCameraPicker: $showingCameraPicker,
                    importError: $importError,
                    allowedContentTypes: [.item],
                    errorTitle: "Attachment Import Failed",
                    errorFallbackMessage: "Unable to import the selected attachment.",
                    handleFileImportResult: handleFileImportResult,
                    importSelectedPhotoItem: importSelectedPhotoItem,
                    importCameraImage: importCameraImage,
                    resetImportPresentation: resetImportPresentation
                )
            }
        }
    }

    private var additionalAttachments: [AdditionalDocumentAttachment] {
        scope.documents?.additionalAttachments ?? []
    }

    private var shouldRenderImportPresenter: Bool {
        activeSlot != nil ||
        showingFileImporter ||
        showingPhotoPicker ||
        showingCameraPicker ||
        importError != nil
    }

    private var commonAttachmentsCard: some View {
        CardGroup(title: "Common Attachments") {
            VStack(alignment: .leading, spacing: 16) {
                documentSlotBlock(
                    title: "Irrigation",
                    detail: "One dedicated attachment slot for irrigation documents or imagery.",
                    attachment: scope.documents?.irrigation,
                    target: .irrigation
                )

                Divider()

                documentSlotBlock(
                    title: "Property Survey",
                    detail: "One dedicated attachment slot for the property survey.",
                    attachment: scope.documents?.propertySurvey,
                    target: .propertySurvey
                )
            }
        }
    }

    private var additionalAttachmentsCard: some View {
        CardGroup(title: "Additional Attachments") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add one-off files, photos, or camera captures as needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if additionalAttachments.isEmpty {
                    Text("No additional attachments yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(additionalAttachments.enumerated()), id: \.element.id) { index, row in
                        additionalAttachmentRow(row, index: index)

                        if row.id != additionalAttachments.last?.id {
                            Divider()
                        }
                    }
                }

                Button {
                    addAdditionalAttachmentRow()
                } label: {
                    Label("Add Another Attachment", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .frame(minHeight: 44)
            }
        }
    }

    @ViewBuilder
    private func additionalAttachmentRow(_ row: AdditionalDocumentAttachment, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Attachment \(index + 1)")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 12)

                Button("Remove", role: .destructive) {
                    removeAdditionalAttachmentRow(row.id)
                }
                .buttonStyle(.borderless)
                .frame(minHeight: 44)
            }

            LabeledTextField("Attachment Name", text: additionalAttachmentNameBinding(for: row.id))

            documentSlotBlock(
                title: "File",
                attachment: row.attachment,
                target: .additional(row.id)
            )
        }
    }

    @ViewBuilder
    private func documentSlotBlock(
        title: String,
        detail: String? = nil,
        attachment: DocumentAttachmentFile?,
        target: DocumentSlotTarget
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldHeader(title)

            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let attachment {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: documentAttachmentSymbol(for: attachment))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(attachment.originalFilename)
                            .font(.body.weight(.medium))
                            .lineLimit(2)

                        Text("\(attachment.source.displayName) • \(attachment.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .liquidGlassSurface(cornerRadius: 18)

                HStack(spacing: 10) {
                    attachmentSourceMenu(title: "Replace", systemImage: nil, target: target)

                    Button("Remove", role: .destructive) {
                        clearAttachment(for: target)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(minHeight: 44)
                }
            } else {
                Text("No attachment selected.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                attachmentSourceMenu(title: "Add File", systemImage: "plus", target: target)
            }
        }
    }

    private func additionalAttachmentNameBinding(for rowID: UUID) -> Binding<String> {
        Binding(
            get: {
                additionalAttachments.first(where: { $0.id == rowID })?.name ?? ""
            },
            set: { newValue in
                updateDocuments { documents in
                    guard var rows = documents.additionalAttachments,
                          let index = rows.firstIndex(where: { $0.id == rowID }) else { return }
                    rows[index].name = newValue.nilIfWhitespaceOnly
                    documents.additionalAttachments = rows
                }
            }
        )
    }

    @ViewBuilder
    private func attachmentSourceMenu(title: String, systemImage: String?, target: DocumentSlotTarget) -> some View {
        Menu {
            Button("Files") {
                presentImporter(.files, for: target)
            }

            Button("Photo Library") {
                presentImporter(.photoLibrary, for: target)
            }

            #if canImport(UIKit)
            if DocumentCameraPicker.isCameraAvailable {
                Button("Camera") {
                    presentImporter(.camera, for: target)
                }
            }
            #endif
        } label: {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .frame(minHeight: 44)
    }

    private func presentImporter(_ source: DocumentImportSource, for target: DocumentSlotTarget) {
        activeSlot = target
        selectedPhotoItem = nil

        switch source {
        case .files:
            showingFileImporter = true
        case .photoLibrary:
            showingPhotoPicker = true
        case .camera:
            showingCameraPicker = true
        }
    }

    private func resetImportPresentation(clearActiveSlot: Bool) {
        showingFileImporter = false
        showingPhotoPicker = false
        showingCameraPicker = false
        selectedPhotoItem = nil

        if clearActiveSlot {
            activeSlot = nil
        }
    }

    private func addAdditionalAttachmentRow() {
        updateDocuments { documents in
            var rows = documents.additionalAttachments ?? []
            rows.append(AdditionalDocumentAttachment())
            documents.additionalAttachments = rows
        }
    }

    private func removeAdditionalAttachmentRow(_ rowID: UUID) {
        let attachment = additionalAttachments.first(where: { $0.id == rowID })?.attachment

        updateDocuments(retiring: attachment) { documents in
            var rows = documents.additionalAttachments ?? []
            rows.removeAll { $0.id == rowID }
            documents.additionalAttachments = rows.isEmpty ? nil : rows
        }
    }

    private func clearAttachment(for target: DocumentSlotTarget) {
        let existing = existingAttachment(for: target)

        updateDocuments(retiring: existing) { documents in
            switch target {
            case .irrigation:
                documents.irrigation = nil
            case .propertySurvey:
                documents.propertySurvey = nil
            case .additional(let rowID):
                guard var rows = documents.additionalAttachments,
                      let index = rows.firstIndex(where: { $0.id == rowID }) else { return }
                rows[index].attachment = nil
                documents.additionalAttachments = rows
            }
        }
    }

    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                resetImportPresentation(clearActiveSlot: true)
                return
            }
            let target = activeSlot
            let scopeID = scope.id

            Task {
                do {
                    let attachment = try await Task.detached(priority: .userInitiated) {
                        try DocumentAssetStore.importFile(from: url, scopeID: scopeID)
                    }.value

                    await MainActor.run {
                        persistImportedAttachment(attachment, for: target)
                        resetImportPresentation(clearActiveSlot: true)
                    }
                } catch {
                    await MainActor.run {
                        importError = error.localizedDescription
                        resetImportPresentation(clearActiveSlot: true)
                    }
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
            resetImportPresentation(clearActiveSlot: true)
        }
    }

    private func importSelectedPhotoItem(_ item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw DocumentAssetStore.StoreError.unsupportedImageData
                }
                let scopeID = scope.id
                let target = activeSlot
                let attachment = try await Task.detached(priority: .userInitiated) {
                    try DocumentAssetStore.savePhotoLibraryImage(data: data, scopeID: scopeID)
                }.value

                await MainActor.run {
                    persistImportedAttachment(attachment, for: target)
                    resetImportPresentation(clearActiveSlot: true)
                }
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                    resetImportPresentation(clearActiveSlot: true)
                }
            }
        }
    }

    #if canImport(UIKit)
    private func importCameraImage(_ image: UIImage) {
        do {
            let attachment = try DocumentAssetStore.saveCameraImage(image, scopeID: scope.id)
            persistImportedAttachment(attachment, for: activeSlot)
            resetImportPresentation(clearActiveSlot: true)
        } catch {
            importError = error.localizedDescription
            resetImportPresentation(clearActiveSlot: true)
        }
    }
    #endif

    private func persistImportedAttachment(_ attachment: DocumentAttachmentFile, for target: DocumentSlotTarget?) {
        guard let target else { return }

        let existing = existingAttachment(for: target)

        updateDocuments(retiring: existing) { documents in
            switch target {
            case .irrigation:
                documents.irrigation = attachment
            case .propertySurvey:
                documents.propertySurvey = attachment
            case .additional(let rowID):
                guard var rows = documents.additionalAttachments,
                      let index = rows.firstIndex(where: { $0.id == rowID }) else { return }
                rows[index].attachment = attachment
                documents.additionalAttachments = rows
            }
        }

        activeSlot = nil
    }

    private func existingAttachment(for target: DocumentSlotTarget) -> DocumentAttachmentFile? {
        switch target {
        case .irrigation:
            return scope.documents?.irrigation
        case .propertySurvey:
            return scope.documents?.propertySurvey
        case .additional(let rowID):
            return additionalAttachments.first(where: { $0.id == rowID })?.attachment
        }
    }

    @discardableResult
    private func updateDocuments(
        retiring attachment: DocumentAttachmentFile? = nil,
        _ update: (inout DocumentsSection) -> Void
    ) -> Bool {
        let previousDocuments = scope.documents
        var documents = scope.documents ?? emptyDocumentsSection()
        update(&documents)
        let updatedDocuments = documents.isEffectivelyEmpty ? nil : documents
        scope.documents = updatedDocuments

        let didChange = previousDocuments != updatedDocuments
        guard let attachment, didChange else {
            autosave.scheduleSave(for: scope)
            return didChange
        }

        autosave.flush(
            scope: scope,
            afterConfirmedSave: { [weak scope] in
                guard let scope,
                      !Self.isAttachment(attachment, referencedIn: scope.documents) else {
                    return
                }

                DocumentAssetStore.retireAttachment(attachment, scopeID: scope.id)
            }
        )
        return true
    }

    private static func isAttachment(
        _ candidate: DocumentAttachmentFile,
        referencedIn documents: DocumentsSection?
    ) -> Bool {
        guard let documents else { return false }
        let attachments = [documents.irrigation, documents.propertySurvey].compactMap { $0 } +
            (documents.additionalAttachments ?? []).compactMap(\.attachment)
        let candidatePath = URL(fileURLWithPath: candidate.filePath).standardizedFileURL.path

        return attachments.contains { attachment in
            attachment.id == candidate.id ||
            URL(fileURLWithPath: attachment.filePath).standardizedFileURL.path == candidatePath
        }
    }

    private func documentAttachmentSymbol(for attachment: DocumentAttachmentFile) -> String {
        guard let identifier = attachment.contentTypeIdentifier,
              let type = UTType(identifier) else {
            return "doc"
        }

        if type.conforms(to: .image) {
            return "photo"
        }

        if type.conforms(to: .pdf) {
            return "doc.richtext"
        }

        if type.conforms(to: .plainText) {
            return "doc.text"
        }

        return "doc"
    }
}

private struct DocumentImportPresenter: View {
    @Binding var showingFileImporter: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var showingPhotoPicker: Bool
    @Binding var showingCameraPicker: Bool
    @Binding var importError: String?

    let allowedContentTypes: [UTType]
    let errorTitle: String
    let errorFallbackMessage: String
    let handleFileImportResult: (Result<[URL], Error>) -> Void
    let importSelectedPhotoItem: (PhotosPickerItem) -> Void
#if canImport(UIKit)
    let importCameraImage: (UIImage) -> Void
#endif
    let resetImportPresentation: (Bool) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: false,
                onCompletion: handleFileImportResult
            )
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                importSelectedPhotoItem(newItem)
            }
            .sheet(isPresented: $showingCameraPicker) {
                #if canImport(UIKit)
                DocumentCameraPicker(
                    onImagePicked: { image in
                        showingCameraPicker = false
                        importCameraImage(image)
                    },
                    onCancel: {
                        resetImportPresentation(true)
                    }
                )
                .ignoresSafeArea()
                #else
                EmptyView()
                #endif
            }
            .alert(errorTitle, isPresented: importErrorPresented) {
                Button("OK", role: .cancel) {
                    importError = nil
                }
            } message: {
                Text(importError ?? errorFallbackMessage)
            }
    }

    private var importErrorPresented: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isPresented in
                if !isPresented {
                    importError = nil
                }
            }
        )
    }
}

private enum DocumentImportSource {
    case files
    case photoLibrary
    case camera
}

private enum DocumentSlotTarget: Identifiable, Equatable {
    case irrigation
    case propertySurvey
    case additional(UUID)

    var id: String {
        switch self {
        case .irrigation:
            return "irrigation"
        case .propertySurvey:
            return "propertySurvey"
        case .additional(let rowID):
            return "additional-\(rowID.uuidString)"
        }
    }
}

struct FinishesEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Trim + Color") {
                VStack(spacing: 12) {
                    LabeledTextField("Trim Type", text: trimTypeBinding, prompt: "Trim type")

                    LabeledTextField("Paint or Powder Color", text: paintOrPowderColorBinding, prompt: "Paint or powder color")

                    OptionalBoolPicker(title: "Siding Replacement Required", selection: sidingReplacementRequiredBinding)
                }
            }

            CardGroup(title: "Sealant Notes") {
                NotesField(title: "Caulking and Sealing Notes", text: caulkingSealingNotesBinding, minHeight: 140, showInlineTitle: false)
            }

            MeasurementsBlockEditor(
                block: scope.finishes?.measurements,
                preset: .finishes,
                setBlock: updateMeasurements
            )
        }
    }

    private var trimTypeBinding: Binding<String> {
        Binding(
            get: { scope.finishes?.trimType ?? "" },
            set: { newValue in
                updateFinishes { $0.trimType = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var paintOrPowderColorBinding: Binding<String> {
        Binding(
            get: { scope.finishes?.paintOrPowderColor ?? "" },
            set: { newValue in
                updateFinishes { $0.paintOrPowderColor = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var sidingReplacementRequiredBinding: Binding<Bool?> {
        Binding(
            get: { scope.finishes?.sidingReplacementRequired },
            set: { newValue in
                updateFinishes { $0.sidingReplacementRequired = newValue }
            }
        )
    }

    private var caulkingSealingNotesBinding: Binding<String> {
        Binding(
            get: { scope.finishes?.caulkingSealingNotes ?? "" },
            set: { newValue in
                updateFinishes { $0.caulkingSealingNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func updateFinishes(_ update: (inout Finishes) -> Void) {
        var finishes = scope.finishes ?? emptyFinishes()
        update(&finishes)
        scope.finishes = finishes.isEffectivelyEmpty ? nil : finishes
        autosave.scheduleSave(for: scope)
    }

    private func updateMeasurements(_ block: MeasurementsBlock?) {
        updateFinishes { $0.measurements = block }
    }
}

struct PermitsHOAEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Approvals") {
                VStack(spacing: 12) {
                    OptionalBoolPicker(title: "Permit Required", selection: permitRequiredBinding)
                    OptionalBoolPicker(title: "HOA Approval Required", selection: hoaApprovalRequiredBinding)
                    OptionalBoolPicker(title: "Engineering Required", selection: engineeringRequiredBinding)

                    LabeledTextField("Jurisdiction", text: jurisdictionBinding)
                }
            }

            CardGroup(title: "Status Notes") {
                NotesField(title: "Status Notes", text: statusNotesBinding, minHeight: 140, showInlineTitle: false)
            }
        }
    }

    private var permitRequiredBinding: Binding<Bool?> {
        Binding(
            get: { scope.permitsHOA?.permitRequired },
            set: { newValue in
                updatePermitsHOA { $0.permitRequired = newValue }
            }
        )
    }

    private var jurisdictionBinding: Binding<String> {
        Binding(
            get: { scope.permitsHOA?.jurisdiction ?? "" },
            set: { newValue in
                updatePermitsHOA { $0.jurisdiction = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var hoaApprovalRequiredBinding: Binding<Bool?> {
        Binding(
            get: { scope.permitsHOA?.hoaApprovalRequired },
            set: { newValue in
                updatePermitsHOA { $0.hoaApprovalRequired = newValue }
            }
        )
    }

    private var engineeringRequiredBinding: Binding<Bool?> {
        Binding(
            get: { scope.permitsHOA?.engineeringRequired },
            set: { newValue in
                updatePermitsHOA { $0.engineeringRequired = newValue }
            }
        )
    }

    private var statusNotesBinding: Binding<String> {
        Binding(
            get: { scope.permitsHOA?.statusNotes ?? "" },
            set: { newValue in
                updatePermitsHOA { $0.statusNotes = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func updatePermitsHOA(_ update: (inout PermitsHOA) -> Void) {
        var permits = scope.permitsHOA ?? emptyPermitsHOA()
        update(&permits)
        scope.permitsHOA = permits.isEffectivelyEmpty ? nil : permits
        autosave.scheduleSave(for: scope)
    }
}

struct ProductionNotesEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Job Status") {
                VStack(spacing: 12) {
                    Picker("Status", selection: statusBinding) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)

                    LabeledTextField("Job Number", text: jobNumberBinding, prompt: "Job number")
                }
            }

            CardGroup(title: "Production Schedule") {
                VStack(spacing: 12) {
                    Toggle("Track Production Metadata", isOn: includeProductionMetaBinding)
                        .frame(minHeight: 44)

                    if scope.production != nil {
                        Toggle("Include Start Date", isOn: includeStartDateBinding)
                            .frame(minHeight: 44)
                            .formRevealTransition()

                        if scope.production?.startDate != nil {
                            DatePicker(
                                "Start Date",
                                selection: productionStartDateBinding,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .formRevealTransition()
                        }

                        LabeledTextField("Crew Lead", text: crewLeadBinding, prompt: "Crew lead")
                            .formRevealTransition()

                        LabeledTextField("Duration Estimate", text: durationEstimateBinding, prompt: "Duration estimate")
                            .formRevealTransition()

                        Picker("Material Order", selection: materialOrderStatusBinding) {
                            ForEach(MaterialOrderStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                        .formRevealTransition()

                        Picker("Permit Status", selection: permitStatusBinding) {
                            ForEach(PermitStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                        .formRevealTransition()
                    }
                }
            }

            CardGroup(title: "Production Notes") {
                VStack(spacing: 12) {
                    Toggle("Include Notes", isOn: includeProductionNotesBinding)
                        .frame(minHeight: 44)

                    if includeProductionNotesBinding.wrappedValue {
                        TextEditor(text: productionNotesBinding)
                            .frame(minHeight: 140)
                            .padding(8)
                            .liquidGlassInputBackground(cornerRadius: 14)
                            .formRevealTransition()
                    }
                }
            }
        }
        .animation(.formReveal, value: scope.production != nil)
        .animation(.formReveal, value: scope.production?.startDate != nil)
        .animation(.formReveal, value: includeProductionNotesBinding.wrappedValue)
    }

    private var statusBinding: Binding<JobStatus> {
        Binding(
            get: { scope.status },
            set: { newValue in
                scope.status = newValue
                autosave.scheduleSave(for: scope)
            }
        )
    }

    private var jobNumberBinding: Binding<String> {
        Binding(
            get: { scope.jobNumber ?? "" },
            set: { newValue in
                scope.jobNumber = newValue.nilIfBlank
                autosave.scheduleSave(for: scope)
            }
        )
    }

    private var includeProductionMetaBinding: Binding<Bool> {
        Binding(
            get: { scope.production != nil },
            set: { newValue in
                scope.production = newValue ? (scope.production ?? defaultProductionOrderMeta()) : nil
                autosave.scheduleSave(for: scope)
            }
        )
    }

    private var includeStartDateBinding: Binding<Bool> {
        Binding(
            get: { scope.production?.startDate != nil },
            set: { newValue in
                updateProduction { production in
                    production.startDate = newValue ? (production.startDate ?? .now) : nil
                }
            }
        )
    }

    private var productionStartDateBinding: Binding<Date> {
        Binding(
            get: { scope.production?.startDate ?? .now },
            set: { newValue in
                updateProduction { $0.startDate = newValue }
            }
        )
    }

    private var crewLeadBinding: Binding<String> {
        Binding(
            get: { scope.production?.crewLead ?? "" },
            set: { newValue in
                updateProduction { $0.crewLead = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var durationEstimateBinding: Binding<String> {
        Binding(
            get: { scope.production?.durationEstimate ?? "" },
            set: { newValue in
                updateProduction { $0.durationEstimate = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private var materialOrderStatusBinding: Binding<MaterialOrderStatus> {
        Binding(
            get: { scope.production?.materialOrderStatus ?? .notOrdered },
            set: { newValue in
                updateProduction { $0.materialOrderStatus = newValue }
            }
        )
    }

    private var permitStatusBinding: Binding<PermitStatus> {
        Binding(
            get: { scope.production?.permitStatus ?? .notSubmitted },
            set: { newValue in
                updateProduction { $0.permitStatus = newValue }
            }
        )
    }

    private var includeProductionNotesBinding: Binding<Bool> {
        Binding(
            get: { scope.customerApproval?.optionsConfirmedText != nil },
            set: { newValue in
                if newValue {
                    updateCustomerApproval { approval in
                        if approval.optionsConfirmedText == nil {
                            approval.optionsConfirmedText = ""
                        }
                    }
                } else {
                    updateCustomerApproval { approval in
                        approval.optionsConfirmedText = nil
                    }
                }
            }
        )
    }

    private var productionNotesBinding: Binding<String> {
        Binding(
            get: { scope.customerApproval?.optionsConfirmedText ?? "" },
            set: { newValue in
                updateCustomerApproval { $0.optionsConfirmedText = newValue.nilIfWhitespaceOnly }
            }
        )
    }

    private func updateProduction(_ update: (inout ProductionOrderMeta) -> Void) {
        var production = scope.production ?? emptyProductionOrderMeta()
        update(&production)
        scope.production = production
        autosave.scheduleSave(for: scope)
    }

    private func updateCustomerApproval(_ update: (inout CustomerApproval) -> Void) {
        var approval = scope.customerApproval ?? emptyCustomerApproval()
        update(&approval)

        if approval.optionsConfirmedText == nil,
           approval.signaturePNGPath == nil,
           approval.signedDate == nil {
            scope.customerApproval = nil
        } else {
            scope.customerApproval = approval
        }

        autosave.scheduleSave(for: scope)
    }
}

struct SignatureAndSketchEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave
    @Environment(\.scenePhase) private var scenePhase

    @State private var customerSignatureDrawing = PKDrawing()
    @State private var salespersonSignatureDrawing = PKDrawing()
    @State private var siteDiagramDrawing = PKDrawing()
    @State private var hasLoadedDrawings = false

    private let salespersonSketchTitle = "Salesperson Signature"
    private let siteDiagramSketchTitle = "Site Diagram"
    private let customerSignatureBaseName = "customer-signature"
    private let salespersonSignatureBaseName = "salesperson-signature"
    private let siteDiagramBaseName = "site-diagram"

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Customer Signature") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Capture customer sign-off with Apple Pencil or touch.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    PencilDrawingCanvas(drawing: $customerSignatureDrawing)
                        .frame(minHeight: 220)

                    Toggle("Include Signed Date", isOn: includesSignedDateBinding)
                        .frame(minHeight: 44)

                    if scope.customerApproval?.signedDate != nil {
                        DatePicker(
                            "Signed Date",
                            selection: signedDateBinding,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                        .formRevealTransition()
                    }

                    Button("Clear Signature", role: .destructive) {
                        withAnimation(.formReveal) {
                            customerSignatureDrawing = PKDrawing()
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(minHeight: 44)
                    .disabled(customerSignatureDrawing.strokes.isEmpty)
                }
            }

            CardGroup(title: "Salesperson Signature") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stored as a sketch attachment for Milestone 3.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    PencilDrawingCanvas(drawing: $salespersonSignatureDrawing)
                        .frame(minHeight: 220)

                    Button("Clear Signature", role: .destructive) {
                        withAnimation(.formReveal) {
                            salespersonSignatureDrawing = PKDrawing()
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(minHeight: 44)
                    .disabled(salespersonSignatureDrawing.strokes.isEmpty)
                }
            }

            CardGroup(title: "Site Diagram (Optional)") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Use a quick sketch to show site-specific details.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    PencilDrawingCanvas(drawing: $siteDiagramDrawing)
                        .frame(minHeight: 260)

                    Button("Clear Diagram", role: .destructive) {
                        withAnimation(.formReveal) {
                            siteDiagramDrawing = PKDrawing()
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(minHeight: 44)
                    .disabled(siteDiagramDrawing.strokes.isEmpty)
                }
            }
        }
        .onAppear {
            loadDrawingsIfNeeded()
        }
        .onDisappear {
            flushDrawingPersistenceIfNeeded()
        }
        .onChange(of: customerSignatureDrawing.dataRepresentation()) { _, _ in
            guard hasLoadedDrawings else { return }
            persistCustomerSignatureDrawing()
        }
        .onChange(of: salespersonSignatureDrawing.dataRepresentation()) { _, _ in
            guard hasLoadedDrawings else { return }
            persistSketchDrawing(
                salespersonSignatureDrawing,
                title: salespersonSketchTitle,
                baseName: salespersonSignatureBaseName
            )
        }
        .onChange(of: siteDiagramDrawing.dataRepresentation()) { _, _ in
            guard hasLoadedDrawings else { return }
            persistSketchDrawing(
                siteDiagramDrawing,
                title: siteDiagramSketchTitle,
                baseName: siteDiagramBaseName
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active else { return }
            flushDrawingPersistenceIfNeeded()
        }
        .animation(.formReveal, value: scope.customerApproval?.signedDate != nil)
        .animation(.formReveal, value: customerSignatureDrawing.strokes.isEmpty)
        .animation(.formReveal, value: salespersonSignatureDrawing.strokes.isEmpty)
        .animation(.formReveal, value: siteDiagramDrawing.strokes.isEmpty)
    }

    private var includesSignedDateBinding: Binding<Bool> {
        Binding(
            get: { scope.customerApproval?.signedDate != nil },
            set: { newValue in
                if newValue {
                    updateCustomerApproval { approval in
                        approval.signedDate = approval.signedDate ?? .now
                    }
                } else {
                    updateCustomerApproval { approval in
                        approval.signedDate = nil
                    }
                }
            }
        )
    }

    private var signedDateBinding: Binding<Date> {
        Binding(
            get: { scope.customerApproval?.signedDate ?? .now },
            set: { newValue in
                updateCustomerApproval { approval in
                    approval.signedDate = newValue
                }
            }
        )
    }

    private func loadDrawingsIfNeeded() {
        guard !hasLoadedDrawings else { return }

        if let customerURLs = try? DrawingAssetStore.urls(scopeID: scope.id, baseName: customerSignatureBaseName) {
            customerSignatureDrawing = DrawingAssetStore.drawing(for: customerURLs.drawing.path)
        }

        salespersonSignatureDrawing = loadDeterministicSketchDrawing(baseName: salespersonSignatureBaseName)
        siteDiagramDrawing = loadDeterministicSketchDrawing(baseName: siteDiagramBaseName)
        reconcileDeterministicSketchMetadataIfNeeded()

        hasLoadedDrawings = true
    }

    private func persistCustomerSignatureDrawing() {
        guard let urls = try? DrawingAssetStore.urls(scopeID: scope.id, baseName: customerSignatureBaseName) else {
            return
        }

        if customerSignatureDrawing.strokes.isEmpty {
            DrawingAssetStore.remove(urls: urls)
            updateCustomerApproval { approval in
                approval.signaturePNGPath = nil
                approval.signedDate = nil
            }
            return
        }

        do {
            try DrawingAssetStore.save(customerSignatureDrawing, to: urls)
            updateCustomerApproval { approval in
                approval.signaturePNGPath = urls.preview.path
                approval.signedDate = approval.signedDate ?? .now
            }
        } catch {
            assertionFailure("Failed to save customer signature")
        }
    }

    private func persistSketchDrawing(_ drawing: PKDrawing, title: String, baseName: String) {
        guard let urls = try? DrawingAssetStore.urls(scopeID: scope.id, baseName: baseName) else {
            return
        }

        if drawing.strokes.isEmpty {
            DrawingAssetStore.remove(urls: urls)
            removeSketch(title: title)
            return
        }

        do {
            try DrawingAssetStore.save(drawing, to: urls)
            upsertSketch(
                title: title,
                drawingPath: urls.drawing.path,
                previewPath: urls.preview.path
            )
        } catch {
            assertionFailure("Failed to save sketch")
        }
    }

    private func loadDeterministicSketchDrawing(baseName: String) -> PKDrawing {
        guard let urls = try? DrawingAssetStore.urls(scopeID: scope.id, baseName: baseName) else {
            return PKDrawing()
        }

        return DrawingAssetStore.drawing(for: urls.drawing.path)
    }

    private func reconcileDeterministicSketchMetadataIfNeeded() {
        reconcileSketchMetadataIfNeeded(
            title: salespersonSketchTitle,
            baseName: salespersonSignatureBaseName
        )
        reconcileSketchMetadataIfNeeded(
            title: siteDiagramSketchTitle,
            baseName: siteDiagramBaseName
        )
    }

    private func reconcileSketchMetadataIfNeeded(title: String, baseName: String) {
        guard let urls = try? DrawingAssetStore.urls(scopeID: scope.id, baseName: baseName) else {
            return
        }

        let drawing = DrawingAssetStore.drawing(for: urls.drawing.path)
        guard !drawing.strokes.isEmpty else { return }

        let drawingPath = urls.drawing.path
        let previewPath = urls.preview.path
        let existingSketch = scope.sketches?.first(where: { $0.title == title })

        if let existingSketch,
           existingSketch.drawingDataPath == drawingPath,
           existingSketch.previewPNGPath == previewPath {
            return
        }

        var sketches = scope.sketches ?? []

        if let index = sketches.firstIndex(where: { $0.title == title }) {
            var existing = sketches[index]
            existing.drawingDataPath = drawingPath
            existing.previewPNGPath = previewPath
            sketches[index] = existing
        } else {
            sketches.append(
                SketchAttachment(
                    title: title,
                    drawingDataPath: drawingPath,
                    previewPNGPath: previewPath
                )
            )
        }

        scope.sketches = sketches
        persistSketchMetadataImmediately()
    }

    private func upsertSketch(title: String, drawingPath: String, previewPath: String) {
        var sketches = scope.sketches ?? []
        let commitDate = Date.now

        if let index = sketches.firstIndex(where: { $0.title == title }) {
            var existing = sketches[index]
            existing.drawingDataPath = drawingPath
            existing.previewPNGPath = previewPath
            existing.createdAt = commitDate
            sketches[index] = existing
        } else {
            sketches.append(
                SketchAttachment(
                    title: title,
                    drawingDataPath: drawingPath,
                    previewPNGPath: previewPath,
                    createdAt: commitDate
                )
            )
        }

        scope.sketches = sketches
        persistSketchMetadataImmediately()
    }

    private func removeSketch(title: String) {
        guard var sketches = scope.sketches else { return }

        sketches.removeAll(where: { $0.title == title })
        scope.sketches = sketches.isEmpty ? nil : sketches
        persistSketchMetadataImmediately()
    }

    private func persistSketchMetadataImmediately() {
        autosave.flush(scope: scope)
    }

    private func flushDrawingPersistenceIfNeeded() {
        guard hasLoadedDrawings else { return }
        autosave.flush(scope: scope)
    }

    private func updateCustomerApproval(_ update: (inout CustomerApproval) -> Void) {
        var approval = scope.customerApproval ?? emptyCustomerApproval()
        update(&approval)

        if approval.optionsConfirmedText == nil,
           approval.signaturePNGPath == nil,
           approval.signedDate == nil {
            scope.customerApproval = nil
        } else {
            scope.customerApproval = approval
        }

        autosave.scheduleSave(for: scope)
    }
}

private struct FieldHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MeasurementTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        LabeledTextField(title, text: $text)
            .keyboardType(.decimalPad)
    }
}

private enum MeasurementSectionPreset {
    case structuralSystem
    case screenEnclosure
    case sunroom
    case electrical
    case drainage
    case attachmentConditions
    case finishes

    var typeOptions: [String] {
        switch self {
        case .structuralSystem:
            return ["Width", "Length", "Height", "Projection", "Fascia Height", "Beam Height", "Post Height", "Post Spacing", "Knee Wall Height", MeasurementTypeOption.otherValue]
        case .screenEnclosure:
            return ["Width", "Length", "Height", "Wall Height", "Knee Wall Height", "Door Width", "Door Height", "Opening Width", "Opening Height", MeasurementTypeOption.otherValue]
        case .sunroom:
            return ["Width", "Length", "Height", "Wall Height", "Window Width", "Window Height", "Door Width", "Door Height", "Opening Width", "Opening Height", MeasurementTypeOption.otherValue]
        case .electrical:
            return ["Panel Distance", "Outlet Height", "Switch Height", "Trench Length", "Run Length", "Clearance", MeasurementTypeOption.otherValue]
        case .drainage:
            return ["Length", "Width", "Depth", "Drop", "Slope", "Elevation Change", "Distance", MeasurementTypeOption.otherValue]
        case .attachmentConditions:
            return ["Attachment Height", "Offset", "Clearance", "Span", "Depth", MeasurementTypeOption.otherValue]
        case .finishes:
            return ["Width", "Height", "Length", "Coverage Area", "Thickness", "Reveal", MeasurementTypeOption.otherValue]
        }
    }
}

private struct MeasurementsBlockEditor: View {
    let block: MeasurementsBlock?
    let preset: MeasurementSectionPreset
    let setBlock: (MeasurementsBlock?) -> Void

    private var items: [MeasurementItem] {
        block?.items ?? []
    }

    var body: some View {
        CardGroup(title: "Measurements") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Add Measurements", isOn: enabledBinding)
                    .frame(minHeight: 44)

                if block?.isEnabled == true {
                    Text("Add section-specific measurements for production. Use ' for feet and \" for inches.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .formRevealTransition()

                    if items.isEmpty {
                        Text("No measurements added.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .formRevealTransition()
                    }

                    ForEach(items) { item in
                        measurementRow(item)
                            .formRevealTransition()
                    }

                    Button {
                        addMeasurement()
                    } label: {
                        Label("Add Measurement", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                    .formRevealTransition()
                }
            }
        }
        .animation(.formReveal, value: block?.isEnabled == true)
        .animation(.formReveal, value: items.count)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { block?.isEnabled == true },
            set: { isEnabled in
                var updated = block ?? MeasurementsBlock(isEnabled: nil, items: nil)
                updated.isEnabled = isEnabled
                if isEnabled && (updated.items ?? []).isEmpty {
                    updated.items = [newMeasurementItem()]
                }
                setBlock(updated.isEffectivelyEmpty ? nil : updated)
            }
        )
    }

    @ViewBuilder
    private func measurementRow(_ item: MeasurementItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    FieldHeader("Measurement Type")
                    Picker("Measurement Type", selection: typeBinding(for: item.id)) {
                        ForEach(preset.typeOptions, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }

                Button(role: .destructive) {
                    removeMeasurement(id: item.id)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove measurement")
            }

            if item.type == MeasurementTypeOption.otherValue {
                LabeledTextField("Custom Measurement Type", text: customTypeBinding(for: item.id), prompt: "Custom measurement type")
                    .formRevealTransition()
            }

            LabeledTextField(
                "Measurement Value",
                text: valueBinding(for: item.id),
                helperText: "Use ' for feet and \" for inches."
            )
                .textInputAutocapitalization(.never)

            NotesField(
                title: "Measurement Notes",
                text: notesBinding(for: item.id),
                minHeight: 92,
                prompt: "Add notes for this measurement"
            )
        }
        .padding(12)
        .liquidGlassSurface(cornerRadius: 16)
    }

    private func typeBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { item(with: id)?.type ?? preset.typeOptions.first ?? MeasurementTypeOption.otherValue },
            set: { newValue in
                updateItem(id: id) { item in
                    item.type = newValue
                }
            }
        )
    }

    private func customTypeBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { item(with: id)?.customType ?? "" },
            set: { newValue in
                updateItem(id: id) { item in
                    item.customType = newValue.nilIfWhitespaceOnly
                }
            }
        )
    }

    private func valueBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { item(with: id)?.value ?? "" },
            set: { newValue in
                updateItem(id: id) { item in
                    item.value = newValue.nilIfWhitespaceOnly
                }
            }
        )
    }

    private func notesBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { item(with: id)?.notes ?? "" },
            set: { newValue in
                updateItem(id: id) { item in
                    item.notes = newValue.nilIfWhitespaceOnly
                }
            }
        )
    }

    private func item(with id: UUID) -> MeasurementItem? {
        items.first { $0.id == id }
    }

    private func addMeasurement() {
        var updated = block ?? MeasurementsBlock(isEnabled: true, items: nil)
        updated.isEnabled = true
        var rows = updated.items ?? []
        rows.append(newMeasurementItem())
        updated.items = rows
        setBlock(updated)
    }

    private func removeMeasurement(id: UUID) {
        var updated = block ?? MeasurementsBlock(isEnabled: true, items: nil)
        var rows = updated.items ?? []
        rows.removeAll { $0.id == id }
        updated.items = rows
        setBlock(updated.isEffectivelyEmpty ? nil : updated)
    }

    private func updateItem(id: UUID, _ update: (inout MeasurementItem) -> Void) {
        var updated = block ?? MeasurementsBlock(isEnabled: true, items: nil)
        var rows = updated.items ?? []
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        update(&rows[index])
        updated.items = rows
        setBlock(updated.isEffectivelyEmpty ? nil : updated)
    }

    private func newMeasurementItem() -> MeasurementItem {
        MeasurementItem(type: preset.typeOptions.first)
    }
}

private struct NotesField: View {
    let title: String
    @Binding var text: String
    let minHeight: CGFloat
    let showInlineTitle: Bool
    let prompt: String?

    init(
        title: String,
        text: Binding<String>,
        minHeight: CGFloat,
        showInlineTitle: Bool = true,
        prompt: String? = nil
    ) {
        self.title = title
        self._text = text
        self.minHeight = minHeight
        self.showInlineTitle = showInlineTitle
        self.prompt = prompt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showInlineTitle {
                FieldHeader(title)
            }

            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .padding(8)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty, let prompt {
                        Text(prompt)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .liquidGlassInputBackground(cornerRadius: 14)
        }
    }
}

private struct OptionalBoolPicker: View {
    let title: String
    @Binding var selection: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body)

            Picker(title, selection: $selection) {
                Text("Not Set").tag(nil as Bool?)
                Text("Yes").tag(Optional(true))
                Text("No").tag(Optional(false))
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
            .padding(6)
            .liquidGlassSurface(cornerRadius: 16)
        }
    }
}

private struct MultiSelectOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension Animation {
    static let formReveal = Animation.snappy(duration: 0.24, extraBounce: 0)
}

private extension View {
    func formRevealTransition() -> some View {
        transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        ))
    }
}

private func parseOptionalDouble(_ value: String) -> Double? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return Double(trimmed)
}

private func formatOptionalDouble(_ value: Double?) -> String {
    guard let value else { return "" }
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(value)
}

private func emptyEnclosure() -> Enclosure {
    Enclosure(
        enclosureTypes: nil,
        screenWallType: nil,
        screenTint: nil,
        screenFrameSize: nil,
        screenFrameColor: nil,
        screenFrameColorCustom: nil,
        screenEnclosureNotes: nil,
        screenMeasurements: nil,
        windowSystem: nil,
        sunroomMeasurements: nil,
        kneeWall: nil,
        doors: nil
    )
}

private func emptyExistingConditions() -> ExistingConditions {
    ExistingConditions(
        houseStories: nil,
        exteriorFinish: nil,
        existingStructure: nil,
        existingStructureNotes: nil,
        obstaclesNotes: nil,
        utilitiesNotes: nil,
        hoaNotes: nil,
        photoChecklist: nil
    )
}

private func emptyStructuralSystem() -> StructuralSystem {
    StructuralSystem(
        systemType: nil,
        systemTypeOther: nil,
        measurements: nil,
        insulatedAluminumPatioCover: nil,
        pergolaType: nil,
        motorizedLouveredPergola: nil,
        manuallyRetractableLouveredPergola: nil,
        cedarPergola: nil,
        alumawoodPergola: nil,
        frameMaterial: nil,
        postSize: nil,
        beamType: nil,
        roofSystem: nil,
        roofColor: nil,
        frameColor: nil,
        notes: nil
    )
}

private func emptyInsulatedAluminumPatioCoverDetails() -> InsulatedAluminumPatioCoverDetails {
    InsulatedAluminumPatioCoverDetails(
        width: nil,
        projection: nil,
        numberOfPosts: nil,
        roofType: nil
    )
}

private func emptyPergolaDimensionDetails() -> PergolaDimensionDetails {
    PergolaDimensionDetails(
        width: nil,
        length: nil,
        height: nil,
        notes: nil
    )
}

private func emptyCedarPergolaDetails() -> CedarPergolaDetails {
    CedarPergolaDetails(
        postSize: nil,
        postSizeOther: nil,
        beamSize: nil,
        beamSizeOther: nil,
        rafterSize: nil,
        rafterSizeOther: nil,
        lattice: nil,
        hardware: nil,
        finish: nil,
        productCode: nil
    )
}

private func emptyAlumawoodPergolaDetails() -> AlumawoodPergolaDetails {
    AlumawoodPergolaDetails(
        mountType: nil,
        width: nil,
        length: nil,
        height: nil,
        attachmentType: nil,
        color: nil,
        privacyWall: nil
    )
}

private func emptyWindowSystem() -> WindowSystem {
    WindowSystem(
        windowType: nil,
        frameSystem: nil,
        glassType: nil,
        glassSafety: nil,
        gridOption: nil,
        operation: nil,
        color: nil,
        colorCustom: nil,
        windowHeight: nil,
        numBays: nil,
        configuration: nil,
        notes: nil
    )
}

private func emptyElectrical() -> Electrical {
    Electrical(
        outletCount: nil,
        lighting: nil,
        fanInstall: nil,
        switchLocations: nil,
        dedicatedCircuits: nil,
        notes: nil,
        measurements: nil
    )
}

private func emptyDrainage() -> Drainage {
    Drainage(
        gutters: nil,
        downspoutLocations: nil,
        drainTieIn: nil,
        slopeNotes: nil,
        measurements: nil
    )
}

private extension WindowSystem {
    var isEffectivelyEmpty: Bool {
        windowType == nil &&
        frameSystem == nil &&
        glassType == nil &&
        glassSafety == nil &&
        gridOption == nil &&
        operation == nil &&
        color == nil &&
        (colorCustom ?? "").nilIfBlank == nil &&
        windowHeight == nil &&
        numBays == nil &&
        configuration == nil &&
        (notes ?? "").nilIfBlank == nil
    }
}

private func emptyKneeWall() -> KneeWall {
    KneeWall(
        option: KneeWallOption.none,
        panelHeight: nil,
        panelColor: nil,
        linearFootage: nil,
        height: nil,
        interiorFinishColor: nil,
        exteriorFinishColor: nil,
        framing: nil
    )
}

private func emptyDoorOptions() -> DoorOptions {
    DoorOptions(
        doorType: DoorType.none,
        style: nil,
        operableSide: nil,
        hingeSide: nil,
        width: nil,
        height: nil,
        color: nil,
        dimensions: nil,
        notes: nil
    )
}

private func emptyAttachmentConditions() -> AttachmentConditions {
    AttachmentConditions(
        houseWallMaterial: nil,
        houseWallOther: nil,
        houseMountingType: nil,
        postColumnMaterial: nil,
        postColumnOther: nil,
        postSize: nil,
        postSpacing: nil,
        trimPresent: nil,
        trimMaterial: nil,
        trimMaterialOther: nil,
        trimThickness: nil,
        trimThicknessCustom: nil,
        mountCondition: nil,
        fastenerPlan: nil,
        notes: nil,
        measurements: nil
    )
}

private func emptyDocumentsSection() -> DocumentsSection {
    DocumentsSection(
        irrigation: nil,
        propertySurvey: nil,
        additionalAttachments: nil
    )
}

private func emptyFinishes() -> Finishes {
    Finishes(
        trimType: nil,
        paintOrPowderColor: nil,
        sidingReplacementRequired: nil,
        caulkingSealingNotes: nil,
        measurements: nil
    )
}

private func emptyPermitsHOA() -> PermitsHOA {
    PermitsHOA(
        permitRequired: nil,
        jurisdiction: nil,
        hoaApprovalRequired: nil,
        engineeringRequired: nil,
        statusNotes: nil
    )
}

private func emptyProductionOrderMeta() -> ProductionOrderMeta {
    ProductionOrderMeta(
        startDate: nil,
        crewLead: nil,
        durationEstimate: nil,
        materialOrderStatus: nil,
        permitStatus: nil
    )
}

private func defaultProductionOrderMeta() -> ProductionOrderMeta {
    ProductionOrderMeta(
        startDate: nil,
        crewLead: nil,
        durationEstimate: nil,
        materialOrderStatus: .notOrdered,
        permitStatus: .notSubmitted
    )
}

private extension Electrical {
    var isEffectivelyEmpty: Bool {
        outletCount == nil &&
        lighting == nil &&
        fanInstall == nil &&
        (switchLocations ?? "").nilIfBlank == nil &&
        (dedicatedCircuits ?? []).isEmpty &&
        (notes ?? "").nilIfBlank == nil &&
        measurements?.isEffectivelyEmpty != false
    }
}

private extension Drainage {
    var isEffectivelyEmpty: Bool {
        gutters == nil &&
        (downspoutLocations ?? "").nilIfBlank == nil &&
        drainTieIn == nil &&
        (slopeNotes ?? "").nilIfBlank == nil &&
        measurements?.isEffectivelyEmpty != false
    }
}

private extension DocumentsSection {
    var isEffectivelyEmpty: Bool {
        irrigation == nil &&
        propertySurvey == nil &&
        (additionalAttachments ?? []).isEmpty
    }
}

private extension Finishes {
    var isEffectivelyEmpty: Bool {
        (trimType ?? "").nilIfBlank == nil &&
        (paintOrPowderColor ?? "").nilIfBlank == nil &&
        sidingReplacementRequired == nil &&
        (caulkingSealingNotes ?? "").nilIfBlank == nil &&
        measurements?.isEffectivelyEmpty != false
    }
}

private extension PermitsHOA {
    var isEffectivelyEmpty: Bool {
        permitRequired == nil &&
        (jurisdiction ?? "").nilIfBlank == nil &&
        hoaApprovalRequired == nil &&
        engineeringRequired == nil &&
        (statusNotes ?? "").nilIfBlank == nil
    }
}

private func emptyCustomerApproval() -> CustomerApproval {
    CustomerApproval(
        optionsConfirmedText: nil,
        signaturePNGPath: nil,
        signedDate: nil
    )
}
