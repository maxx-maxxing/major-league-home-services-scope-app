
import SwiftUI
import SwiftData

struct ProjectInfoEditorView: View {
    @Bindable var scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    var body: some View {
        VStack(spacing: 16) {
            CardGroup(title: "Client") {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        RequiredLabel(text: "Client Name")
                        TextField("Enter client name", text: requiredStringBinding(\.clientName))
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        RequiredLabel(text: "Address")
                        TextField("Street address", text: requiredStringBinding(\.address))
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("City")
                                .font(.body)
                            TextField("City", text: optionalStringBinding(\.city))
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("ZIP")
                                .font(.body)
                            TextField("ZIP", text: optionalStringBinding(\.zip))
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)
                                .keyboardType(.numberPad)
                        }
                    }
                }
            }

            CardGroup(title: "Contact") {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone")
                            .font(.body)
                        TextField("Phone", text: optionalStringBinding(\.phone))
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
                            .keyboardType(.phonePad)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.body)
                        TextField("Email", text: optionalStringBinding(\.email))
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Salesperson")
                            .font(.body)
                        TextField("Salesperson", text: optionalStringBinding(\.salesperson))
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Estimator")
                            .font(.body)
                        TextField("Estimator", text: optionalStringBinding(\.estimator))
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
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
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.body)
                        TextEditor(text: notesBinding)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }

    private var projectTypeBinding: Binding<ProjectType> {
        Binding(
            get: { scope.projectInfo.projectType },
            set: { newValue in
                updateProjectInfo { $0.projectType = newValue }
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

struct EnclosureEditorView: View {
    @Bindable var scope: JobScope
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
                            Text("Not Set").tag(nil as StandardColorOption?)
                            ForEach(StandardColorOption.allCases, id: \.self) { color in
                                Text(color.displayName).tag(Optional(color))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                        if scope.enclosure?.screenFrameColor == .custom {
                            TextField("Custom screen frame color", text: screenFrameColorCustomBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)
                        }
                    }
                }
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

                        if scope.enclosure?.kneeWall?.option != .none {
                            TextField("Panel height", text: kneeWallPanelHeightBinding)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(minHeight: 44)

                            TextField("Panel color", text: kneeWallPanelColorBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)

                            TextField("Trim color", text: kneeWallTrimColorBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)

                            TextField("Interior finish", text: kneeWallInteriorFinishBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)
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

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Door Notes")
                                .font(.body)
                            TextEditor(text: doorNotesBinding)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var showsScreenOptions: Bool {
        switch scope.enclosure?.enclosureType {
        case .screenOnly, .screenRoomWithDoor, .mixed:
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

    private var screenFrameColorBinding: Binding<StandardColorOption?> {
        Binding(
            get: { scope.enclosure?.screenFrameColor },
            set: { newValue in
                updateEnclosure { enclosure in
                    enclosure.screenFrameColor = newValue
                    if newValue != .custom {
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
                        kneeWall.trimColor = nil
                        kneeWall.interiorFinish = nil
                    }
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallPanelHeightBinding: Binding<String> {
        Binding(
            get: { formatOptionalDouble(scope.enclosure?.kneeWall?.panelHeight) },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.panelHeight = parseOptionalDouble(newValue)
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

    private var kneeWallTrimColorBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.kneeWall?.trimColor ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.trimColor = newValue.nilIfBlank
                    enclosure.kneeWall = kneeWall
                }
            }
        )
    }

    private var kneeWallInteriorFinishBinding: Binding<String> {
        Binding(
            get: { scope.enclosure?.kneeWall?.interiorFinish ?? "" },
            set: { newValue in
                updateEnclosure { enclosure in
                    var kneeWall = enclosure.kneeWall ?? emptyKneeWall()
                    kneeWall.interiorFinish = newValue.nilIfBlank
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
        scope.enclosure = enclosure
        autosave.scheduleSave(for: scope)
    }

    private func isScreenType(_ value: EnclosureType?) -> Bool {
        switch value {
        case .screenOnly, .screenRoomWithDoor, .mixed:
            return true
        default:
            return false
        }
    }
}

struct WindowsAndGlassEditorView: View {
    @Bindable var scope: JobScope
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

                        FieldHeader("Frame System")
                        Picker("Frame System", selection: frameSystemBinding) {
                            Text("Not Set").tag(nil as WindowFrameSystem?)
                            ForEach(WindowFrameSystem.allCases, id: \.self) { frame in
                                Text(frame.displayName).tag(Optional(frame))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
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

                        if scope.enclosure?.windowSystem?.color == .custom {
                            TextField("Custom frame color", text: frameColorCustomBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(minHeight: 44)
                        }

                        TextField("Window Height", text: windowHeightBinding)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(minHeight: 44)

                        TextField("Number of Bays", text: numBaysBinding)
                            .textFieldStyle(.roundedBorder)
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
            }
        }
        .onAppear {
            isWindowSystemEnabled = scope.enclosure?.windowSystem != nil
        }
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
                    if newValue != .custom {
                        windowSystem.colorCustom = nil
                    }
                }
            }
        )
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
            enclosure.windowSystem = windowSystem
        }
    }
}

struct AttachmentConditionsEditorView: View {
    @Bindable var scope: JobScope
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
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 44)
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
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
                    }

                    TextField("Post size", text: postSizeBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 44)

                    TextField("Post spacing", text: postSpacingBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 44)

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

                        if scope.attachment?.trimMaterial == .other {
                            TextField("Describe trim material", text: trimMaterialOtherBinding)
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)
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

                        if scope.attachment?.trimThickness == .custom {
                            TextField("Custom trim thickness", text: trimThicknessCustomBinding)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(minHeight: 44)
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
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
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
                    if newValue != .custom {
                        attachment.trimThicknessCustom = nil
                    }
                }
            }
        )
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

struct ProductionNotesEditorView: View {
    @Bindable var scope: JobScope
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
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 44)
                }
            }

            CardGroup(title: "Production Schedule") {
                VStack(spacing: 12) {
                    Toggle("Track Production Metadata", isOn: includeProductionMetaBinding)
                        .frame(minHeight: 44)

                    if scope.production != nil {
                        Toggle("Include Start Date", isOn: includeStartDateBinding)
                            .frame(minHeight: 44)

                        if scope.production?.startDate != nil {
                            DatePicker(
                                "Start Date",
                                selection: productionStartDateBinding,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }

                        TextField("Crew lead", text: crewLeadBinding)
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)

                        TextField("Duration estimate", text: durationEstimateBinding)
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 44)

                        Picker("Material Order", selection: materialOrderStatusBinding) {
                            ForEach(MaterialOrderStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Permit Status", selection: permitStatusBinding) {
                            ForEach(PermitStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
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
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
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
                scope.production = newValue ? (scope.production ?? emptyProductionOrderMeta()) : nil
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

private struct FieldHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
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
        configuration: nil
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

private func emptyKneeWall() -> KneeWall {
    KneeWall(
        option: KneeWallOption.none,
        panelHeight: nil,
        panelColor: nil,
        trimColor: nil,
        interiorFinish: nil
    )
}

private func emptyDoorOptions() -> DoorOptions {
    DoorOptions(doorType: DoorType.none, notes: nil)
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

private func emptyProductionOrderMeta() -> ProductionOrderMeta {
    ProductionOrderMeta(
        startDate: nil,
        crewLead: nil,
        durationEstimate: nil,
        materialOrderStatus: nil,
        permitStatus: nil
    )
}

private func emptyCustomerApproval() -> CustomerApproval {
    CustomerApproval(
        optionsConfirmedText: nil,
        signaturePNGPath: nil,
        signedDate: nil
    )
}

