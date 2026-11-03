import Foundation

/// A portable snapshot, separate from SwiftData's persisted representation.
/// Keep this inventory in step with every stored JobScope property. Archive
/// versioning belongs to the archive envelope, rather than the live schema.
struct ScopeBackupRecord: Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var lastOpenedAt: Date?
    var updatedAt: Date
    var status: JobStatus
    var jobNumber: String?
    var scopeTitle: String?
    var jobTreadCustomer: JobTreadCustomerRef?
    var jobTreadJob: JobTreadJobRef?
    var jobTreadSync: JobTreadSyncMetadata?
    var projectInfo: ProjectInfo
    var existingConditions: ExistingConditions?
    var dimensions: Dimensions?
    var structuralSystem: StructuralSystem?
    var enclosure: Enclosure?
    var electrical: Electrical?
    var drainage: Drainage?
    var attachment: AttachmentConditions?
    var documentsPayload: Data?
    var finishes: Finishes?
    var permitsHOA: PermitsHOA?
    var production: ProductionOrderMeta?
    var customerApproval: CustomerApproval?
    var photos: [PhotoAttachment]?
    var sketches: [SketchAttachment]?
    var voiceNotes: [ScopeVoiceNote]?
    var aiExtractionDrafts: [ScopeAIExtractionDraft]?
    var reviewState: [String: Date]

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case lastOpenedAt
        case updatedAt
        case status
        case jobNumber
        case scopeTitle
        case jobTreadCustomer
        case jobTreadJob
        case jobTreadSync
        case projectInfo
        case existingConditions
        case dimensions
        case structuralSystem
        case enclosure
        case electrical
        case drainage
        case attachment
        case documentsPayload
        case finishes
        case permitsHOA
        case production
        case customerApproval
        case photos
        case sketches
        case voiceNotes
        case aiExtractionDrafts
        case reviewState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        status = try container.decode(JobStatus.self, forKey: .status)
        jobNumber = try container.decodeIfPresent(String.self, forKey: .jobNumber)
        scopeTitle = try container.decodeIfPresent(String.self, forKey: .scopeTitle)
        jobTreadCustomer = try container.decodeIfPresent(JobTreadCustomerRef.self, forKey: .jobTreadCustomer)
        jobTreadJob = try container.decodeIfPresent(JobTreadJobRef.self, forKey: .jobTreadJob)
        jobTreadSync = try container.decodeIfPresent(JobTreadSyncMetadata.self, forKey: .jobTreadSync)
        projectInfo = try container.decode(ScopeBackupProjectInfo.self, forKey: .projectInfo).modelValue()
        existingConditions = try container.decodeIfPresent(ScopeBackupExistingConditions.self, forKey: .existingConditions)?.modelValue()
        dimensions = try container.decodeIfPresent(Dimensions.self, forKey: .dimensions)
        structuralSystem = try container.decodeIfPresent(ScopeBackupStructuralSystem.self, forKey: .structuralSystem)?.modelValue()
        enclosure = try container.decodeIfPresent(ScopeBackupEnclosure.self, forKey: .enclosure)?.modelValue()
        electrical = try container.decodeIfPresent(Electrical.self, forKey: .electrical)
        drainage = try container.decodeIfPresent(Drainage.self, forKey: .drainage)
        attachment = try container.decodeIfPresent(AttachmentConditions.self, forKey: .attachment)
        documentsPayload = try container.decodeIfPresent(Data.self, forKey: .documentsPayload)
        finishes = try container.decodeIfPresent(Finishes.self, forKey: .finishes)
        permitsHOA = try container.decodeIfPresent(PermitsHOA.self, forKey: .permitsHOA)
        production = try container.decodeIfPresent(ProductionOrderMeta.self, forKey: .production)
        customerApproval = try container.decodeIfPresent(CustomerApproval.self, forKey: .customerApproval)
        photos = try container.decodeIfPresent([PhotoAttachment].self, forKey: .photos)
        sketches = try container.decodeIfPresent([SketchAttachment].self, forKey: .sketches)
        voiceNotes = try container.decodeIfPresent([ScopeVoiceNote].self, forKey: .voiceNotes)
        aiExtractionDrafts = try container.decodeIfPresent([ScopeAIExtractionDraft].self, forKey: .aiExtractionDrafts)
        reviewState = try container.decode([String: Date].self, forKey: .reviewState)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastOpenedAt, forKey: .lastOpenedAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(jobNumber, forKey: .jobNumber)
        try container.encodeIfPresent(scopeTitle, forKey: .scopeTitle)
        try container.encodeIfPresent(jobTreadCustomer, forKey: .jobTreadCustomer)
        try container.encodeIfPresent(jobTreadJob, forKey: .jobTreadJob)
        try container.encodeIfPresent(jobTreadSync, forKey: .jobTreadSync)
        try container.encode(ScopeBackupProjectInfo(projectInfo), forKey: .projectInfo)
        try container.encodeIfPresent(existingConditions.map(ScopeBackupExistingConditions.init), forKey: .existingConditions)
        try container.encodeIfPresent(dimensions, forKey: .dimensions)
        try container.encodeIfPresent(structuralSystem.map(ScopeBackupStructuralSystem.init), forKey: .structuralSystem)
        try container.encodeIfPresent(enclosure.map(ScopeBackupEnclosure.init), forKey: .enclosure)
        try container.encodeIfPresent(electrical, forKey: .electrical)
        try container.encodeIfPresent(drainage, forKey: .drainage)
        try container.encodeIfPresent(attachment, forKey: .attachment)
        try container.encodeIfPresent(documentsPayload, forKey: .documentsPayload)
        try container.encodeIfPresent(finishes, forKey: .finishes)
        try container.encodeIfPresent(permitsHOA, forKey: .permitsHOA)
        try container.encodeIfPresent(production, forKey: .production)
        try container.encodeIfPresent(customerApproval, forKey: .customerApproval)
        try container.encodeIfPresent(photos, forKey: .photos)
        try container.encodeIfPresent(sketches, forKey: .sketches)
        try container.encodeIfPresent(voiceNotes, forKey: .voiceNotes)
        try container.encodeIfPresent(aiExtractionDrafts, forKey: .aiExtractionDrafts)
        try container.encode(reviewState, forKey: .reviewState)
    }

    @MainActor
    init(scope: JobScope, reviewState: [String: Date] = [:]) {
        id = scope.id
        createdAt = scope.createdAt
        lastOpenedAt = scope.lastOpenedAt
        updatedAt = scope.updatedAt
        status = scope.status
        jobNumber = scope.jobNumber
        scopeTitle = scope.scopeTitle
        jobTreadCustomer = scope.jobTreadCustomer
        jobTreadJob = scope.jobTreadJob
        jobTreadSync = scope.jobTreadSync
        projectInfo = scope.projectInfo
        existingConditions = scope.existingConditions
        dimensions = scope.dimensions
        structuralSystem = scope.structuralSystem
        enclosure = scope.enclosure
        electrical = scope.electrical
        drainage = scope.drainage
        attachment = scope.attachment
        documentsPayload = scope.documentsPayload
        finishes = scope.finishes
        permitsHOA = scope.permitsHOA
        production = scope.production
        customerApproval = scope.customerApproval
        photos = scope.photos
        sketches = scope.sketches
        voiceNotes = scope.voiceNotes
        aiExtractionDrafts = scope.aiExtractionDrafts
        self.reviewState = reviewState
    }

    /// Creates an unattached model. The caller owns insertion and save approval.
    /// Never calls JobTread or resolves/creates a customer record.
    @MainActor
    func makeScope() throws -> JobScope {
        try validateModelEncodingFidelity()
        _ = try decodedDocuments()
        let scope = JobScope(
            id: id,
            createdAt: createdAt,
            lastOpenedAt: lastOpenedAt,
            updatedAt: updatedAt,
            status: status,
            jobNumber: jobNumber,
            scopeTitle: scopeTitle,
            jobTreadCustomer: jobTreadCustomer,
            jobTreadJob: jobTreadJob,
            jobTreadSync: jobTreadSync,
            projectInfo: projectInfo,
            existingConditions: existingConditions,
            dimensions: dimensions,
            structuralSystem: structuralSystem,
            enclosure: enclosure,
            electrical: electrical,
            drainage: drainage,
            attachment: attachment,
            finishes: finishes,
            permitsHOA: permitsHOA,
            production: production,
            customerApproval: customerApproval,
            photos: photos,
            sketches: sketches,
            voiceNotes: voiceNotes,
            aiExtractionDrafts: aiExtractionDrafts
        )
        // Preserve the original encoded bytes, including a valid empty section.
        // The model's convenience setter otherwise normalizes empty documents.
        scope.documentsPayload = documentsPayload
        return scope
    }

    /// SwiftData continues to use the existing model codecs, several of which
    /// normalize editing values. An archive may preserve those values exactly,
    /// but must not report a successful restore if a model save would change
    /// them. Call this before adopting files or inserting any live model.
    func validateModelEncodingFidelity() throws {
        try requireStableModelEncoding(projectInfo)
        try requireStableModelEncoding(existingConditions)
        try requireStableModelEncoding(structuralSystem)
        try requireStableModelEncoding(enclosure)
        _ = try decodedDocuments()
    }

    private func requireStableModelEncoding<Value: Codable & Equatable>(_ value: Value) throws {
        do {
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(Value.self, from: encoded)
            guard decoded == value else {
                throw ScopeBackupRecordError.unsupportedModelRepresentation
            }
        } catch {
            throw ScopeBackupRecordError.unsupportedModelRepresentation
        }
    }

    /// Enumerates model references only. Folder-discovered checklist images and
    /// deterministic drawing assets also need the archive's directory inventory.
    func referencedAssetPaths() throws -> [String] {
        var paths: [String] = []
        if let path = customerApproval?.signaturePNGPath { paths.append(path) }
        if let documents = try decodedDocuments() {
            if let file = documents.irrigation { paths.append(file.filePath) }
            if let file = documents.propertySurvey { paths.append(file.filePath) }
            paths.append(contentsOf: (documents.additionalAttachments ?? []).compactMap { $0.attachment?.filePath })
        }
        paths.append(contentsOf: (photos ?? []).map(\.imagePath))
        for sketch in sketches ?? [] {
            paths.append(sketch.drawingDataPath)
            paths.append(sketch.previewPNGPath)
        }
        paths.append(contentsOf: (voiceNotes ?? []).map(\.audioPath))
        guard paths.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw ScopeBackupRecordError.invalidAssetPath
        }
        var seen = Set<String>()
        return paths.filter { seen.insert($0).inserted }
    }

    /// Rewrites every file reference without partially mutating this record on
    /// failure. The archive layer validates that mapping targets are owned paths.
    mutating func remapAssetPaths(_ mapping: [String: String]) throws {
        let paths = try referencedAssetPaths()
        for path in paths { _ = try mapped(path, using: mapping) }

        var updated = self
        if let path = updated.customerApproval?.signaturePNGPath {
            updated.customerApproval?.signaturePNGPath = try mapped(path, using: mapping)
        }
        if var documents = try decodedDocuments() {
            if let path = documents.irrigation?.filePath {
                documents.irrigation?.filePath = try mapped(path, using: mapping)
            }
            if let path = documents.propertySurvey?.filePath {
                documents.propertySurvey?.filePath = try mapped(path, using: mapping)
            }
            if var attachments = documents.additionalAttachments {
                for index in attachments.indices {
                    if let path = attachments[index].attachment?.filePath {
                        attachments[index].attachment?.filePath = try mapped(path, using: mapping)
                    }
                }
                documents.additionalAttachments = attachments
            }
            // Avoid rewriting raw bytes when all document paths are unchanged.
            if documents != (try decodedDocuments()) {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys]
                do {
                    updated.documentsPayload = try encoder.encode(documents)
                } catch {
                    throw ScopeBackupRecordError.invalidDocumentsPayload
                }
            }
        }
        if var photos = updated.photos {
            for index in photos.indices {
                photos[index].imagePath = try mapped(photos[index].imagePath, using: mapping)
            }
            updated.photos = photos
        }
        if var sketches = updated.sketches {
            for index in sketches.indices {
                sketches[index].drawingDataPath = try mapped(sketches[index].drawingDataPath, using: mapping)
                sketches[index].previewPNGPath = try mapped(sketches[index].previewPNGPath, using: mapping)
            }
            updated.sketches = sketches
        }
        if var notes = updated.voiceNotes {
            for index in notes.indices {
                notes[index].audioPath = try mapped(notes[index].audioPath, using: mapping)
            }
            updated.voiceNotes = notes
        }
        self = updated
    }

    private func decodedDocuments() throws -> DocumentsSection? {
        guard let documentsPayload else { return nil }
        do {
            let documents = try JSONDecoder().decode(DocumentsSection.self, from: documentsPayload)
            let encoded = try JSONEncoder().encode(documents)
            guard let originalObject = try JSONSerialization.jsonObject(with: documentsPayload) as? NSDictionary,
                  let encodedObject = try JSONSerialization.jsonObject(with: encoded) as? NSDictionary else {
                throw ScopeBackupRecordError.invalidDocumentsPayload
            }
            // Rewriting known paths must not erase unknown keys or explicit
            // null/default representations. Compare objects, not serialized
            // bytes, so harmless whitespace/key order changes are accepted.
            guard originalObject.isEqual(encodedObject) else {
                throw ScopeBackupRecordError.unsupportedDocumentsRepresentation
            }
            return documents
        } catch let error as ScopeBackupRecordError {
            throw error
        } catch {
            throw ScopeBackupRecordError.invalidDocumentsPayload
        }
    }

    private func mapped(_ path: String, using mapping: [String: String]) throws -> String {
        guard let destination = mapping[path] else {
            throw ScopeBackupRecordError.missingAssetMapping
        }
        guard !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScopeBackupRecordError.invalidAssetPath
        }
        return destination
    }
}

enum ScopeBackupRecordError: LocalizedError {
    case invalidDocumentsPayload
    case missingAssetMapping
    case invalidAssetPath
    case unsupportedEnumValue
    case unsupportedModelRepresentation
    case unsupportedDocumentsRepresentation

    var errorDescription: String? {
        switch self {
        case .unsupportedDocumentsRepresentation:
            return "This scope's document information contains values that this app cannot restore without changing them. Preserve the backup and installed app."
        case .unsupportedModelRepresentation:
            return "This scope contains values that the current app cannot restore without changing them. Preserve the backup and installed app; no existing scope should be replaced."
        case .unsupportedEnumValue:
            return "The backup uses a field value that this app version does not support."
        case .invalidDocumentsPayload:
            return "A scope contains document information that could not be read. Preserve the installed app and resolve that issue before backing up or restoring."
        case .missingAssetMapping:
            return "A scope references an asset that is missing from the backup's file inventory."
        case .invalidAssetPath:
            return "A scope contains an invalid asset reference."
        }
    }
}

// These archive-only representations intentionally bypass model codecs that
// normalize display/export values. Every stored member is assigned verbatim,
// including whitespace, empty-but-present structs, disabled measurement rows,
// duplicate/order-sensitive selections, and retired enum cases.

private struct ScopeBackupProjectInfo: Codable {
    var clientName: String
    var address: String
    var unitNumber: String?
    var city: String?
    var state: String?
    var zip: String?
    var phone: String?
    var email: String?
    var salesperson: String?
    var estimator: String?
    var siteVisitDate: Date?
    var projectTypes: [ProjectType]?
    var notes: String?

    init(_ value: ProjectInfo) {
        clientName = value.clientName
        address = value.address
        unitNumber = value.unitNumber
        city = value.city
        state = value.state
        zip = value.zip
        phone = value.phone
        email = value.email
        salesperson = value.salesperson
        estimator = value.estimator
        siteVisitDate = value.siteVisitDate
        projectTypes = value.projectTypes
        notes = value.notes
    }

    func modelValue() throws -> ProjectInfo {
        var value = ProjectInfo()
        value.clientName = clientName
        value.address = address
        value.unitNumber = unitNumber
        value.city = city
        value.state = state
        value.zip = zip
        value.phone = phone
        value.email = email
        value.salesperson = salesperson
        value.estimator = estimator
        value.siteVisitDate = siteVisitDate
        value.projectTypes = projectTypes
        value.notes = notes
        return value
    }
}

private struct ScopeBackupExistingConditions: Codable {
    var houseStories: HouseStories?
    var exteriorFinish: ExistingConditionsExteriorFinish?
    var existingStructure: [ExistingStructure]?
    var existingStructureNotes: String?
    var obstaclesNotes: String?
    var utilitiesNotes: String?
    var hoaNotes: String?
    var photoChecklist: PhotoChecklist?

    init(_ value: ExistingConditions) {
        houseStories = value.houseStories
        exteriorFinish = value.exteriorFinish
        existingStructure = value.existingStructure
        existingStructureNotes = value.existingStructureNotes
        obstaclesNotes = value.obstaclesNotes
        utilitiesNotes = value.utilitiesNotes
        hoaNotes = value.hoaNotes
        photoChecklist = value.photoChecklist
    }

    func modelValue() throws -> ExistingConditions {
        var value = ExistingConditions()
        value.houseStories = houseStories
        value.exteriorFinish = exteriorFinish
        value.existingStructure = existingStructure
        value.existingStructureNotes = existingStructureNotes
        value.obstaclesNotes = obstaclesNotes
        value.utilitiesNotes = utilitiesNotes
        value.hoaNotes = hoaNotes
        value.photoChecklist = photoChecklist
        return value
    }
}

private struct ScopeBackupStructuralSystem: Codable {
    var systemType: StructuralSystemType?
    var systemTypeOther: String?
    var measurements: MeasurementsBlock?
    var insulatedAluminumPatioCover: InsulatedAluminumPatioCoverDetails?
    var pergolaType: PergolaType?
    var motorizedLouveredPergola: PergolaDimensionDetails?
    var manuallyRetractableLouveredPergola: PergolaDimensionDetails?
    var cedarPergola: CedarPergolaDetails?
    var alumawoodPergola: AlumawoodPergolaDetails?
    var frameMaterial: FrameMaterial?
    var postSize: String?
    var beamType: String?
    var roofSystem: RoofSystem?
    var roofColor: String?
    var frameColor: String?
    var notes: String?

    init(_ value: StructuralSystem) {
        systemType = value.systemType
        systemTypeOther = value.systemTypeOther
        measurements = value.measurements
        insulatedAluminumPatioCover = value.insulatedAluminumPatioCover
        pergolaType = value.pergolaType
        motorizedLouveredPergola = value.motorizedLouveredPergola
        manuallyRetractableLouveredPergola = value.manuallyRetractableLouveredPergola
        cedarPergola = value.cedarPergola
        alumawoodPergola = value.alumawoodPergola
        frameMaterial = value.frameMaterial
        postSize = value.postSize
        beamType = value.beamType
        roofSystem = value.roofSystem
        roofColor = value.roofColor
        frameColor = value.frameColor
        notes = value.notes
    }

    func modelValue() throws -> StructuralSystem {
        var value = StructuralSystem()
        value.systemType = systemType
        value.systemTypeOther = systemTypeOther
        value.measurements = measurements
        value.insulatedAluminumPatioCover = insulatedAluminumPatioCover
        value.pergolaType = pergolaType
        value.motorizedLouveredPergola = motorizedLouveredPergola
        value.manuallyRetractableLouveredPergola = manuallyRetractableLouveredPergola
        value.cedarPergola = cedarPergola
        value.alumawoodPergola = alumawoodPergola
        value.frameMaterial = frameMaterial
        value.postSize = postSize
        value.beamType = beamType
        value.roofSystem = roofSystem
        value.roofColor = roofColor
        value.frameColor = frameColor
        value.notes = notes
        return value
    }
}

private struct ScopeBackupDoorOptions: Codable {
    var doorType: String?
    var style: DoorStyleOption?
    var operableSide: DoorOperableSideOption?
    var hingeSide: DoorHingeSideOption?
    var width: String?
    var height: String?
    var color: String?
    var dimensions: String?
    var notes: String?

    init(_ value: DoorOptions) {
        doorType = value.doorType?.rawValue
        style = value.style
        operableSide = value.operableSide
        hingeSide = value.hingeSide
        width = value.width
        height = value.height
        color = value.color
        dimensions = value.dimensions
        notes = value.notes
    }

    func modelValue() throws -> DoorOptions {
        var value = DoorOptions()
        if let doorType {
            guard let type = DoorType(rawValue: doorType) else {
                throw ScopeBackupRecordError.unsupportedEnumValue
            }
            value.doorType = type
        }
        value.style = style
        value.operableSide = operableSide
        value.hingeSide = hingeSide
        value.width = width
        value.height = height
        value.color = color
        value.dimensions = dimensions
        value.notes = notes
        return value
    }
}

private struct ScopeBackupEnclosure: Codable {
    var enclosureTypes: [String]?
    var screenWallType: ScreenWallType?
    var screenTint: ScreenTintOption?
    var screenFrameSize: ScreenFrameSizeOption?
    var screenFrameColor: EnclosureScreenFrameColorOption?
    var screenFrameColorCustom: String?
    var screenEnclosureNotes: String?
    var screenMeasurements: MeasurementsBlock?
    var windowSystem: WindowSystem?
    var sunroomMeasurements: MeasurementsBlock?
    var kneeWall: KneeWall?
    var doors: ScopeBackupDoorOptions?

    init(_ value: Enclosure) {
        enclosureTypes = value.enclosureTypes?.map(\.rawValue)
        screenWallType = value.screenWallType
        screenTint = value.screenTint
        screenFrameSize = value.screenFrameSize
        screenFrameColor = value.screenFrameColor
        screenFrameColorCustom = value.screenFrameColorCustom
        screenEnclosureNotes = value.screenEnclosureNotes
        screenMeasurements = value.screenMeasurements
        windowSystem = value.windowSystem
        sunroomMeasurements = value.sunroomMeasurements
        kneeWall = value.kneeWall
        doors = value.doors.map(ScopeBackupDoorOptions.init)
    }

    func modelValue() throws -> Enclosure {
        var value = Enclosure()
        value.enclosureTypes = try enclosureTypes?.map { rawValue in
            guard let type = EnclosureType(rawValue: rawValue) else {
                throw ScopeBackupRecordError.unsupportedEnumValue
            }
            return type
        }
        value.screenWallType = screenWallType
        value.screenTint = screenTint
        value.screenFrameSize = screenFrameSize
        value.screenFrameColor = screenFrameColor
        value.screenFrameColorCustom = screenFrameColorCustom
        value.screenEnclosureNotes = screenEnclosureNotes
        value.screenMeasurements = screenMeasurements
        value.windowSystem = windowSystem
        value.sunroomMeasurements = sunroomMeasurements
        value.kneeWall = kneeWall
        value.doors = try doors?.modelValue()
        return value
    }
}
