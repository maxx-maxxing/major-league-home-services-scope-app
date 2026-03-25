
import SwiftUI
import SwiftData
import PencilKit

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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Scope Title")
                            .font(.body)
                        TextField("Enter scope title", text: scopeTitleBinding)
                            .liquidGlassInput()
                    }

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

                                Text("Verified JobTread-owned customer fields below are read-only and refresh from JobTread. Phone and email remain local editable fields for now.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let fetchedAt = scope.jobTreadCustomer?.fetchedAt {
                                    Text("Last synced \(fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 12)

                            if let refreshLinkedCustomer {
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
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            RequiredLabel(text: "Customer Name")
                            TextField("Enter customer name", text: requiredStringBinding(\.clientName))
                                .liquidGlassInput()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            RequiredLabel(text: "Address")
                            TextField("Street address", text: requiredStringBinding(\.address))
                                .liquidGlassInput()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Unit Number")
                                .font(.body)
                            TextField("Apartment, suite, etc.", text: optionalStringBinding(\.unitNumber))
                                .liquidGlassInput()
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("City")
                                    .font(.body)
                                TextField("City", text: optionalStringBinding(\.city))
                                    .liquidGlassInput()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("State")
                                    .font(.body)
                                TextField("State", text: optionalStringBinding(\.state))
                                    .liquidGlassInput()
                                    .textInputAutocapitalization(.characters)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("ZIP")
                                    .font(.body)
                                TextField("ZIP", text: optionalStringBinding(\.zip))
                                    .liquidGlassInput()
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                }
            }

            CardGroup(title: hasLinkedCustomer ? "Contact (Local)" : "Contact") {
                VStack(spacing: 12) {
                    if hasLinkedCustomer {
                        Text("Phone and email stay editable locally until their JobTread ownership path is verified.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone")
                            .font(.body)
                        TextField("Phone", text: optionalStringBinding(\.phone))
                            .liquidGlassInput()
                            .keyboardType(.phonePad)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.body)
                        TextField("Email", text: optionalStringBinding(\.email))
                            .liquidGlassInput()
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Salesperson")
                            .font(.body)
                        TextField("Salesperson", text: optionalStringBinding(\.salesperson))
                            .liquidGlassInput()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Estimator")
                            .font(.body)
                        TextField("Estimator", text: optionalStringBinding(\.estimator))
                            .liquidGlassInput()
                    }
                }
            }

            CardGroup(title: "Project") {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project Type")
                            .font(.body)

                        Picker("Project Type", selection: projectTypeBinding) {
                            ForEach(ProjectType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
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

    private var projectTypeBinding: Binding<ProjectType> {
        Binding(
            get: { scope.projectInfo.projectType },
            set: { newValue in
                updateProjectInfo { $0.projectType = newValue }
            }
        )
    }

    private var scopeTitleBinding: Binding<String> {
        Binding(
            get: { scope.resolvedScopeTitle ?? "" },
            set: { newValue in
                scope.setLocalScopeTitle(newValue)
                autosave.scheduleSave(for: scope)
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.projectInfo.notes ?? "" },
            set: { newValue in
                updateProjectInfo { $0.notes = newValue.nilIfBlank }
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

struct ExistingConditionsEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Site Snapshot") {
                VStack(spacing: 12) {
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
                    Picker("Exterior Finish", selection: exteriorFinishBinding) {
                        Text("Not Set").tag(nil as ExteriorFinish?)
                        ForEach(ExteriorFinish.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    FieldHeader("Existing Structure")
                    Picker("Existing Structure", selection: existingStructureBinding) {
                        Text("Not Set").tag(nil as ExistingStructure?)
                        ForEach(ExistingStructure.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mark the reference photos that should be captured on site.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    OptionalBoolPicker(title: "Front of House", selection: photoChecklistBinding(\.frontOfHouse))
                    OptionalBoolPicker(title: "Rear Elevation", selection: photoChecklistBinding(\.rearElevation))
                    OptionalBoolPicker(title: "Roof Line", selection: photoChecklistBinding(\.roofLine))
                    OptionalBoolPicker(title: "Electrical Panel", selection: photoChecklistBinding(\.electricalPanel))
                    OptionalBoolPicker(title: "Work Area", selection: photoChecklistBinding(\.workArea))
                }
            }
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

    private var exteriorFinishBinding: Binding<ExteriorFinish?> {
        Binding(
            get: { scope.existingConditions?.exteriorFinish },
            set: { newValue in
                updateExistingConditions { $0.exteriorFinish = newValue }
            }
        )
    }

    private var existingStructureBinding: Binding<ExistingStructure?> {
        Binding(
            get: { scope.existingConditions?.existingStructure },
            set: { newValue in
                updateExistingConditions { $0.existingStructure = newValue }
            }
        )
    }

    private var obstaclesNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.obstaclesNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.obstaclesNotes = newValue.nilIfBlank }
            }
        )
    }

    private var utilitiesNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.utilitiesNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.utilitiesNotes = newValue.nilIfBlank }
            }
        )
    }

    private var hoaNotesBinding: Binding<String> {
        Binding(
            get: { scope.existingConditions?.hoaNotes ?? "" },
            set: { newValue in
                updateExistingConditions { $0.hoaNotes = newValue.nilIfBlank }
            }
        )
    }

    private func photoChecklistBinding(_ keyPath: WritableKeyPath<PhotoChecklist, Bool?>) -> Binding<Bool?> {
        Binding(
            get: { scope.existingConditions?.photoChecklist.map { $0[keyPath: keyPath] } ?? nil },
            set: { newValue in
                updateExistingConditions { conditions in
                    var checklist = conditions.photoChecklist ?? emptyPhotoChecklist()
                    checklist[keyPath: keyPath] = newValue
                    conditions.photoChecklist = checklist.isEffectivelyEmpty ? nil : checklist
                }
            }
        )
    }

    private func updateExistingConditions(_ update: (inout ExistingConditions) -> Void) {
        var conditions = scope.existingConditions ?? emptyExistingConditions()
        update(&conditions)
        scope.existingConditions = conditions.isEffectivelyEmpty ? nil : conditions
        autosave.scheduleSave(for: scope)
    }
}

struct DimensionsEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Measurements") {
                VStack(spacing: 12) {
                    MeasurementTextField(title: "Width", text: widthBinding)
                    MeasurementTextField(title: "Projection", text: projectionBinding)
                    MeasurementTextField(title: "Fascia Height", text: fasciaHeightBinding)
                    MeasurementTextField(title: "Beam Height", text: beamHeightBinding)
                }
            }

            CardGroup(title: "Configuration") {
                VStack(spacing: 12) {
                    FieldHeader("Roof Style")
                    Picker("Roof Style", selection: roofStyleBinding) {
                        Text("Not Set").tag(nil as RoofStyle?)
                        ForEach(RoofStyle.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    FieldHeader("Attachment Type")
                    Picker("Attachment Type", selection: attachmentTypeBinding) {
                        Text("Not Set").tag(nil as DimensionsAttachmentType?)
                        ForEach(DimensionsAttachmentType.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
            }

            CardGroup(title: "Elevation Notes") {
                NotesField(title: "Elevation Notes", text: elevationNotesBinding, minHeight: 140, showInlineTitle: false)
            }
        }
    }

    private var widthBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.dimensions?.width) },
            set: { newValue in
                updateDimensions { $0.width = parseOptionalDouble(newValue) }
            }
        )
    }

    private var projectionBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.dimensions?.projection) },
            set: { newValue in
                updateDimensions { $0.projection = parseOptionalDouble(newValue) }
            }
        )
    }

    private var fasciaHeightBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.dimensions?.fasciaHeight) },
            set: { newValue in
                updateDimensions { $0.fasciaHeight = parseOptionalDouble(newValue) }
            }
        )
    }

    private var beamHeightBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.dimensions?.beamHeight) },
            set: { newValue in
                updateDimensions { $0.beamHeight = parseOptionalDouble(newValue) }
            }
        )
    }

    private var roofStyleBinding: Binding<RoofStyle?> {
        Binding(
            get: { scope.dimensions?.roofStyle },
            set: { newValue in
                updateDimensions { $0.roofStyle = newValue }
            }
        )
    }

    private var attachmentTypeBinding: Binding<DimensionsAttachmentType?> {
        Binding(
            get: { scope.dimensions?.attachmentType },
            set: { newValue in
                updateDimensions { $0.attachmentType = newValue }
            }
        )
    }

    private var elevationNotesBinding: Binding<String> {
        Binding(
            get: { scope.dimensions?.elevationNotes ?? "" },
            set: { newValue in
                updateDimensions { $0.elevationNotes = newValue.nilIfBlank }
            }
        )
    }

    private func updateDimensions(_ update: (inout Dimensions) -> Void) {
        var dimensions = scope.dimensions ?? emptyDimensions()
        update(&dimensions)
        scope.dimensions = dimensions.isEffectivelyEmpty ? nil : dimensions
        autosave.scheduleSave(for: scope)
    }
}

struct StructuralSystemEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Structure") {
                VStack(spacing: 12) {
                    FieldHeader("Frame Material")
                    Picker("Frame Material", selection: frameMaterialBinding) {
                        Text("Not Set").tag(nil as FrameMaterial?)
                        ForEach(FrameMaterial.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    TextField("Post size", text: postSizeBinding)
                        .liquidGlassInput()

                    TextField("Beam type", text: beamTypeBinding)
                        .liquidGlassInput()
                }
            }

            CardGroup(title: "Roof + Finish") {
                VStack(spacing: 12) {
                    FieldHeader("Roof System")
                    Picker("Roof System", selection: roofSystemBinding) {
                        Text("Not Set").tag(nil as RoofSystem?)
                        ForEach(RoofSystem.allCases, id: \.self) { value in
                            Text(value.displayName).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    TextField("Roof color", text: roofColorBinding)
                        .liquidGlassInput()

                    TextField("Frame color", text: frameColorBinding)
                        .liquidGlassInput()
                }
            }

            CardGroup(title: "Structural Notes") {
                NotesField(title: "Structural Notes", text: notesBinding, minHeight: 140, showInlineTitle: false)
            }
        }
    }

    private var frameMaterialBinding: Binding<FrameMaterial?> {
        Binding(
            get: { scope.structuralSystem?.frameMaterial },
            set: { newValue in
                updateStructuralSystem { $0.frameMaterial = newValue }
            }
        )
    }

    private var postSizeBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.postSize ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.postSize = newValue.nilIfBlank }
            }
        )
    }

    private var beamTypeBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.beamType ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.beamType = newValue.nilIfBlank }
            }
        )
    }

    private var roofSystemBinding: Binding<RoofSystem?> {
        Binding(
            get: { scope.structuralSystem?.roofSystem },
            set: { newValue in
                updateStructuralSystem { $0.roofSystem = newValue }
            }
        )
    }

    private var roofColorBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.roofColor ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.roofColor = newValue.nilIfBlank }
            }
        )
    }

    private var frameColorBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.frameColor ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.frameColor = newValue.nilIfBlank }
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.structuralSystem?.notes ?? "" },
            set: { newValue in
                updateStructuralSystem { $0.notes = newValue.nilIfBlank }
            }
        )
    }

    private func updateStructuralSystem(_ update: (inout StructuralSystem) -> Void) {
        var structuralSystem = scope.structuralSystem ?? emptyStructuralSystem()
        update(&structuralSystem)
        scope.structuralSystem = structuralSystem.isEffectivelyEmpty ? nil : structuralSystem
        autosave.scheduleSave(for: scope)
    }
}

struct EnclosureEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Enclosure Type") {
                FieldHeader("Type")
                Picker("Type", selection: enclosureTypeBinding) {
                    Text("Not Set").tag(nil as EnclosureType?)
                    ForEach(EnclosureType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(Optional(type))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            if showsScreenOptions {
                CardGroup(title: "Screen Options") {
                    VStack(spacing: 12) {
                        FieldHeader("Screen Wall Type")
                        Picker("Screen Wall Type", selection: screenWallTypeBinding) {
                            Text("Not Set").tag(nil as ScreenWallType?)
                            ForEach(ScreenWallType.allCases, id: \.self) { option in
                                Text(option.displayName).tag(Optional(option))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        FieldHeader("Screen Frame Color")
                        Picker("Screen Frame Color", selection: screenFrameColorBinding) {
                            Text("Not Set").tag(nil as ScreenFrameColorOption?)
                            ForEach(ScreenFrameColorOption.allCases, id: \.self) { color in
                                Text(color.displayName).tag(Optional(color))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if showsCustomScreenFrameColorField {
                            TextField("Custom or other screen frame color", text: screenFrameColorCustomBinding)
                                .liquidGlassInput()
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

                                TextField("Panel color", text: kneeWallPanelColorBinding)
                                    .liquidGlassInput()
                                    .formRevealTransition()

                                TextField("Linear footage", text: kneeWallLinearFootageBinding)
                                    .liquidGlassInput()
                                    .formRevealTransition()
                            }

                            if showsFramedKneeWallFields {
                                TextField("Height", text: kneeWallHeightBinding)
                                    .liquidGlassInput()
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
                            TextField("Width", text: doorWidthBinding)
                                .liquidGlassInput()
                                .formRevealTransition()

                            TextField("Height", text: doorHeightBinding)
                                .liquidGlassInput()
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

                            TextField("Color", text: doorColorBinding)
                                .liquidGlassInput()
                                .formRevealTransition()

                            TextField("Dimensions", text: doorDimensionsBinding)
                                .liquidGlassInput()
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
    }

    private var showsScreenOptions: Bool {
        switch scope.enclosure?.enclosureType {
        case .screenEnclosure, .mixed:
            return true
        default:
            return false
        }
    }

    private var showsCustomScreenFrameColorField: Bool {
        switch scope.enclosure?.screenFrameColor {
        case .other:
            return true
        default:
            return false
        }
    }

    private var enclosureTypeBinding: Binding<EnclosureType?> {
        Binding(
            get: { scope.enclosure?.enclosureType },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.enclosureType = newValue
                    if !isScreenType(newValue) {
                        enclosure.screenWallType = nil
                        enclosure.screenFrameColor = nil
                        enclosure.screenFrameColorCustom = nil
                    }
                }
            }
        )
    }

    private var screenWallTypeBinding: Binding<ScreenWallType?> {
        Binding(
            get: { scope.enclosure?.screenWallType },
            set: { newValue in
                updateEnclosure { $0.screenWallType = newValue }
            }
        )
    }

    private var screenFrameColorBinding: Binding<ScreenFrameColorOption?> {
        Binding(
            get: { scope.enclosure?.screenFrameColor },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.screenFrameColor = newValue
                    if newValue != .other {
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
                updateEnclosure { $0.screenFrameColorCustom = newValue.nilIfBlank }
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
                    kneeWall.panelColor = newValue.nilIfBlank
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
                    doors.color = newValue.nilIfBlank
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
                    doors.dimensions = newValue.nilIfBlank
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
                    doors.notes = newValue.nilIfBlank
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

    private func isScreenType(_ value: EnclosureType?) -> Bool {
        switch value {
        case .screenEnclosure, .mixed:
            return true
        default:
            return false
        }
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
                            TextField("Custom or other frame color", text: frameColorCustomBinding)
                                .liquidGlassInput()
                                .formRevealTransition()
                        }

                        TextField("Window Height", text: windowHeightBinding)
                            .liquidGlassInput()
                            .keyboardType(.decimalPad)
                            .frame(minHeight: 44)

                        TextField("Number of Bays", text: numBaysBinding)
                            .liquidGlassInput()
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
                updateWindowSystem { $0.colorCustom = newValue.nilIfBlank }
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
                updateWindowSystem { $0.notes = newValue.nilIfBlank }
            }
        )
    }

    private func updateEnclosure(_ update: (inout Enclosure) -> Void) {
        var enclosure = scope.enclosure ?? emptyEnclosure()
        update(&enclosure)
        scope.enclosure = enclosure.isEffectivelyEmpty ? nil : enclosure
        autosave.scheduleSave(for: scope)
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

                    TextField("Switch locations", text: switchLocationsBinding)
                        .liquidGlassInput()
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
                updateElectrical { $0.switchLocations = newValue.nilIfBlank }
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { scope.electrical?.notes ?? "" },
            set: { newValue in
                updateElectrical { $0.notes = newValue.nilIfBlank }
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
}

struct DrainageEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Drainage Setup") {
                VStack(spacing: 12) {
                    OptionalBoolPicker(title: "Include Gutters", selection: guttersBinding)

                    TextField("Downspout locations", text: downspoutLocationsBinding)
                        .liquidGlassInput()

                    OptionalBoolPicker(title: "Drain Tie-In", selection: drainTieInBinding)
                }
            }

            CardGroup(title: "Slope Notes") {
                NotesField(title: "Slope Notes", text: slopeNotesBinding, minHeight: 140, showInlineTitle: false)
            }
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
                updateDrainage { $0.downspoutLocations = newValue.nilIfBlank }
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
                updateDrainage { $0.slopeNotes = newValue.nilIfBlank }
            }
        )
    }

    private func updateDrainage(_ update: (inout Drainage) -> Void) {
        var drainage = scope.drainage ?? emptyDrainage()
        update(&drainage)
        scope.drainage = drainage.isEffectivelyEmpty ? nil : drainage
        autosave.scheduleSave(for: scope)
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
                        TextField("Describe wall material", text: houseWallOtherBinding)
                            .liquidGlassInput()
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
                        TextField("Describe post/column material", text: postMaterialOtherBinding)
                            .liquidGlassInput()
                            .formRevealTransition()
                    }

                    TextField("Post size", text: postSizeBinding)
                        .liquidGlassInput()

                    TextField("Post spacing", text: postSpacingBinding)
                        .liquidGlassInput()

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
                            TextField("Describe trim material", text: trimMaterialOtherBinding)
                                .liquidGlassInput()
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
                            TextField("Custom or other trim thickness", text: trimThicknessCustomBinding)
                                .liquidGlassInput()
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
                updateAttachment { $0.houseWallOther = newValue.nilIfBlank }
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
                updateAttachment { $0.postColumnOther = newValue.nilIfBlank }
            }
        )
    }

    private var postSizeBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.postSize ?? "" },
            set: { newValue in
                updateAttachment { $0.postSize = newValue.nilIfBlank }
            }
        )
    }

    private var postSpacingBinding: Binding<String> {
        Binding(
            get: { scope.attachment?.postSpacing ?? "" },
            set: { newValue in
                updateAttachment { $0.postSpacing = newValue.nilIfBlank }
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
                updateAttachment { $0.trimMaterialOther = newValue.nilIfBlank }
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
                updateAttachment { $0.notes = newValue.nilIfBlank }
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
}

struct FinishesEditorView: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Trim + Color") {
                VStack(spacing: 12) {
                    TextField("Trim type", text: trimTypeBinding)
                        .liquidGlassInput()

                    TextField("Paint or powder color", text: paintOrPowderColorBinding)
                        .liquidGlassInput()

                    OptionalBoolPicker(title: "Siding Replacement Required", selection: sidingReplacementRequiredBinding)
                }
            }

            CardGroup(title: "Sealant Notes") {
                NotesField(title: "Caulking and Sealing Notes", text: caulkingSealingNotesBinding, minHeight: 140, showInlineTitle: false)
            }
        }
    }

    private var trimTypeBinding: Binding<String> {
        Binding(
            get: { scope.finishes?.trimType ?? "" },
            set: { newValue in
                updateFinishes { $0.trimType = newValue.nilIfBlank }
            }
        )
    }

    private var paintOrPowderColorBinding: Binding<String> {
        Binding(
            get: { scope.finishes?.paintOrPowderColor ?? "" },
            set: { newValue in
                updateFinishes { $0.paintOrPowderColor = newValue.nilIfBlank }
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
                updateFinishes { $0.caulkingSealingNotes = newValue.nilIfBlank }
            }
        )
    }

    private func updateFinishes(_ update: (inout Finishes) -> Void) {
        var finishes = scope.finishes ?? emptyFinishes()
        update(&finishes)
        scope.finishes = finishes.isEffectivelyEmpty ? nil : finishes
        autosave.scheduleSave(for: scope)
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

                    TextField("Jurisdiction", text: jurisdictionBinding)
                        .liquidGlassInput()
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
                updatePermitsHOA { $0.jurisdiction = newValue.nilIfBlank }
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
                updatePermitsHOA { $0.statusNotes = newValue.nilIfBlank }
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

                    TextField("Job number", text: jobNumberBinding)
                        .liquidGlassInput()
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

                        TextField("Crew lead", text: crewLeadBinding)
                            .liquidGlassInput()
                            .formRevealTransition()

                        TextField("Duration estimate", text: durationEstimateBinding)
                            .liquidGlassInput()
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
                updateProduction { $0.crewLead = newValue.nilIfBlank }
            }
        )
    }

    private var durationEstimateBinding: Binding<String> {
        Binding(
            get: { scope.production?.durationEstimate ?? "" },
            set: { newValue in
                updateProduction { $0.durationEstimate = newValue.nilIfBlank }
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
                updateCustomerApproval { $0.optionsConfirmedText = newValue.nilIfBlank }
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

        salespersonSignatureDrawing = DrawingAssetStore.drawing(
            for: scope.sketches?.first(where: { $0.title == salespersonSketchTitle })?.drawingDataPath
        )
        siteDiagramDrawing = DrawingAssetStore.drawing(
            for: scope.sketches?.first(where: { $0.title == siteDiagramSketchTitle })?.drawingDataPath
        )

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
            assertionFailure("Failed to save customer signature: \(error)")
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
            assertionFailure("Failed to save sketch \(title): \(error)")
        }
    }

    private func upsertSketch(title: String, drawingPath: String, previewPath: String) {
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
        autosave.scheduleSave(for: scope)
    }

    private func removeSketch(title: String) {
        guard var sketches = scope.sketches else { return }

        sketches.removeAll(where: { $0.title == title })
        scope.sketches = sketches.isEmpty ? nil : sketches
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
        TextField(title, text: $text)
            .liquidGlassInput()
            .keyboardType(.decimalPad)
    }
}

private struct NotesField: View {
    let title: String
    @Binding var text: String
    let minHeight: CGFloat
    let showInlineTitle: Bool

    init(title: String, text: Binding<String>, minHeight: CGFloat, showInlineTitle: Bool = true) {
        self.title = title
        self._text = text
        self.minHeight = minHeight
        self.showInlineTitle = showInlineTitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showInlineTitle {
                FieldHeader(title)
            }

            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .padding(8)
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

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
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
        enclosureType: nil,
        screenWallType: nil,
        screenFrameColor: nil,
        screenFrameColorCustom: nil,
        windowSystem: nil,
        kneeWall: nil,
        doors: nil
    )
}

private func emptyExistingConditions() -> ExistingConditions {
    ExistingConditions(
        houseStories: nil,
        exteriorFinish: nil,
        existingStructure: nil,
        obstaclesNotes: nil,
        utilitiesNotes: nil,
        hoaNotes: nil,
        photoChecklist: nil
    )
}

private func emptyPhotoChecklist() -> PhotoChecklist {
    PhotoChecklist(
        frontOfHouse: nil,
        rearElevation: nil,
        roofLine: nil,
        electricalPanel: nil,
        workArea: nil
    )
}

private func emptyDimensions() -> Dimensions {
    Dimensions(
        width: nil,
        projection: nil,
        fasciaHeight: nil,
        beamHeight: nil,
        roofStyle: nil,
        attachmentType: nil,
        elevationNotes: nil
    )
}

private func emptyStructuralSystem() -> StructuralSystem {
    StructuralSystem(
        frameMaterial: nil,
        postSize: nil,
        beamType: nil,
        roofSystem: nil,
        roofColor: nil,
        frameColor: nil,
        notes: nil
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
        notes: nil
    )
}

private func emptyDrainage() -> Drainage {
    Drainage(
        gutters: nil,
        downspoutLocations: nil,
        drainTieIn: nil,
        slopeNotes: nil
    )
}

private extension Enclosure {
    var isEffectivelyEmpty: Bool {
        enclosureType == nil &&
        screenWallType == nil &&
        screenFrameColor == nil &&
        (screenFrameColorCustom ?? "").nilIfBlank == nil &&
        windowSystem == nil &&
        kneeWall == nil &&
        doors == nil
    }
}

private extension ExistingConditions {
    var isEffectivelyEmpty: Bool {
        houseStories == nil &&
        exteriorFinish == nil &&
        existingStructure == nil &&
        (obstaclesNotes ?? "").nilIfBlank == nil &&
        (utilitiesNotes ?? "").nilIfBlank == nil &&
        (hoaNotes ?? "").nilIfBlank == nil &&
        photoChecklist == nil
    }
}

private extension PhotoChecklist {
    var isEffectivelyEmpty: Bool {
        frontOfHouse == nil &&
        rearElevation == nil &&
        roofLine == nil &&
        electricalPanel == nil &&
        workArea == nil
    }
}

private extension Dimensions {
    var isEffectivelyEmpty: Bool {
        width == nil &&
        projection == nil &&
        fasciaHeight == nil &&
        beamHeight == nil &&
        roofStyle == nil &&
        attachmentType == nil &&
        (elevationNotes ?? "").nilIfBlank == nil
    }
}

private extension StructuralSystem {
    var isEffectivelyEmpty: Bool {
        frameMaterial == nil &&
        (postSize ?? "").nilIfBlank == nil &&
        (beamType ?? "").nilIfBlank == nil &&
        roofSystem == nil &&
        (roofColor ?? "").nilIfBlank == nil &&
        (frameColor ?? "").nilIfBlank == nil &&
        (notes ?? "").nilIfBlank == nil
    }
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
        notes: nil
    )
}

private func emptyFinishes() -> Finishes {
    Finishes(
        trimType: nil,
        paintOrPowderColor: nil,
        sidingReplacementRequired: nil,
        caulkingSealingNotes: nil
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
        (notes ?? "").nilIfBlank == nil
    }
}

private extension Drainage {
    var isEffectivelyEmpty: Bool {
        gutters == nil &&
        (downspoutLocations ?? "").nilIfBlank == nil &&
        drainTieIn == nil &&
        (slopeNotes ?? "").nilIfBlank == nil
    }
}

private extension Finishes {
    var isEffectivelyEmpty: Bool {
        (trimType ?? "").nilIfBlank == nil &&
        (paintOrPowderColor ?? "").nilIfBlank == nil &&
        sidingReplacementRequired == nil &&
        (caulkingSealingNotes ?? "").nilIfBlank == nil
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
