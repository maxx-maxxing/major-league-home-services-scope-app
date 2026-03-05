import Foundation
import SwiftData

protocol SchemaEnumDisplayable: RawRepresentable where RawValue == String {}

extension SchemaEnumDisplayable {
    var displayName: String {
        rawValue
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "ezebreeze", with: "Eze-Breeze")
            .capitalized
    }
}

enum JobStatus: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case draft
    case sold
    case inProduction = "in_production"
    case closed
}

enum ProjectType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case patioCover = "patio_cover"
    case screenRoom = "screen_room"
    case sunroom
    case deck
    case pergola
    case concrete
    case other
}

enum HouseStories: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case oneStory = "one_story"
    case twoStory = "two_story"
}

enum ExteriorFinish: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case brick
    case hardie
    case stucco
    case stone
    case other
}

enum ExistingStructure: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case existingPatioCover = "existing_patio_cover"
    case none
    case deck
    case concreteSlab = "concrete_slab"
    case other
}

enum RoofStyle: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case flat
    case lowSlope = "low_slope"
    case gable
    case pergola
}

enum DimensionsAttachmentType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case fasciaMount = "fascia_mount"
    case wallMount = "wall_mount"
    case freeStanding = "free_standing"
}

enum FrameMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case aluminum
    case cedar
    case steel
}

enum RoofSystem: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case insulatedPanels = "insulated_panels"
    case polycarbonate
    case metal
    case shingle
}

enum EnclosureType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case screenOnly = "screen_only"
    case screenRoomWithDoor = "screen_room_with_door"
    case vinylWindowEnclosure = "vinyl_window_enclosure"
    case glassSunroom = "glass_sunroom"
    case mixed
}

enum ScreenWallType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case standardFiberglass1814 = "18x14_standard_fiberglass"
    case noSeeUm2020 = "20x20_no_see_um"
    case tuff1814 = "18x14_tuff"
    case tuff2020 = "20x20_tuff"

    var displayName: String {
        switch self {
        case .standardFiberglass1814: return "18x14 Standard Fiberglass"
        case .noSeeUm2020: return "20x20 No-See-Um"
        case .tuff1814: return "18x14 Tuff"
        case .tuff2020: return "20x20 Tuff"
        }
    }
}

enum StandardColorOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case white
    case beige
    case bronze
    case black
    case custom
}

enum WindowType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case pgtEzebreeze4TrackVinyl = "pgt_ezebreeze_4track_vinyl"
    case doublePaneInsulatedGlass = "double_pane_insulated_glass"

    var displayName: String {
        switch self {
        case .pgtEzebreeze4TrackVinyl:
            return "PGT Eze-Breeze Vertical 4-Track Vinyl"
        case .doublePaneInsulatedGlass:
            return "Double Pane Insulated Glass"
        }
    }
}

enum WindowFrameSystem: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case standardPatioExtrusion = "standard_patio_extrusion"
    case heavyDutyExtrusion = "heavy_duty_extrusion"
    case thermallyBrokenInsulated = "thermally_broken_insulated"
}

enum GlassType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case clear
    case lowE = "low_e"
    case tinted
}

enum GlassSafety: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case annealed
    case tempered
    case temperedRequiredByCode = "tempered_required_by_code"
}

enum GridOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case twoByTwo = "2x2"
    case twoByThree = "2x3"
    case colonial

    var displayName: String {
        switch self {
        case .none: return "None"
        case .twoByTwo: return "2x2"
        case .twoByThree: return "2x3"
        case .colonial: return "Colonial"
        }
    }
}

enum WindowOperation: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case verticalSlide = "vertical_slide"
    case horizontalSlide = "horizontal_slide"
    case fixed
    case casement
}

enum WindowConfiguration: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case fullHeight = "full_height"
    case aboveKneeWall = "above_knee_wall"
    case mixed
}

enum KneeWallOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case aluminumKickplate = "aluminum_kickplate"
    case framedKneeWall = "framed_knee_wall"
    case insulatedAluminumPanel = "insulated_aluminum_panel"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .aluminumKickplate: return "Aluminum Kickplate"
        case .framedKneeWall: return "Framed Knee Wall"
        case .insulatedAluminumPanel: return "Insulated Aluminum Panel Knee Wall"
        }
    }
}

enum DoorType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case hingedScreen = "hinged_screen"
    case heavyDutyAluminum = "heavy_duty_aluminum"
    case slidingGlass = "sliding_glass"
    case french
}

enum LightingOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case recessed
    case fanLight = "fan_light"
    case surfaceMount = "surface_mount"
}

enum DedicatedCircuitType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case miniSplit = "mini_split"
    case hotTub = "hot_tub"
    case evCharger = "ev_charger"
    case other
}

enum HouseWallMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case brick
    case stone
    case stucco
    case hardie
    case woodSiding = "wood_siding"
    case lpSiding = "lp_siding"
    case structuralFascia = "structural_fascia"
    case roofFascia = "roof_fascia"
    case other
}

enum HouseMountingType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case ledgerRequired = "ledger_required"
    case directMount = "direct_mount"
    case throughSidingIntoFraming = "through_siding_into_framing"
    case throughMasonryIntoStructure = "through_masonry_into_structure"
}

enum PostColumnMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case wood
    case cedar
    case aluminum
    case steel
    case brickColumn = "brick_column"
    case stoneColumn = "stone_column"
    case wrappedStructural = "wrapped_structural"
    case other
}

enum TrimMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case wood
    case pvc
    case hardie
    case aluminumWrap = "aluminum_wrap"
    case other
}

enum TrimThickness: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case inchesHalf = "0.5"
    case inchesThreeQuarter = "0.75"
    case inchesOne = "1.0"
    case inchesOneAndHalf = "1.5"
    case inchesTwo = "2.0"
    case custom

    var displayName: String {
        switch self {
        case .none: return "None"
        case .inchesHalf: return "0.5 in"
        case .inchesThreeQuarter: return "0.75 in"
        case .inchesOne: return "1.0 in"
        case .inchesOneAndHalf: return "1.5 in"
        case .inchesTwo: return "2.0 in"
        case .custom: return "Custom"
        }
    }
}

enum MountCondition: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case directToStructural = "direct_to_structural"
    case throughTrimToStructural = "through_trim_to_structural"
    case trimCutBack = "trim_cut_back"
    case spacerBlockRequired = "spacer_block_required"
}

enum FastenerType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case structuralLags = "structural_lags"
    case masonryAnchors = "masonry_anchors"
    case tapcons
    case sleeveAnchors = "sleeve_anchors"
    case epoxyAnchors = "epoxy_anchors"
}

enum MaterialOrderStatus: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case notOrdered = "not_ordered"
    case ordered
    case delivered
}

enum PermitStatus: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case notSubmitted = "not_submitted"
    case submitted
    case approved
}

struct ProjectInfo: Codable, Hashable {
    var clientName: String
    var address: String
    var city: String?
    var zip: String?
    var phone: String?
    var email: String?
    var salesperson: String?
    var estimator: String?
    var siteVisitDate: Date?
    var projectType: ProjectType
    var notes: String?

    init(
        clientName: String = "",
        address: String = "",
        city: String? = nil,
        zip: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        salesperson: String? = nil,
        estimator: String? = nil,
        siteVisitDate: Date? = nil,
        projectType: ProjectType = .patioCover,
        notes: String? = nil
    ) {
        self.clientName = clientName
        self.address = address
        self.city = city
        self.zip = zip
        self.phone = phone
        self.email = email
        self.salesperson = salesperson
        self.estimator = estimator
        self.siteVisitDate = siteVisitDate
        self.projectType = projectType
        self.notes = notes
    }
}

struct ExistingConditions: Codable, Hashable {
    var houseStories: HouseStories?
    var exteriorFinish: ExteriorFinish?
    var existingStructure: ExistingStructure?
    var obstaclesNotes: String?
    var utilitiesNotes: String?
    var hoaNotes: String?
    var photoChecklist: PhotoChecklist?
}

struct PhotoChecklist: Codable, Hashable {
    var frontOfHouse: Bool?
    var rearElevation: Bool?
    var roofLine: Bool?
    var electricalPanel: Bool?
    var workArea: Bool?
}

struct Dimensions: Codable, Hashable {
    var width: Double?
    var projection: Double?
    var fasciaHeight: Double?
    var beamHeight: Double?
    var roofStyle: RoofStyle?
    var attachmentType: DimensionsAttachmentType?
    var elevationNotes: String?
}

struct StructuralSystem: Codable, Hashable {
    var frameMaterial: FrameMaterial?
    var postSize: String?
    var beamType: String?
    var roofSystem: RoofSystem?
    var roofColor: String?
    var frameColor: String?
}

struct Enclosure: Codable, Hashable {
    var enclosureType: EnclosureType?
    var screenWallType: ScreenWallType?
    var screenFrameColor: StandardColorOption?
    var screenFrameColorCustom: String?
    var windowSystem: WindowSystem?
    var kneeWall: KneeWall?
    var doors: DoorOptions?
}

struct WindowSystem: Codable, Hashable {
    var windowType: WindowType?
    var frameSystem: WindowFrameSystem?
    var glassType: GlassType?
    var glassSafety: GlassSafety?
    var gridOption: GridOption?
    var operation: WindowOperation?
    var color: StandardColorOption?
    var colorCustom: String?
    var windowHeight: Double?
    var numBays: Double?
    var configuration: WindowConfiguration?
}

struct KneeWall: Codable, Hashable {
    var option: KneeWallOption?
    var panelHeight: Double?
    var panelColor: String?
    var trimColor: String?
    var interiorFinish: String?
}

struct DoorOptions: Codable, Hashable {
    var doorType: DoorType?
    var notes: String?
}

struct Electrical: Codable, Hashable {
    var outletCount: Double?
    var lighting: LightingOption?
    var fanInstall: Bool?
    var switchLocations: String?
    var dedicatedCircuits: [DedicatedCircuitType]?
    var notes: String?
}

struct Drainage: Codable, Hashable {
    var gutters: Bool?
    var downspoutLocations: String?
    var drainTieIn: Bool?
    var slopeNotes: String?
}

struct AttachmentConditions: Codable, Hashable {
    var houseWallMaterial: HouseWallMaterial?
    var houseWallOther: String?
    var houseMountingType: HouseMountingType?
    var postColumnMaterial: PostColumnMaterial?
    var postColumnOther: String?
    var postSize: String?
    var postSpacing: String?
    var trimPresent: Bool?
    var trimMaterial: TrimMaterial?
    var trimMaterialOther: String?
    var trimThickness: TrimThickness?
    var trimThicknessCustom: Double?
    var mountCondition: MountCondition?
    var fastenerPlan: [FastenerType]?
    var notes: String?
}

struct Finishes: Codable, Hashable {
    var trimType: String?
    var paintOrPowderColor: String?
    var sidingReplacementRequired: Bool?
    var caulkingSealingNotes: String?
}

struct PermitsHOA: Codable, Hashable {
    var permitRequired: Bool?
    var jurisdiction: String?
    var hoaApprovalRequired: Bool?
    var engineeringRequired: Bool?
    var statusNotes: String?
}

struct ProductionOrderMeta: Codable, Hashable {
    var startDate: Date?
    var crewLead: String?
    var durationEstimate: String?
    var materialOrderStatus: MaterialOrderStatus?
    var permitStatus: PermitStatus?
}

struct CustomerApproval: Codable, Hashable {
    var optionsConfirmedText: String?
    var signaturePNGPath: String?
    var signedDate: Date?
}

struct PhotoAttachment: Codable, Hashable, Identifiable {
    var id: UUID
    var caption: String?
    var imagePath: String
    var createdAt: Date

    init(id: UUID = UUID(), caption: String? = nil, imagePath: String, createdAt: Date = .now) {
        self.id = id
        self.caption = caption
        self.imagePath = imagePath
        self.createdAt = createdAt
    }
}

struct SketchAttachment: Codable, Hashable, Identifiable {
    var id: UUID
    var title: String?
    var drawingDataPath: String
    var previewPNGPath: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String? = nil,
        drawingDataPath: String,
        previewPNGPath: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.drawingDataPath = drawingDataPath
        self.previewPNGPath = previewPNGPath
        self.createdAt = createdAt
    }
}

@Model
final class JobScope {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var status: JobStatus
    var jobNumber: String?
    var projectInfo: ProjectInfo
    var existingConditions: ExistingConditions?
    var dimensions: Dimensions?
    var structuralSystem: StructuralSystem?
    var enclosure: Enclosure?
    var electrical: Electrical?
    var drainage: Drainage?
    var attachment: AttachmentConditions?
    var finishes: Finishes?
    var permitsHOA: PermitsHOA?
    var production: ProductionOrderMeta?
    var customerApproval: CustomerApproval?
    var photos: [PhotoAttachment]?
    var sketches: [SketchAttachment]?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        status: JobStatus = .draft,
        jobNumber: String? = nil,
        projectInfo: ProjectInfo,
        existingConditions: ExistingConditions? = nil,
        dimensions: Dimensions? = nil,
        structuralSystem: StructuralSystem? = nil,
        enclosure: Enclosure? = nil,
        electrical: Electrical? = nil,
        drainage: Drainage? = nil,
        attachment: AttachmentConditions? = nil,
        finishes: Finishes? = nil,
        permitsHOA: PermitsHOA? = nil,
        production: ProductionOrderMeta? = nil,
        customerApproval: CustomerApproval? = nil,
        photos: [PhotoAttachment]? = nil,
        sketches: [SketchAttachment]? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.jobNumber = jobNumber
        self.projectInfo = projectInfo
        self.existingConditions = existingConditions
        self.dimensions = dimensions
        self.structuralSystem = structuralSystem
        self.enclosure = enclosure
        self.electrical = electrical
        self.drainage = drainage
        self.attachment = attachment
        self.finishes = finishes
        self.permitsHOA = permitsHOA
        self.production = production
        self.customerApproval = customerApproval
        self.photos = photos
        self.sketches = sketches
    }

    var displayName: String {
        if projectInfo.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Untitled Scope"
        }
        return projectInfo.clientName
    }
}

struct ScopeTemplateConfig: Codable, Hashable {
    let isLocked: Bool
    let defaultStatus: JobStatus
    let defaultProjectInfo: ProjectInfo
}

enum ScopeTemplate {
    static let lockedTemplate = ScopeTemplateConfig(
        isLocked: true,
        defaultStatus: .draft,
        defaultProjectInfo: ProjectInfo(
            clientName: "",
            address: "",
            projectType: .patioCover,
            notes: ""
        )
    )

    static func makeNewScope() -> JobScope {
        JobScope(
            status: lockedTemplate.defaultStatus,
            projectInfo: lockedTemplate.defaultProjectInfo
        )
    }
}
