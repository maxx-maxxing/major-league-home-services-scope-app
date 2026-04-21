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

enum PhotoChecklistCategory: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case frontOfHouse = "front_of_house"
    case rearElevation = "rear_elevation"
    case roofLine = "roof_line"
    case electricalPanel = "electrical_panel"
    case workArea = "work_area"

    var displayName: String {
        switch self {
        case .frontOfHouse:
            return "Front of House"
        case .rearElevation:
            return "Rear Elevation"
        case .roofLine:
            return "Roof Line"
        case .electricalPanel:
            return "Electrical Panel"
        case .workArea:
            return "Work Area"
        }
    }
}

enum ExteriorFinishArea: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case postsColumns = "posts_columns"
    case exteriorHouseWall = "exterior_house_wall"

    var displayName: String {
        switch self {
        case .postsColumns:
            return "Posts/Columns"
        case .exteriorHouseWall:
            return "Exterior House Wall"
        }
    }
}

enum PostsColumnsMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case wood
    case brick
    case stone
    case hardie
}

enum ExteriorHouseWallMaterial: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case wood
    case vinyl
    case brick
    case stone
    case hardie
    case lpSiding = "lp_siding"
    case other

    var displayName: String {
        switch self {
        case .lpSiding:
            return "LP Siding"
        default:
            return rawValue
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
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

enum StructuralSystemType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case insulatedAluminumPatioCover = "insulated_aluminum_patio_cover"
    case pergola
    case none
    case other

    var displayName: String {
        switch self {
        case .insulatedAluminumPatioCover: return "Insulated Aluminum Patio Cover"
        case .pergola: return "Pergola"
        case .none: return "None"
        case .other: return "Other"
        }
    }
}

enum PatioCoverRoofType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case shingles
    case rollRoofing = "roll_roofing"

    var displayName: String {
        switch self {
        case .shingles: return "Shingles"
        case .rollRoofing: return "Roll Roofing"
        }
    }
}

enum PergolaType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case motorizedLouveredPergola = "motorized_louvered_pergola"
    case manuallyRetractableLouveredPergola = "manually_retractable_louvered_pergola"
    case cedarPergola = "cedar_pergola"
    case alumawoodPergola = "alumawood_pergola"

    var displayName: String {
        switch self {
        case .motorizedLouveredPergola: return "Motorized Louvered Pergola"
        case .manuallyRetractableLouveredPergola: return "Manually Retractable Louvered Pergola"
        case .cedarPergola: return "Cedar Pergola"
        case .alumawoodPergola: return "Alumawood Pergola"
        }
    }
}

enum CedarPergolaPostSize: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case fourByFour = "4x4"
    case sixBySix = "6x6"
    case other

    var displayName: String {
        switch self {
        case .fourByFour: return "4x4"
        case .sixBySix: return "6x6"
        case .other: return "Other"
        }
    }
}

enum CedarPergolaBeamSize: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case twoByEight = "2x8"
    case other

    var displayName: String {
        switch self {
        case .twoByEight: return "2x8"
        case .other: return "Other"
        }
    }
}

enum CedarPergolaRafterSize: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case twoBySix = "2x6"
    case other

    var displayName: String {
        switch self {
        case .twoBySix: return "2x6"
        case .other: return "Other"
        }
    }
}

enum CedarPergolaLattice: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case twoByTwo = "2x2"
    case twoByFour = "2x4"

    var displayName: String {
        switch self {
        case .twoByTwo: return "2x2"
        case .twoByFour: return "2x4"
        }
    }
}

enum CedarPergolaHardware: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case galvanized
    case ornamental
}

enum CedarPergolaFinish: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case stained
    case painted
}

enum AlumawoodPergolaMountType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case freestanding
    case attached
}

enum AlumawoodPergolaAttachmentType: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case isolatedFooting = "isolated_footing"
    case surfaceAttachment = "surface_attachment"

    var displayName: String {
        switch self {
        case .isolatedFooting: return "Isolated Footing"
        case .surfaceAttachment: return "Surface Attachment"
        }
    }
}

enum AlumawoodPergolaColor: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case white
    case desertSand = "desert_sand"
    case mojave
    case tan
    case latte
    case adobe
    case spanishBrown = "spanish_brown"
    case graphite

    var displayName: String {
        switch self {
        case .white: return "White"
        case .desertSand: return "Desert Sand"
        case .mojave: return "Mojave"
        case .tan: return "Tan"
        case .latte: return "Latte"
        case .adobe: return "Adobe"
        case .spanishBrown: return "Spanish Brown"
        case .graphite: return "Graphite"
        }
    }
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
    case suntexSolarScreen = "suntex_solar_screen"
    case other

    var displayName: String {
        switch self {
        case .standardFiberglass1814: return "18x14 Standard Fiberglass"
        case .noSeeUm2020: return "20x20 No-See-Um"
        case .tuff1814: return "18x14 Tuff"
        case .tuff2020: return "20x20 Tuff"
        case .suntexSolarScreen: return "Suntex Solar Screen"
        case .other: return "Other"
        }
    }
}

enum ScreenTintOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case percent95 = "95%"
    case percent99 = "99%"
}

enum ScreenFrameSizeOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case twoInchFrame = "2_in_frame"
    case threeInchFrame = "3_in_frame"

    var displayName: String {
        switch self {
        case .twoInchFrame: return "2\" Frame"
        case .threeInchFrame: return "3\" Frame"
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

enum EnclosureScreenFrameColorOption: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case white
    case black
    case bronze
    case almond
    case clay
    case legacyBeige = "beige"
    case legacyKhaki = "khaki"
    case legacyOther = "other"

    static var allCases: [EnclosureScreenFrameColorOption] {
        [.white, .black, .bronze, .almond, .clay]
    }

    var displayName: String {
        switch self {
        case .legacyBeige:
            return "Almond"
        case .legacyKhaki:
            return "Clay"
        case .legacyOther:
            return "Other"
        default:
            return rawValue.capitalized
        }
    }
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
    var unitNumber: String?
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
        unitNumber: String? = nil,
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
        self.unitNumber = unitNumber
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

    var formattedAddressLine: String? {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedUnitNumber = unitNumber?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        switch (trimmedAddress, trimmedUnitNumber) {
        case let (address?, unitNumber?):
            return "\(address), \(unitNumber)"
        case let (address?, nil):
            return address
        case let (nil, unitNumber?):
            return unitNumber
        case (nil, nil):
            return nil
        }
    }
}

struct ExistingConditionsExteriorFinish: Codable, Hashable {
    var selectedAreas: [ExteriorFinishArea]?
    var postsColumnsMaterials: [PostsColumnsMaterial]?
    var postTrim: Bool?
    var trimThickness: String?
    var exteriorHouseWallMaterials: [ExteriorHouseWallMaterial]?
    var exteriorHouseWallOther: String?

    var activeSelectedAreas: [ExteriorFinishArea] {
        Self.normalizedAreas(selectedAreas) ?? []
    }

    var postsColumnsMaterialDisplaySummary: String? {
        Self.displaySummary(Self.normalizedPostsColumnsMaterials(postsColumnsMaterials))
    }

    var exteriorHouseWallMaterialDisplaySummary: String? {
        Self.displaySummary(Self.normalizedExteriorHouseWallMaterials(exteriorHouseWallMaterials))
    }

    var displaySummary: String? {
        let names = activeSelectedAreas.map(\.displayName)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: ", ")
    }

    var isEffectivelyEmpty: Bool {
        activeSelectedAreas.isEmpty &&
        postsColumnsMaterials == nil &&
        postTrim == nil &&
        trimThickness?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        exteriorHouseWallMaterials == nil &&
        exteriorHouseWallOther?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }

    var hasPostsColumnsSelection: Bool {
        activeSelectedAreas.contains(.postsColumns)
    }

    var hasExteriorHouseWallSelection: Bool {
        activeSelectedAreas.contains(.exteriorHouseWall)
    }

    var hasExteriorHouseWallOtherSelection: Bool {
        hasExteriorHouseWallSelection &&
        (Self.normalizedExteriorHouseWallMaterials(exteriorHouseWallMaterials) ?? []).contains(.other)
    }

    init(
        selectedAreas: [ExteriorFinishArea]? = nil,
        postsColumnsMaterials: [PostsColumnsMaterial]? = nil,
        postTrim: Bool? = nil,
        trimThickness: String? = nil,
        exteriorHouseWallMaterials: [ExteriorHouseWallMaterial]? = nil,
        exteriorHouseWallOther: String? = nil
    ) {
        self.selectedAreas = Self.normalizedAreas(selectedAreas)
        self.postsColumnsMaterials = Self.normalizedPostsColumnsMaterials(postsColumnsMaterials)
        self.postTrim = postTrim
        self.trimThickness = trimThickness?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.exteriorHouseWallMaterials = Self.normalizedExteriorHouseWallMaterials(exteriorHouseWallMaterials)
        self.exteriorHouseWallOther = exteriorHouseWallOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    mutating func setArea(_ area: ExteriorFinishArea, isSelected: Bool) {
        var selected = activeSelectedAreas
        if isSelected {
            guard !selected.contains(area) else { return }
            selected.append(area)
        } else {
            selected.removeAll { $0 == area }
        }
        selectedAreas = Self.normalizedAreas(selected)
    }

    mutating func setPostsColumnsMaterial(_ material: PostsColumnsMaterial, isSelected: Bool) {
        var selected = Self.normalizedPostsColumnsMaterials(postsColumnsMaterials) ?? []
        if isSelected {
            guard !selected.contains(material) else { return }
            selected.append(material)
        } else {
            selected.removeAll { $0 == material }
        }
        postsColumnsMaterials = Self.normalizedPostsColumnsMaterials(selected)
    }

    mutating func setExteriorHouseWallMaterial(_ material: ExteriorHouseWallMaterial, isSelected: Bool) {
        var selected = Self.normalizedExteriorHouseWallMaterials(exteriorHouseWallMaterials) ?? []
        if isSelected {
            guard !selected.contains(material) else { return }
            selected.append(material)
        } else {
            selected.removeAll { $0 == material }
        }
        exteriorHouseWallMaterials = Self.normalizedExteriorHouseWallMaterials(selected)
    }

    mutating func pruneInactiveDependentValuesForExport() {
        selectedAreas = Self.normalizedAreas(selectedAreas)

        if !hasPostsColumnsSelection {
            postsColumnsMaterials = nil
            postTrim = nil
            trimThickness = nil
        } else {
            postsColumnsMaterials = Self.normalizedPostsColumnsMaterials(postsColumnsMaterials)
            trimThickness = trimThickness?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }

        if !hasExteriorHouseWallSelection {
            exteriorHouseWallMaterials = nil
            exteriorHouseWallOther = nil
        } else {
            exteriorHouseWallMaterials = Self.normalizedExteriorHouseWallMaterials(exteriorHouseWallMaterials)
            if !hasExteriorHouseWallOtherSelection {
                exteriorHouseWallOther = nil
            } else {
                exteriorHouseWallOther = exteriorHouseWallOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            }
        }
    }

    func normalizedForExport() -> ExistingConditionsExteriorFinish? {
        var normalized = self
        normalized.pruneInactiveDependentValuesForExport()
        return normalized.isEffectivelyEmpty ? nil : normalized
    }

    private static func normalizedAreas(_ areas: [ExteriorFinishArea]?) -> [ExteriorFinishArea]? {
        guard let areas else { return nil }
        let active = ExteriorFinishArea.allCases.filter { areas.contains($0) }
        return active.isEmpty ? nil : active
    }

    private static func normalizedPostsColumnsMaterials(_ materials: [PostsColumnsMaterial]?) -> [PostsColumnsMaterial]? {
        guard let materials else { return nil }
        let active = PostsColumnsMaterial.allCases.filter { materials.contains($0) }
        return active.isEmpty ? nil : active
    }

    private static func normalizedExteriorHouseWallMaterials(_ materials: [ExteriorHouseWallMaterial]?) -> [ExteriorHouseWallMaterial]? {
        guard let materials else { return nil }
        let active = ExteriorHouseWallMaterial.allCases.filter { materials.contains($0) }
        return active.isEmpty ? nil : active
    }

    private static func displaySummary<Option: SchemaEnumDisplayable>(_ values: [Option]?) -> String? {
        let names = (values ?? []).map(\.displayName)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: ", ")
    }
}

struct ExistingConditions: Codable, Hashable {
    var houseStories: HouseStories?
    var exteriorFinish: ExistingConditionsExteriorFinish?
    var existingStructure: [ExistingStructure]?
    var obstaclesNotes: String?
    var utilitiesNotes: String?
    var hoaNotes: String?
    var photoChecklist: PhotoChecklist?

    var activeExistingStructures: [ExistingStructure] {
        Self.normalizedExistingStructures(existingStructure) ?? []
    }

    var existingStructureDisplaySummary: String? {
        let names = activeExistingStructures.map(\.displayName)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: ", ")
    }

    var isEffectivelyEmpty: Bool {
        houseStories == nil &&
        exteriorFinish == nil &&
        activeExistingStructures.isEmpty &&
        obstaclesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        utilitiesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        hoaNotes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        photoChecklist == nil
    }

    init(
        houseStories: HouseStories? = nil,
        exteriorFinish: ExistingConditionsExteriorFinish? = nil,
        existingStructure: [ExistingStructure]? = nil,
        obstaclesNotes: String? = nil,
        utilitiesNotes: String? = nil,
        hoaNotes: String? = nil,
        photoChecklist: PhotoChecklist? = nil
    ) {
        self.houseStories = houseStories
        self.exteriorFinish = exteriorFinish?.isEffectivelyEmpty == true ? nil : exteriorFinish
        self.existingStructure = Self.normalizedExistingStructures(existingStructure)
        self.obstaclesNotes = obstaclesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.utilitiesNotes = utilitiesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.hoaNotes = hoaNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.photoChecklist = photoChecklist?.isEffectivelyEmpty == true ? nil : photoChecklist
    }

    mutating func setExistingStructure(_ structure: ExistingStructure, isSelected: Bool) {
        var selected = activeExistingStructures
        if isSelected {
            guard !selected.contains(structure) else { return }
            selected.append(structure)
        } else {
            selected.removeAll { $0 == structure }
        }
        existingStructure = Self.normalizedExistingStructures(selected)
    }

    mutating func pruneInactiveDependentValuesForExport() {
        if var finish = exteriorFinish {
            finish.pruneInactiveDependentValuesForExport()
            exteriorFinish = finish.isEffectivelyEmpty ? nil : finish
        }

        existingStructure = Self.normalizedExistingStructures(existingStructure)
        obstaclesNotes = obstaclesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        utilitiesNotes = utilitiesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        hoaNotes = hoaNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        photoChecklist = nil
    }

    func normalizedForExport() -> ExistingConditions? {
        var normalized = self
        normalized.pruneInactiveDependentValuesForExport()
        return normalized.isEffectivelyEmpty ? nil : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case houseStories
        case exteriorFinish
        case existingStructure
        case obstaclesNotes
        case utilitiesNotes
        case hoaNotes
        case photoChecklist
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        houseStories = try container.decodeIfPresent(HouseStories.self, forKey: .houseStories)
        obstaclesNotes = try container.decodeIfPresent(String.self, forKey: .obstaclesNotes)
        utilitiesNotes = try container.decodeIfPresent(String.self, forKey: .utilitiesNotes)
        hoaNotes = try container.decodeIfPresent(String.self, forKey: .hoaNotes)
        let decodedChecklist = try container.decodeIfPresent(PhotoChecklist.self, forKey: .photoChecklist)
        photoChecklist = decodedChecklist?.isEffectivelyEmpty == true ? nil : decodedChecklist

        if let decodedFinish = try container.decodeIfPresent(ExistingConditionsExteriorFinish.self, forKey: .exteriorFinish) {
            exteriorFinish = decodedFinish.isEffectivelyEmpty ? nil : decodedFinish
        } else {
            let legacyFinish = try container.decodeIfPresent(ExteriorFinish.self, forKey: .exteriorFinish)
            exteriorFinish = Self.legacyExteriorFinishValue(from: legacyFinish)
        }

        if let decodedExistingStructure = try container.decodeIfPresent([ExistingStructure].self, forKey: .existingStructure) {
            existingStructure = Self.normalizedExistingStructures(decodedExistingStructure)
        } else {
            let legacyExistingStructure = try container.decodeIfPresent(ExistingStructure.self, forKey: .existingStructure)
            existingStructure = Self.normalizedExistingStructures(legacyExistingStructure.map { [$0] })
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(houseStories, forKey: .houseStories)
        try container.encodeIfPresent(exteriorFinish, forKey: .exteriorFinish)
        try container.encodeIfPresent(Self.normalizedExistingStructures(existingStructure), forKey: .existingStructure)
        try container.encodeIfPresent(obstaclesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .obstaclesNotes)
        try container.encodeIfPresent(utilitiesNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .utilitiesNotes)
        try container.encodeIfPresent(hoaNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .hoaNotes)
        try container.encodeIfPresent(photoChecklist?.isEffectivelyEmpty == true ? nil : photoChecklist, forKey: .photoChecklist)
    }

    private static func normalizedExistingStructures(_ values: [ExistingStructure]?) -> [ExistingStructure]? {
        guard let values else { return nil }
        let active = ExistingStructure.allCases.filter { values.contains($0) }
        return active.isEmpty ? nil : active
    }

    private static func legacyExteriorFinishValue(from value: ExteriorFinish?) -> ExistingConditionsExteriorFinish? {
        guard let value else { return nil }

        switch value {
        case .brick:
            return ExistingConditionsExteriorFinish(
                selectedAreas: [.exteriorHouseWall],
                exteriorHouseWallMaterials: [.brick]
            )
        case .hardie:
            return ExistingConditionsExteriorFinish(
                selectedAreas: [.exteriorHouseWall],
                exteriorHouseWallMaterials: [.hardie]
            )
        case .stone:
            return ExistingConditionsExteriorFinish(
                selectedAreas: [.exteriorHouseWall],
                exteriorHouseWallMaterials: [.stone]
            )
        case .other:
            return ExistingConditionsExteriorFinish(
                selectedAreas: [.exteriorHouseWall],
                exteriorHouseWallMaterials: [.other]
            )
        case .stucco:
            return ExistingConditionsExteriorFinish(
                selectedAreas: [.exteriorHouseWall],
                exteriorHouseWallMaterials: [.other],
                exteriorHouseWallOther: "Stucco"
            )
        }
    }
}

struct PhotoChecklist: Codable, Hashable {
    var frontOfHouse: Bool?
    var rearElevation: Bool?
    var roofLine: Bool?
    var electricalPanel: Bool?
    var workArea: Bool?

    var isEffectivelyEmpty: Bool {
        frontOfHouse == nil &&
        rearElevation == nil &&
        roofLine == nil &&
        electricalPanel == nil &&
        workArea == nil
    }
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

struct InsulatedAluminumPatioCoverDetails: Codable, Hashable {
    var width: String?
    var projection: String?
    var numberOfPosts: String?
    var roofType: PatioCoverRoofType?

    var isEffectivelyEmpty: Bool {
        width?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        projection?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        numberOfPosts?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        roofType == nil
    }

    mutating func pruneForExport() {
        width = width?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        projection = projection?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        numberOfPosts = numberOfPosts?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var detailSummary: String? {
        structuralSummaryParts([
            labeledStructuralValue("Width", width),
            labeledStructuralValue("Projection", projection),
            labeledStructuralValue("Number of Posts", numberOfPosts),
            labeledStructuralValue("Roof Type", roofType?.displayName)
        ])
    }
}

struct PergolaDimensionDetails: Codable, Hashable {
    var width: String?
    var length: String?
    var height: String?
    var notes: String?

    var isEffectivelyEmpty: Bool {
        width?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        length?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        height?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }

    mutating func pruneForExport() {
        width = width?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        length = length?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        height = height?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var dimensionSummary: String? {
        structuralSummaryParts([
            labeledStructuralValue("Width", width),
            labeledStructuralValue("Length", length),
            labeledStructuralValue("Height", height)
        ])
    }
}

struct CedarPergolaDetails: Codable, Hashable {
    var postSize: CedarPergolaPostSize?
    var postSizeOther: String?
    var beamSize: CedarPergolaBeamSize?
    var beamSizeOther: String?
    var rafterSize: CedarPergolaRafterSize?
    var rafterSizeOther: String?
    var lattice: CedarPergolaLattice?
    var hardware: CedarPergolaHardware?
    var finish: CedarPergolaFinish?
    var productCode: String?

    var isEffectivelyEmpty: Bool {
        postSize == nil &&
        postSizeOther?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        beamSize == nil &&
        beamSizeOther?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        rafterSize == nil &&
        rafterSizeOther?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        lattice == nil &&
        hardware == nil &&
        finish == nil &&
        productCode?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }

    mutating func pruneForExport() {
        if postSize != .other {
            postSizeOther = nil
        } else {
            postSizeOther = postSizeOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }

        if beamSize != .other {
            beamSizeOther = nil
        } else {
            beamSizeOther = beamSizeOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }

        if rafterSize != .other {
            rafterSizeOther = nil
        } else {
            rafterSizeOther = rafterSizeOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }

        productCode = productCode?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var detailSummary: String? {
        structuralSummaryParts([
            labeledStructuralValue("Post Size", resolvedPostSize),
            labeledStructuralValue("Beam Size", resolvedBeamSize),
            labeledStructuralValue("Rafter Size", resolvedRafterSize),
            labeledStructuralValue("Lattice", lattice?.displayName),
            labeledStructuralValue("Hardware", hardware?.displayName),
            labeledStructuralValue("Finish", finish?.displayName),
            labeledStructuralValue("Product Code", productCode)
        ])
    }

    var resolvedPostSize: String? {
        postSize == .other ? (postSizeOther?.nilIfBlank ?? postSize?.displayName) : postSize?.displayName
    }

    var resolvedBeamSize: String? {
        beamSize == .other ? (beamSizeOther?.nilIfBlank ?? beamSize?.displayName) : beamSize?.displayName
    }

    var resolvedRafterSize: String? {
        rafterSize == .other ? (rafterSizeOther?.nilIfBlank ?? rafterSize?.displayName) : rafterSize?.displayName
    }
}

struct AlumawoodPergolaDetails: Codable, Hashable {
    var mountType: AlumawoodPergolaMountType?
    var width: String?
    var length: String?
    var height: String?
    var attachmentType: AlumawoodPergolaAttachmentType?
    var color: AlumawoodPergolaColor?
    var privacyWall: Bool?

    var isEffectivelyEmpty: Bool {
        mountType == nil &&
        width?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        length?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        height?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        attachmentType == nil &&
        color == nil &&
        privacyWall == nil
    }

    mutating func pruneForExport() {
        width = width?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        length = length?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        height = height?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var layoutSummary: String? {
        structuralSummaryParts([
            labeledStructuralValue("Width", width),
            labeledStructuralValue("Length", length),
            labeledStructuralValue("Height", height)
        ])
    }

    var detailSummary: String? {
        let privacyWallSummary = privacyWall.map { $0 ? "Yes" : "No" }

        return structuralSummaryParts([
            labeledStructuralValue("Mount Type", mountType?.displayName),
            layoutSummary,
            labeledStructuralValue("Attachment Type", attachmentType?.displayName),
            labeledStructuralValue("Color", color?.displayName),
            labeledStructuralValue("Privacy Wall", privacyWallSummary)
        ])
    }
}

struct StructuralSystem: Codable, Hashable {
    var systemType: StructuralSystemType?
    var systemTypeOther: String?
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

    var hasLegacyFlatValues: Bool {
        frameMaterial != nil ||
        postSize?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
        beamType?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
        roofSystem != nil ||
        roofColor?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
        frameColor?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var legacyFlatSummary: String? {
        structuralSummaryParts([
            labeledStructuralValue("Frame Material", frameMaterial?.displayName),
            labeledStructuralValue("Post Size", postSize),
            labeledStructuralValue("Beam Type", beamType),
            labeledStructuralValue("Roof System", roofSystem?.displayName),
            labeledStructuralValue("Roof Color", roofColor),
            labeledStructuralValue("Frame Color", frameColor)
        ])
    }

    var resolvedSelectionDisplayName: String? {
        if let systemType {
            if systemType == .other {
                return systemTypeOther?.nilIfBlank ?? systemType.displayName
            }
            return systemType.displayName
        }
        return nil
    }

    var resolvedDetailSummary: String? {
        switch systemType {
        case .some(.insulatedAluminumPatioCover):
            return insulatedAluminumPatioCover?.detailSummary
        case .some(.pergola):
            switch pergolaType {
            case .some(.motorizedLouveredPergola):
                return motorizedLouveredPergola?.dimensionSummary
            case .some(.manuallyRetractableLouveredPergola):
                return manuallyRetractableLouveredPergola?.dimensionSummary
            case .some(.cedarPergola):
                return cedarPergola?.detailSummary
            case .some(.alumawoodPergola):
                return alumawoodPergola?.detailSummary
            case .none:
                return nil
            }
        case .some(.none), .some(.other), nil:
            return nil
        }
    }

    var resolvedPergolaNotes: String? {
        guard systemType == .pergola else { return nil }

        switch pergolaType {
        case .motorizedLouveredPergola:
            return motorizedLouveredPergola?.notes?.nilIfBlank
        case .manuallyRetractableLouveredPergola:
            return manuallyRetractableLouveredPergola?.notes?.nilIfBlank
        default:
            return nil
        }
    }

    var isEffectivelyEmpty: Bool {
        systemType == nil &&
        systemTypeOther?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        insulatedAluminumPatioCover == nil &&
        pergolaType == nil &&
        motorizedLouveredPergola == nil &&
        manuallyRetractableLouveredPergola == nil &&
        cedarPergola == nil &&
        alumawoodPergola == nil &&
        !hasLegacyFlatValues &&
        notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }

    mutating func pruneInactiveDependentValuesForExport() {
        notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        systemTypeOther = systemTypeOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if systemType != .other {
            systemTypeOther = nil
        }

        if systemType == .insulatedAluminumPatioCover {
            insulatedAluminumPatioCover?.pruneForExport()
            insulatedAluminumPatioCover = insulatedAluminumPatioCover?.isEffectivelyEmpty == true ? nil : insulatedAluminumPatioCover
            pergolaType = nil
            motorizedLouveredPergola = nil
            manuallyRetractableLouveredPergola = nil
            cedarPergola = nil
            alumawoodPergola = nil
        } else if systemType == .pergola {
            insulatedAluminumPatioCover = nil

            switch pergolaType {
            case .motorizedLouveredPergola:
                motorizedLouveredPergola?.pruneForExport()
                motorizedLouveredPergola = motorizedLouveredPergola?.isEffectivelyEmpty == true ? nil : motorizedLouveredPergola
                manuallyRetractableLouveredPergola = nil
                cedarPergola = nil
                alumawoodPergola = nil
            case .manuallyRetractableLouveredPergola:
                manuallyRetractableLouveredPergola?.pruneForExport()
                manuallyRetractableLouveredPergola = manuallyRetractableLouveredPergola?.isEffectivelyEmpty == true ? nil : manuallyRetractableLouveredPergola
                motorizedLouveredPergola = nil
                cedarPergola = nil
                alumawoodPergola = nil
            case .cedarPergola:
                cedarPergola?.pruneForExport()
                cedarPergola = cedarPergola?.isEffectivelyEmpty == true ? nil : cedarPergola
                motorizedLouveredPergola = nil
                manuallyRetractableLouveredPergola = nil
                alumawoodPergola = nil
            case .alumawoodPergola:
                alumawoodPergola?.pruneForExport()
                alumawoodPergola = alumawoodPergola?.isEffectivelyEmpty == true ? nil : alumawoodPergola
                motorizedLouveredPergola = nil
                manuallyRetractableLouveredPergola = nil
                cedarPergola = nil
            case .none:
                motorizedLouveredPergola = nil
                manuallyRetractableLouveredPergola = nil
                cedarPergola = nil
                alumawoodPergola = nil
            }
        } else {
            insulatedAluminumPatioCover = nil
            pergolaType = nil
            motorizedLouveredPergola = nil
            manuallyRetractableLouveredPergola = nil
            cedarPergola = nil
            alumawoodPergola = nil
        }

        if systemType != nil {
            frameMaterial = nil
            postSize = nil
            beamType = nil
            roofSystem = nil
            roofColor = nil
            frameColor = nil
        } else {
            postSize = postSize?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            beamType = beamType?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            roofColor = roofColor?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            frameColor = frameColor?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
    }

    func normalizedForExport() -> StructuralSystem? {
        var normalized = self
        normalized.pruneInactiveDependentValuesForExport()
        return normalized.isEffectivelyEmpty ? nil : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case systemType
        case systemTypeOther
        case insulatedAluminumPatioCover
        case pergolaType
        case motorizedLouveredPergola
        case manuallyRetractableLouveredPergola
        case cedarPergola
        case alumawoodPergola
        case frameMaterial
        case postSize
        case beamType
        case roofSystem
        case roofColor
        case frameColor
        case notes
    }

    init(
        systemType: StructuralSystemType? = nil,
        systemTypeOther: String? = nil,
        insulatedAluminumPatioCover: InsulatedAluminumPatioCoverDetails? = nil,
        pergolaType: PergolaType? = nil,
        motorizedLouveredPergola: PergolaDimensionDetails? = nil,
        manuallyRetractableLouveredPergola: PergolaDimensionDetails? = nil,
        cedarPergola: CedarPergolaDetails? = nil,
        alumawoodPergola: AlumawoodPergolaDetails? = nil,
        frameMaterial: FrameMaterial? = nil,
        postSize: String? = nil,
        beamType: String? = nil,
        roofSystem: RoofSystem? = nil,
        roofColor: String? = nil,
        frameColor: String? = nil,
        notes: String? = nil
    ) {
        self.systemType = systemType
        self.systemTypeOther = systemTypeOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.insulatedAluminumPatioCover = insulatedAluminumPatioCover?.isEffectivelyEmpty == true ? nil : insulatedAluminumPatioCover
        self.pergolaType = pergolaType
        self.motorizedLouveredPergola = motorizedLouveredPergola?.isEffectivelyEmpty == true ? nil : motorizedLouveredPergola
        self.manuallyRetractableLouveredPergola = manuallyRetractableLouveredPergola?.isEffectivelyEmpty == true ? nil : manuallyRetractableLouveredPergola
        self.cedarPergola = cedarPergola?.isEffectivelyEmpty == true ? nil : cedarPergola
        self.alumawoodPergola = alumawoodPergola?.isEffectivelyEmpty == true ? nil : alumawoodPergola
        self.frameMaterial = frameMaterial
        self.postSize = postSize?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.beamType = beamType?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.roofSystem = roofSystem
        self.roofColor = roofColor?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.frameColor = frameColor?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        systemType = try container.decodeIfPresent(StructuralSystemType.self, forKey: .systemType)
        systemTypeOther = try container.decodeIfPresent(String.self, forKey: .systemTypeOther)
        insulatedAluminumPatioCover = try container.decodeIfPresent(InsulatedAluminumPatioCoverDetails.self, forKey: .insulatedAluminumPatioCover)
        pergolaType = try container.decodeIfPresent(PergolaType.self, forKey: .pergolaType)
        motorizedLouveredPergola = try container.decodeIfPresent(PergolaDimensionDetails.self, forKey: .motorizedLouveredPergola)
        manuallyRetractableLouveredPergola = try container.decodeIfPresent(PergolaDimensionDetails.self, forKey: .manuallyRetractableLouveredPergola)
        cedarPergola = try container.decodeIfPresent(CedarPergolaDetails.self, forKey: .cedarPergola)
        alumawoodPergola = try container.decodeIfPresent(AlumawoodPergolaDetails.self, forKey: .alumawoodPergola)
        frameMaterial = try container.decodeIfPresent(FrameMaterial.self, forKey: .frameMaterial)
        postSize = try container.decodeIfPresent(String.self, forKey: .postSize)
        beamType = try container.decodeIfPresent(String.self, forKey: .beamType)
        roofSystem = try container.decodeIfPresent(RoofSystem.self, forKey: .roofSystem)
        roofColor = try container.decodeIfPresent(String.self, forKey: .roofColor)
        frameColor = try container.decodeIfPresent(String.self, forKey: .frameColor)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(systemType, forKey: .systemType)
        try container.encodeIfPresent(systemTypeOther?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .systemTypeOther)
        try container.encodeIfPresent(insulatedAluminumPatioCover?.isEffectivelyEmpty == true ? nil : insulatedAluminumPatioCover, forKey: .insulatedAluminumPatioCover)
        try container.encodeIfPresent(pergolaType, forKey: .pergolaType)
        try container.encodeIfPresent(motorizedLouveredPergola?.isEffectivelyEmpty == true ? nil : motorizedLouveredPergola, forKey: .motorizedLouveredPergola)
        try container.encodeIfPresent(manuallyRetractableLouveredPergola?.isEffectivelyEmpty == true ? nil : manuallyRetractableLouveredPergola, forKey: .manuallyRetractableLouveredPergola)
        try container.encodeIfPresent(cedarPergola?.isEffectivelyEmpty == true ? nil : cedarPergola, forKey: .cedarPergola)
        try container.encodeIfPresent(alumawoodPergola?.isEffectivelyEmpty == true ? nil : alumawoodPergola, forKey: .alumawoodPergola)
        try container.encodeIfPresent(frameMaterial, forKey: .frameMaterial)
        try container.encodeIfPresent(postSize?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .postSize)
        try container.encodeIfPresent(beamType?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .beamType)
        try container.encodeIfPresent(roofSystem, forKey: .roofSystem)
        try container.encodeIfPresent(roofColor?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .roofColor)
        try container.encodeIfPresent(frameColor?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .frameColor)
        try container.encodeIfPresent(notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, forKey: .notes)
    }
}

struct Enclosure: Codable, Hashable {
    var enclosureTypes: [EnclosureType]?
    var screenWallType: ScreenWallType?
    var screenTint: ScreenTintOption?
    var screenFrameSize: ScreenFrameSizeOption?
    var screenFrameColor: EnclosureScreenFrameColorOption?
    var screenFrameColorCustom: String?
    var windowSystem: WindowSystem?
    var kneeWall: KneeWall?
    var doors: DoorOptions?

    var enclosureType: EnclosureType? {
        get { activeEnclosureTypes.first }
        set { enclosureTypes = Self.normalizedTypes(newValue.map { [$0] }) }
    }

    var activeEnclosureTypes: [EnclosureType] {
        Self.normalizedTypes(enclosureTypes) ?? []
    }

    var enclosureTypeDisplaySummary: String? {
        let names = activeEnclosureTypes.map(\.displayName)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: ", ")
    }

    var hasScreenEnclosureSelection: Bool {
        activeEnclosureTypes.contains { type in
            switch type {
            case .screenEnclosure, .mixed:
                return true
            default:
                return false
            }
        }
    }

    var isEffectivelyEmpty: Bool {
        activeEnclosureTypes.isEmpty &&
        screenWallType == nil &&
        screenTint == nil &&
        screenFrameSize == nil &&
        screenFrameColor == nil &&
        screenFrameColorCustom?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        windowSystem == nil &&
        kneeWall == nil &&
        doors == nil
    }

    init(
        enclosureTypes: [EnclosureType]? = nil,
        screenWallType: ScreenWallType? = nil,
        screenTint: ScreenTintOption? = nil,
        screenFrameSize: ScreenFrameSizeOption? = nil,
        screenFrameColor: EnclosureScreenFrameColorOption? = nil,
        screenFrameColorCustom: String? = nil,
        windowSystem: WindowSystem? = nil,
        kneeWall: KneeWall? = nil,
        doors: DoorOptions? = nil
    ) {
        self.enclosureTypes = Self.normalizedTypes(enclosureTypes)
        self.screenWallType = screenWallType
        self.screenTint = screenTint
        self.screenFrameSize = screenFrameSize
        self.screenFrameColor = screenFrameColor
        self.screenFrameColorCustom = screenFrameColorCustom
        self.windowSystem = windowSystem
        self.kneeWall = kneeWall
        self.doors = doors
    }

    mutating func pruneInactiveDependentValuesForExport() {
        enclosureTypes = Self.normalizedTypes(enclosureTypes)

        if !hasScreenEnclosureSelection {
            screenWallType = nil
            screenTint = nil
            screenFrameSize = nil
            screenFrameColor = nil
            screenFrameColorCustom = nil
        } else {
            if screenWallType != .suntexSolarScreen {
                screenTint = nil
            }

            if screenFrameColor != .legacyOther {
                screenFrameColorCustom = nil
            }
        }
    }

    mutating func setEnclosureType(_ type: EnclosureType, isSelected: Bool) {
        var selectedTypes = activeEnclosureTypes
        if isSelected {
            guard !selectedTypes.contains(type) else { return }
            selectedTypes.append(type)
        } else {
            selectedTypes.removeAll { $0 == type }
        }
        enclosureTypes = Self.normalizedTypes(selectedTypes)
    }

    func normalizedForExport() -> Enclosure? {
        var normalized = self
        normalized.pruneInactiveDependentValuesForExport()
        return normalized.isEffectivelyEmpty ? nil : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case enclosureTypes
        case enclosureType
        case screenWallType
        case screenTint
        case screenFrameSize
        case screenFrameColor
        case screenFrameColorCustom
        case windowSystem
        case kneeWall
        case doors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTypes = try container.decodeIfPresent([EnclosureType].self, forKey: .enclosureTypes)
        let legacyType = try container.decodeIfPresent(EnclosureType.self, forKey: .enclosureType)
        let selectedTypes = decodedTypes ?? legacyType.map { [$0] }

        enclosureTypes = Self.normalizedTypes(selectedTypes)
        screenWallType = try container.decodeIfPresent(ScreenWallType.self, forKey: .screenWallType)
        screenTint = try container.decodeIfPresent(ScreenTintOption.self, forKey: .screenTint)
        screenFrameSize = try container.decodeIfPresent(ScreenFrameSizeOption.self, forKey: .screenFrameSize)
        screenFrameColor = try container.decodeIfPresent(EnclosureScreenFrameColorOption.self, forKey: .screenFrameColor)
        screenFrameColorCustom = try container.decodeIfPresent(String.self, forKey: .screenFrameColorCustom)
        windowSystem = try container.decodeIfPresent(WindowSystem.self, forKey: .windowSystem)
        kneeWall = try container.decodeIfPresent(KneeWall.self, forKey: .kneeWall)
        doors = try container.decodeIfPresent(DoorOptions.self, forKey: .doors)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(Self.normalizedTypes(enclosureTypes), forKey: .enclosureTypes)
        try container.encodeIfPresent(screenWallType, forKey: .screenWallType)
        try container.encodeIfPresent(screenTint, forKey: .screenTint)
        try container.encodeIfPresent(screenFrameSize, forKey: .screenFrameSize)
        try container.encodeIfPresent(screenFrameColor, forKey: .screenFrameColor)
        try container.encodeIfPresent(screenFrameColorCustom, forKey: .screenFrameColorCustom)
        try container.encodeIfPresent(windowSystem, forKey: .windowSystem)
        try container.encodeIfPresent(kneeWall, forKey: .kneeWall)
        try container.encodeIfPresent(doors, forKey: .doors)
    }

    private static func normalizedTypes(_ types: [EnclosureType]?) -> [EnclosureType]? {
        guard let types else { return nil }
        let activeTypes = EnclosureType.allCases.filter { type in
            types.contains(type)
        }
        return activeTypes.isEmpty ? nil : activeTypes
    }
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
    var unitNumber: String?
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
        unitNumber: String? = nil,
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
        self.unitNumber = unitNumber
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

enum DocumentAttachmentSource: String, Codable, CaseIterable, SchemaEnumDisplayable {
    case files
    case photoLibrary = "photo_library"
    case camera

    var displayName: String {
        switch self {
        case .files: return "Files"
        case .photoLibrary: return "Photo Library"
        case .camera: return "Camera"
        }
    }
}

struct DocumentAttachmentFile: Codable, Hashable, Identifiable {
    var id: UUID
    var originalFilename: String
    var filePath: String
    var contentTypeIdentifier: String?
    var source: DocumentAttachmentSource
    var createdAt: Date

    init(
        id: UUID = UUID(),
        originalFilename: String,
        filePath: String,
        contentTypeIdentifier: String? = nil,
        source: DocumentAttachmentSource,
        createdAt: Date = .now
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.filePath = filePath
        self.contentTypeIdentifier = contentTypeIdentifier
        self.source = source
        self.createdAt = createdAt
    }
}

struct AdditionalDocumentAttachment: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String?
    var attachment: DocumentAttachmentFile?

    init(id: UUID = UUID(), name: String? = nil, attachment: DocumentAttachmentFile? = nil) {
        self.id = id
        self.name = name
        self.attachment = attachment
    }
}

struct DocumentsSection: Codable, Hashable {
    var irrigation: DocumentAttachmentFile?
    var propertySurvey: DocumentAttachmentFile?
    var additionalAttachments: [AdditionalDocumentAttachment]?
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
    var documentsPayload: Data?
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
        documents: DocumentsSection? = nil,
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
        self.documentsPayload = JobScope.encodeDocumentsPayload(documents)
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

    var editableScopeTitle: String {
        scopeTitle ?? ""
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

    var documents: DocumentsSection? {
        get {
            JobScope.decodeDocumentsPayload(documentsPayload)
        }
        set {
            documentsPayload = JobScope.encodeDocumentsPayload(newValue)
        }
    }

    private static func decodeDocumentsPayload(_ payload: Data?) -> DocumentsSection? {
        guard let payload, !payload.isEmpty else { return nil }

        do {
            return try JSONDecoder().decode(DocumentsSection.self, from: payload)
        } catch {
            assertionFailure("Failed to decode documents payload: \(error)")
            return nil
        }
    }

    private static func encodeDocumentsPayload(_ documents: DocumentsSection?) -> Data? {
        guard let documents else { return nil }

        let isEffectivelyEmpty =
            documents.irrigation == nil &&
            documents.propertySurvey == nil &&
            (documents.additionalAttachments ?? []).isEmpty

        guard !isEffectivelyEmpty else { return nil }

        do {
            return try JSONEncoder().encode(documents)
        } catch {
            assertionFailure("Failed to encode documents payload: \(error)")
            return nil
        }
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

    func setEditableScopeTitle(_ newTitle: String) {
        scopeTitle = newTitle.isEmpty ? nil : newTitle
        updatedAt = .now
    }

    var hasLinkedJobTreadCustomer: Bool {
        jobTreadCustomer != nil
    }

    func applyLinkedCustomerHydration(_ detail: JobTreadCustomerDetail) {
        let trimmedName = detail.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedAddress = detail.primaryAddress?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedUnitNumber = detail.unitNumber?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedAccountType = detail.accountType?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedCity = detail.city?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedState = detail.state?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedZIP = detail.postalCode?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if jobTreadCustomer != nil {
            jobTreadCustomer?.displayName = trimmedName
            jobTreadCustomer?.accountType = trimmedAccountType
            jobTreadCustomer?.primaryAddress = trimmedAddress
            jobTreadCustomer?.unitNumber = trimmedUnitNumber
            jobTreadCustomer?.city = trimmedCity
            jobTreadCustomer?.state = trimmedState
            jobTreadCustomer?.postalCode = trimmedZIP
            jobTreadCustomer?.fetchedAt = .now
        }

        projectInfo.clientName = trimmedName ?? ""
        projectInfo.address = trimmedAddress ?? ""
        projectInfo.unitNumber = trimmedUnitNumber
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

private func labeledStructuralValue(_ label: String, _ value: String?) -> String? {
    guard let value = value?.nilIfBlank else { return nil }
    return "\(label): \(value)"
}

private func structuralSummaryParts(_ parts: [String?]) -> String? {
    let values = parts.compactMap { $0?.nilIfBlank }
    guard !values.isEmpty else { return nil }
    return values.joined(separator: " • ")
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var nilIfWhitespaceOnly: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
