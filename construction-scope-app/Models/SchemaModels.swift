import Foundation
import Observation
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
    case other
}

enum ProjectType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case notSet = "not_set"
    case patioCover = "patio_cover"
    case screenRoom = "screen_room"
    case sunroom
    case deck
    case pergola
    case concrete
    case other

    var displayName: String {
        switch self {
        case .notSet:
            return "Not Set"
        default:
            return rawValue
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
}

enum HouseStories: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case oneStory = "one_story"
    case twoStory = "two_story"
    case other
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
    case other
}

enum DimensionsAttachmentType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case fasciaMount = "fascia_mount"
    case wallMount = "wall_mount"
    case freeStanding = "free_standing"
    case other
}

enum FrameMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case aluminum
    case cedar
    case steel
    case other
}

enum RoofSystem: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case insulatedPanels = "insulated_panels"
    case polycarbonate
    case metal
    case shingle
    case other
}

enum EnclosureType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case screenEnclosure = "screen_enclosure"
    case vinylWindowEnclosure = "vinyl_window_enclosure"
    case glassSunroom = "glass_sunroom"
    case mixed
    case other
    case legacyScreenOnly = "screen_only"
    case legacyScreenRoomWithDoor = "screen_room_with_door"

    static var allCases: [EnclosureType] {
        [.screenEnclosure, .vinylWindowEnclosure, .glassSunroom, .mixed, .other]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.legacyScreenOnly.rawValue, Self.legacyScreenRoomWithDoor.rawValue:
            self = .screenEnclosure
        case let value where Self.allCases.contains(where: { $0.rawValue == value }):
            self = Self(rawValue: value) ?? .other
        default:
            self = .other
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum ScreenWallType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case standardFiberglass1814 = "18x14_standard_fiberglass"
    case noSeeUm2020 = "20x20_no_see_um"
    case tuff1814 = "18x14_tuff"
    case tuff2020 = "20x20_tuff"
    case other

    var displayName: String {
        switch self {
        case .standardFiberglass1814: return "18x14 Standard Fiberglass"
        case .noSeeUm2020: return "20x20 No-See-Um"
        case .tuff1814: return "18x14 Tuff"
        case .tuff2020: return "20x20 Tuff"
        case .other: return "Other"
        }
    }
}

enum StandardColorOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case white
    case beige
    case bronze
    case black
    case custom
    case other
}

enum ScreenFrameColorOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case white
    case beige
    case bronze
    case black
    case khaki
    case other
}

enum WindowType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case pgtEzebreeze4TrackVinyl = "pgt_ezebreeze_4track_vinyl"
    case doublePaneInsulatedGlass = "double_pane_insulated_glass"
    case other

    var displayName: String {
        switch self {
        case .pgtEzebreeze4TrackVinyl:
            return "PGT Eze-Breeze Vertical 4-Track Vinyl"
        case .doublePaneInsulatedGlass:
            return "Double Pane Insulated Glass"
        case .other:
            return "Other"
        }
    }
}

enum WindowFrameSystem: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case standardPatioExtrusion = "standard_patio_extrusion"
    case heavyDutyExtrusion = "heavy_duty_extrusion"
    case thermallyBrokenInsulated = "thermally_broken_insulated"
    case other
}

enum GlassType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case clear
    case lowE = "low_e"
    case tinted
    case other
}

enum GlassSafety: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case annealed
    case tempered
    case temperedRequiredByCode = "tempered_required_by_code"
    case other
}

enum GridOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case twoByTwo = "2x2"
    case twoByThree = "2x3"
    case colonial
    case other

    var displayName: String {
        switch self {
        case .none: return "None"
        case .twoByTwo: return "2x2"
        case .twoByThree: return "2x3"
        case .colonial: return "Colonial"
        case .other: return "Other"
        }
    }
}

enum WindowOperation: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case verticalSlide = "vertical_slide"
    case horizontalSlide = "horizontal_slide"
    case fixed
    case casement
    case other
}

enum WindowConfiguration: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case fullHeight = "full_height"
    case aboveKneeWall = "above_knee_wall"
    case mixed
    case other
}

enum KneeWallOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case aluminumKickplate = "aluminum_kickplate"
    case framedKneeWall = "framed_knee_wall"
    case insulatedAluminumPanel = "insulated_aluminum_panel"
    case other

    var displayName: String {
        switch self {
        case .none: return "None"
        case .aluminumKickplate: return "Aluminum Kickplate"
        case .framedKneeWall: return "Framed Knee Wall"
        case .insulatedAluminumPanel: return "Insulated Aluminum Panel Knee Wall"
        case .other: return "Other"
        }
    }
}

enum KneeWallPanelHeightOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case inches16 = "16_in"
    case inches24 = "24_in"

    var displayName: String {
        switch self {
        case .inches16: return "16\""
        case .inches24: return "24\""
        }
    }
}

enum KneeWallFramingOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case twoByFour = "2x4"
    case twoBySix = "2x6"

    var displayName: String {
        rawValue
    }
}

enum DoorType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case hingedScreen = "hinged_screen"
    case pgtCabanaDoor = "pgt_cabana_door"
    case slidingGlass = "sliding_glass"
    case other
    case legacyHeavyDutyAluminum = "heavy_duty_aluminum"
    case legacyFrench = "french"

    static var allCases: [DoorType] {
        [.none, .hingedScreen, .pgtCabanaDoor, .slidingGlass, .other]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.legacyHeavyDutyAluminum.rawValue:
            self = .pgtCabanaDoor
        case Self.legacyFrench.rawValue:
            self = .legacyFrench
        case let value where Self.allCases.contains(where: { $0.rawValue == value }):
            self = Self(rawValue: value) ?? .other
        default:
            self = .other
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var displayName: String {
        switch self {
        case .pgtCabanaDoor:
            return "PGT Cabana Door"
        default:
            return rawValue
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
}

enum DoorStyleOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case french
    case single
}

enum DoorOperableSideOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case left
    case right
}

enum DoorHingeSideOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case leftHinge = "left_hinge"
    case rightHinge = "right_hinge"
}

enum LightingOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case none
    case recessed
    case fanLight = "fan_light"
    case surfaceMount = "surface_mount"
    case other
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
    case other
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
    case other

    var displayName: String {
        switch self {
        case .none: return "None"
        case .inchesHalf: return "0.5 in"
        case .inchesThreeQuarter: return "0.75 in"
        case .inchesOne: return "1.0 in"
        case .inchesOneAndHalf: return "1.5 in"
        case .inchesTwo: return "2.0 in"
        case .custom: return "Custom"
        case .other: return "Other"
        }
    }
}

enum MountCondition: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case directToStructural = "direct_to_structural"
    case throughTrimToStructural = "through_trim_to_structural"
    case trimCutBack = "trim_cut_back"
    case spacerBlockRequired = "spacer_block_required"
    case other
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
    case other
}

enum PermitStatus: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case notSubmitted = "not_submitted"
    case submitted
    case approved
    case other
}

struct ProjectInfo: Codable, Hashable {
    var clientName: String
    var address: String
    var city: String?
    var state: String?
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
        state: String? = nil,
        zip: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        salesperson: String? = nil,
        estimator: String? = nil,
        siteVisitDate: Date? = nil,
        projectType: ProjectType = .notSet,
        notes: String? = nil
    ) {
        self.clientName = clientName
        self.address = address
        self.city = city
        self.state = state
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
    var notes: String?
}

struct Enclosure: Codable, Hashable {
    var enclosureType: EnclosureType?
    var screenWallType: ScreenWallType?
    var screenFrameColor: ScreenFrameColorOption?
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
    var notes: String?
}

struct KneeWall: Codable, Hashable {
    var option: KneeWallOption?
    var panelHeight: KneeWallPanelHeightOption?
    var panelColor: String?
    var linearFootage: String?
    var height: String?
    var interiorFinishColor: ScreenFrameColorOption?
    var exteriorFinishColor: ScreenFrameColorOption?
    var framing: KneeWallFramingOption?

    private enum CodingKeys: String, CodingKey {
        case option
        case panelHeight
        case panelColor
        case linearFootage
        case height
        case interiorFinishColor
        case exteriorFinishColor
        case framing
        case trimColor
    }

    init(
        option: KneeWallOption? = nil,
        panelHeight: KneeWallPanelHeightOption? = nil,
        panelColor: String? = nil,
        linearFootage: String? = nil,
        height: String? = nil,
        interiorFinishColor: ScreenFrameColorOption? = nil,
        exteriorFinishColor: ScreenFrameColorOption? = nil,
        framing: KneeWallFramingOption? = nil
    ) {
        self.option = option
        self.panelHeight = panelHeight
        self.panelColor = panelColor
        self.linearFootage = linearFootage
        self.height = height
        self.interiorFinishColor = interiorFinishColor
        self.exteriorFinishColor = exteriorFinishColor
        self.framing = framing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        option = try container.decodeIfPresent(KneeWallOption.self, forKey: .option)
        panelColor = try container.decodeIfPresent(String.self, forKey: .panelColor)
        linearFootage =
            try container.decodeIfPresent(String.self, forKey: .linearFootage) ??
            container.decodeIfPresent(String.self, forKey: .trimColor)
        height = try container.decodeIfPresent(String.self, forKey: .height)
        interiorFinishColor = try container.decodeIfPresent(ScreenFrameColorOption.self, forKey: .interiorFinishColor)
        exteriorFinishColor = try container.decodeIfPresent(ScreenFrameColorOption.self, forKey: .exteriorFinishColor)
        framing = try container.decodeIfPresent(KneeWallFramingOption.self, forKey: .framing)

        if let panelHeight = try container.decodeIfPresent(KneeWallPanelHeightOption.self, forKey: .panelHeight) {
            self.panelHeight = panelHeight
        } else if let legacyHeight = try container.decodeIfPresent(Double.self, forKey: .panelHeight) {
            switch Int(legacyHeight.rounded()) {
            case 16:
                self.panelHeight = .inches16
            case 24:
                self.panelHeight = .inches24
            default:
                self.panelHeight = nil
            }
        } else {
            panelHeight = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(option, forKey: .option)
        try container.encodeIfPresent(panelHeight, forKey: .panelHeight)
        try container.encodeIfPresent(panelColor, forKey: .panelColor)
        try container.encodeIfPresent(linearFootage, forKey: .linearFootage)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(interiorFinishColor, forKey: .interiorFinishColor)
        try container.encodeIfPresent(exteriorFinishColor, forKey: .exteriorFinishColor)
        try container.encodeIfPresent(framing, forKey: .framing)
    }
}

struct DoorOptions: Codable, Hashable {
    var doorType: DoorType?
    var style: DoorStyleOption?
    var operableSide: DoorOperableSideOption?
    var hingeSide: DoorHingeSideOption?
    var width: String?
    var height: String?
    var color: String?
    var dimensions: String?
    var notes: String?

    private enum CodingKeys: String, CodingKey {
        case doorType
        case style
        case operableSide
        case hingeSide
        case width
        case height
        case color
        case dimensions
        case notes
    }

    init(
        doorType: DoorType? = nil,
        style: DoorStyleOption? = nil,
        operableSide: DoorOperableSideOption? = nil,
        hingeSide: DoorHingeSideOption? = nil,
        width: String? = nil,
        height: String? = nil,
        color: String? = nil,
        dimensions: String? = nil,
        notes: String? = nil
    ) {
        self.doorType = doorType
        self.style = style
        self.operableSide = operableSide
        self.hingeSide = hingeSide
        self.width = width
        self.height = height
        self.color = color
        self.dimensions = dimensions
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDoorType = try container.decodeIfPresent(DoorType.self, forKey: .doorType)

        if decodedDoorType?.rawValue == "french" {
            doorType = .hingedScreen
            style = .french
        } else {
            doorType = decodedDoorType
            style = try container.decodeIfPresent(DoorStyleOption.self, forKey: .style)
        }

        operableSide = try container.decodeIfPresent(DoorOperableSideOption.self, forKey: .operableSide)
        hingeSide = try container.decodeIfPresent(DoorHingeSideOption.self, forKey: .hingeSide)
        width = try container.decodeIfPresent(String.self, forKey: .width)
        height = try container.decodeIfPresent(String.self, forKey: .height)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        dimensions = try container.decodeIfPresent(String.self, forKey: .dimensions)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(doorType, forKey: .doorType)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encodeIfPresent(operableSide, forKey: .operableSide)
        try container.encodeIfPresent(hingeSide, forKey: .hingeSide)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(dimensions, forKey: .dimensions)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
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

struct JobTreadCustomerLookupResult: Codable, Hashable, Identifiable, Sendable {
    let customerID: String
    let displayName: String?
    let accountType: String?
    let primaryAddress: String?
    let phone: String?
    let email: String?

    var id: String { customerID }

    var resolvedDisplayName: String {
        displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Unnamed Customer"
    }

    var customerReference: JobTreadCustomerRef {
        JobTreadCustomerRef(
            customerID: customerID,
            displayName: displayName,
            accountType: accountType,
            primaryAddress: primaryAddress,
            phone: phone,
            email: email,
            fetchedAt: .now
        )
    }
}

struct JobTreadCustomerRef: Codable, Hashable {
    var customerID: String
    var displayName: String?
    var accountType: String?
    var primaryAddress: String?
    var city: String?
    var state: String?
    var postalCode: String?
    var phone: String?
    var email: String?
    var fetchedAt: Date?

    init(
        customerID: String,
        displayName: String? = nil,
        accountType: String? = nil,
        primaryAddress: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        fetchedAt: Date? = nil
    ) {
        self.customerID = customerID
        self.displayName = displayName
        self.accountType = accountType
        self.primaryAddress = primaryAddress
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.phone = phone
        self.email = email
        self.fetchedAt = fetchedAt
    }
}

struct JobTreadJobRef: Codable, Hashable {
    var jobID: String
    var jobNumber: String?
    var title: String?
    var fetchedAt: Date?

    init(
        jobID: String,
        jobNumber: String? = nil,
        title: String? = nil,
        fetchedAt: Date? = nil
    ) {
        self.jobID = jobID
        self.jobNumber = jobNumber
        self.title = title
        self.fetchedAt = fetchedAt
    }
}

enum JobTreadSyncStatus: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case neverSynced = "never_synced"
    case inProgress = "in_progress"
    case succeeded
    case failed
}

struct JobTreadSyncMetadata: Codable, Hashable {
    var status: JobTreadSyncStatus
    var lastAttemptAt: Date?
    var lastSucceededAt: Date?
    var lastErrorMessage: String?

    init(
        status: JobTreadSyncStatus = .neverSynced,
        lastAttemptAt: Date? = nil,
        lastSucceededAt: Date? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.status = status
        self.lastAttemptAt = lastAttemptAt
        self.lastSucceededAt = lastSucceededAt
        self.lastErrorMessage = lastErrorMessage
    }
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
    var finishes: Finishes?
    var permitsHOA: PermitsHOA?
    var production: ProductionOrderMeta?
    var customerApproval: CustomerApproval?
    var photos: [PhotoAttachment]?
    var sketches: [SketchAttachment]?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        lastOpenedAt: Date? = nil,
        updatedAt: Date = .now,
        status: JobStatus = .draft,
        jobNumber: String? = nil,
        scopeTitle: String? = nil,
        jobTreadCustomer: JobTreadCustomerRef? = nil,
        jobTreadJob: JobTreadJobRef? = nil,
        jobTreadSync: JobTreadSyncMetadata? = nil,
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
        self.lastOpenedAt = lastOpenedAt
        self.updatedAt = updatedAt
        self.status = status
        self.jobNumber = jobNumber
        self.scopeTitle = scopeTitle
        self.jobTreadCustomer = jobTreadCustomer
        self.jobTreadJob = jobTreadJob
        self.jobTreadSync = jobTreadSync
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

    var resolvedScopeTitle: String? {
        scopeTitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var resolvedLinkedCustomerName: String? {
        jobTreadCustomer?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var resolvedProjectClientName: String? {
        projectInfo.clientName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var resolvedCustomerDisplayName: String? {
        resolvedLinkedCustomerName ?? resolvedProjectClientName
    }

    var resolvedDocumentTitle: String {
        resolvedScopeTitle ?? resolvedCustomerDisplayName ?? "Untitled Scope"
    }

    var resolvedExportCustomerName: String? {
        resolvedCustomerDisplayName
    }

    var resolvedExportIdentityToken: String {
        resolvedScopeTitle ?? resolvedCustomerDisplayName ?? "Scope"
    }

    var displayName: String {
        resolvedScopeTitle ??
            resolvedLinkedCustomerName ??
            resolvedProjectClientName ??
            "Untitled Scope"
    }

    var showsSeparateCustomerIdentity: Bool {
        guard let customerName = resolvedCustomerDisplayName else { return false }
        return customerName.localizedCaseInsensitiveCompare(displayName) != .orderedSame
    }

    var shouldShowMissingLinkedStreetAddressHint: Bool {
        guard jobTreadCustomer != nil else { return false }
        guard projectInfo.address.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty == nil else { return false }

        return [
            jobTreadCustomer?.city,
            jobTreadCustomer?.state,
            jobTreadCustomer?.postalCode
        ].contains { $0?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil }
    }

    func setLocalScopeTitle(_ newTitle: String) {
        scopeTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        updatedAt = .now
    }

    var hasLinkedJobTreadCustomer: Bool {
        jobTreadCustomer != nil
    }

    func applyLinkedCustomerHydration(_ detail: JobTreadCustomerDetail) {
        let trimmedName = detail.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedAddress = detail.primaryAddress?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedAccountType = detail.accountType?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedCity = detail.city?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedState = detail.state?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedZIP = detail.postalCode?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if jobTreadCustomer != nil {
            jobTreadCustomer?.displayName = trimmedName
            jobTreadCustomer?.accountType = trimmedAccountType
            jobTreadCustomer?.primaryAddress = trimmedAddress
            jobTreadCustomer?.city = trimmedCity
            jobTreadCustomer?.state = trimmedState
            jobTreadCustomer?.postalCode = trimmedZIP
            jobTreadCustomer?.fetchedAt = .now
        }

        projectInfo.clientName = trimmedName ?? ""
        projectInfo.address = trimmedAddress ?? ""
        projectInfo.city = trimmedCity
        projectInfo.state = trimmedState
        projectInfo.zip = trimmedZIP
        updatedAt = .now
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
            projectType: .notSet,
            notes: ""
        )
    )

    static func makeNewScope() -> JobScope {
        JobScope(
            status: lockedTemplate.defaultStatus,
            projectInfo: lockedTemplate.defaultProjectInfo
        )
    }

    static func makeScope(linkedCustomer customer: JobTreadCustomerLookupResult) -> JobScope {
        JobScope(
            status: lockedTemplate.defaultStatus,
            jobTreadCustomer: customer.customerReference,
            jobTreadSync: JobTreadSyncMetadata(),
            projectInfo: ProjectInfo(
                clientName: customer.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "",
                address: customer.primaryAddress?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "",
                phone: customer.phone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                email: customer.email?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                projectType: .notSet,
                notes: lockedTemplate.defaultProjectInfo.notes
            )
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
