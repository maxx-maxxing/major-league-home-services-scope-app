import Foundation

// This foundation keeps pricing/proposal structure out of Views and PDF rendering.
enum ScopeCaptureSectionKey: String, Codable, CaseIterable, Identifiable {
    case projectInfo
    case existingConditions
    case dimensions
    case structuralSystem
    case enclosure
    case electrical
    case drainage
    case attachmentConditions
    case documents
    case finishes
    case permitsHOA
    case production
    case attachmentsAndSketches

    var id: String { rawValue }

    var title: String {
        switch self {
        case .projectInfo: return "Project Information"
        case .existingConditions: return "Existing Conditions"
        case .dimensions: return "Dimensions"
        case .structuralSystem: return "Structural System"
        case .enclosure: return "Enclosure / Windows / Doors"
        case .electrical: return "Electrical"
        case .drainage: return "Drainage"
        case .attachmentConditions: return "Attachment Conditions"
        case .documents: return "Documents"
        case .finishes: return "Finishes"
        case .permitsHOA: return "Permits / HOA"
        case .production: return "Production"
        case .attachmentsAndSketches: return "Photos / Sketches / Signatures"
        }
    }
}

enum ScopeInputKey: String, Codable, CaseIterable, Identifiable {
    case scopeTitle
    case customerName
    case linkedCustomerID
    case addressLine
    case cityStateZIP
    case phone
    case email
    case salesperson
    case estimator
    case projectType
    case siteVisitDate
    case projectNotes
    case houseStories
    case exteriorFinish
    case existingStructure
    case obstaclesNotes
    case utilitiesNotes
    case hoaNotes
    case photoChecklist
    case widthFeet
    case projectionFeet
    case fasciaHeightFeet
    case beamHeightFeet
    case roofStyle
    case attachmentType
    case elevationNotes
    case frameMaterial
    case structuralPostSize
    case beamType
    case roofSystem
    case roofColor
    case frameColor
    case structuralNotes
    case enclosureType
    case screenWallType
    case screenTint
    case screenFrameSize
    case screenFrameColor
    case windowType
    case windowFrameSystem
    case glassType
    case glassSafety
    case gridOption
    case windowOperation
    case windowColor
    case windowHeight
    case windowBayCount
    case windowConfiguration
    case windowNotes
    case kneeWallOption
    case kneeWallPanelHeight
    case kneeWallPanelColor
    case kneeWallLinearFootage
    case kneeWallHeight
    case kneeWallFraming
    case doorType
    case doorStyle
    case doorOperableSide
    case doorHingeSide
    case doorWidth
    case doorHeight
    case doorColor
    case doorDimensions
    case doorNotes
    case outletCount
    case lighting
    case fanInstall
    case switchLocations
    case dedicatedCircuits
    case electricalNotes
    case gutters
    case downspoutLocations
    case drainTieIn
    case slopeNotes
    case houseWallMaterial
    case houseWallOther
    case houseMountingType
    case postColumnMaterial
    case postColumnOther
    case attachmentPostSize
    case postSpacing
    case trimPresent
    case trimMaterial
    case trimThickness
    case mountCondition
    case fastenerPlan
    case attachmentNotes
    case irrigationDocument
    case propertySurveyDocument
    case additionalDocumentCount
    case additionalDocumentNames
    case finishTrimType
    case finishColor
    case sidingReplacementRequired
    case caulkingSealingNotes
    case permitRequired
    case jurisdiction
    case hoaApprovalRequired
    case engineeringRequired
    case permitStatusNotes
    case productionStartDate
    case crewLead
    case durationEstimate
    case materialOrderStatus
    case permitStatus
    case customerOptionsConfirmed
    case signedDate
    case photoCount
    case sketchCount

    var id: String { rawValue }
}

enum ProposalTemplateSectionID: String, Codable, CaseIterable, Identifiable {
    case projectSummary
    case siteConditions
    case structuralSystem
    case enclosureAndOpenings
    case electricalAndDrainage
    case finishesAndPermitting
    case attachmentsAndSupportingDocuments

    var id: String { rawValue }
}

enum ProposalOutputChannel: String, Codable, CaseIterable {
    case customerFacing = "customer_facing"
    case internalOnly = "internal_only"
    case syncCandidate = "sync_candidate"
}

enum ProposalSectionVisibilityRule: String, Codable, CaseIterable {
    case always
    case whenAnyTriggerInputPresent
    case whenAnyTriggerValueAffirmativeOrMeaningful
    case whenProjectTypeIsSet
}

enum PricingCalculationStrategyKind: String, Codable, CaseIterable {
    case manualAmount
    case quantityTimesRate
    case allowance
    case lookupOnly
}

enum PricingQuantitySource: String, Codable, CaseIterable {
    case widthFeet
    case projectionFeet
    case areaSquareFeet
    case perimeterFeet
    case bayCount
    case outletCount
    case attachmentCount
}

enum FutureSyncTargetKind: String, Codable, CaseIterable {
    case jobField
    case costGroup
    case costItem
    case customField
    case document
}

enum ProposalPricingBucketState: String, Codable, CaseIterable {
    case excluded
    case placeholder
    case quantitySeeded
}

struct ProposalInputValue: Codable, Hashable, Identifiable {
    let key: ScopeInputKey
    let label: String
    let stringValue: String?
    let numericValue: Double?
    let boolValue: Bool?

    var id: ScopeInputKey { key }

    var displayValue: String {
        if let stringValue = stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !stringValue.isEmpty {
            return stringValue
        }

        if let numericValue {
            return ProposalFoundationFormatter.number.string(from: NSNumber(value: numericValue)) ?? "\(numericValue)"
        }

        if let boolValue {
            return boolValue ? "Yes" : "No"
        }

        return ""
    }

    var isMeaningful: Bool {
        !displayValue.isEmpty
    }
}

struct ScopeCaptureSectionSnapshot: Codable, Hashable, Identifiable {
    let section: ScopeCaptureSectionKey
    let values: [ProposalInputValue]

    var id: ScopeCaptureSectionKey { section }
}

struct ProposalCustomerContext: Codable, Hashable {
    let linkedCustomerID: String?
    let customerName: String?
    let scopeTitle: String?
    let projectType: ProjectType
}

struct ProposalCompositionInput: Codable, Hashable {
    let scopeID: UUID
    let templateID: String
    let templateVersion: Int
    let capturedAt: Date
    let customerContext: ProposalCustomerContext
    let sections: [ScopeCaptureSectionSnapshot]

    func values(for section: ScopeCaptureSectionKey) -> [ProposalInputValue] {
        sections.first(where: { $0.section == section })?.values ?? []
    }

    func value(for key: ScopeInputKey) -> ProposalInputValue? {
        sections.lazy
            .flatMap(\.values)
            .first(where: { $0.key == key })
    }

    func values(for keys: [ScopeInputKey]) -> [ProposalInputValue] {
        keys.compactMap(value(for:))
    }
}

struct FutureSyncTargetBlueprint: Codable, Hashable, Identifiable {
    let kind: FutureSyncTargetKind
    let targetKey: String
    let title: String
    let notes: String?

    var id: String { "\(kind.rawValue):\(targetKey)" }
}

struct ProposalVisibilityDefinition: Codable, Hashable {
    let rule: ProposalSectionVisibilityRule
    let triggerInputKeys: [ScopeInputKey]
}

struct ProposalTemplateSectionDefinition: Codable, Hashable, Identifiable {
    let id: ProposalTemplateSectionID
    let title: String
    let sourceSections: [ScopeCaptureSectionKey]
    let customerFacingInputKeys: [ScopeInputKey]
    let internalInputKeys: [ScopeInputKey]
    let visibility: ProposalVisibilityDefinition
    let relatedPricingGroupIDs: [String]
    let syncTargets: [FutureSyncTargetBlueprint]
}

struct PricingComponentDefinition: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let summary: String
    let mappedInputKeys: [ScopeInputKey]
    let visibility: ProposalVisibilityDefinition
    let quantitySource: PricingQuantitySource?
    let strategy: PricingCalculationStrategyKind
    let outputChannels: [ProposalOutputChannel]
    let syncTargets: [FutureSyncTargetBlueprint]
}

struct PricingGroupDefinition: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let sourceSections: [ScopeCaptureSectionKey]
    let outputChannels: [ProposalOutputChannel]
    let components: [PricingComponentDefinition]
}

struct ProposalTemplateDefinition: Codable, Hashable, Identifiable {
    let id: String
    let version: Int
    let name: String
    let sections: [ProposalTemplateSectionDefinition]
    let pricingGroups: [PricingGroupDefinition]
}

struct ComposedProposalSection: Codable, Hashable, Identifiable {
    let id: ProposalTemplateSectionID
    let title: String
    let isIncluded: Bool
    let inclusionReason: String
    let sourceSections: [ScopeCaptureSectionKey]
    let customerFacingValues: [ProposalInputValue]
    let internalValues: [ProposalInputValue]
    let relatedPricingGroupIDs: [String]
    let highlights: [String]
}

struct ComposedPricingComponent: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let summary: String
    let outputChannels: [ProposalOutputChannel]
    let strategy: PricingCalculationStrategyKind
    let inclusionReason: String
    let quantitySource: PricingQuantitySource?
    let quantityValue: Double?
    let mappedValues: [ProposalInputValue]
    let bucketState: ProposalPricingBucketState
    let isCandidate: Bool
}

struct ComposedPricingGroup: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let sourceSections: [ScopeCaptureSectionKey]
    let outputChannels: [ProposalOutputChannel]
    let isIncluded: Bool
    let components: [ComposedPricingComponent]
}

struct ProposalSyncCandidate: Codable, Hashable, Identifiable {
    let blueprint: FutureSyncTargetBlueprint
    let sourceSectionID: ProposalTemplateSectionID?
    let pricingComponentID: String?
    let previewValues: [String]

    var id: String { "\(blueprint.id):\(sourceSectionID?.rawValue ?? pricingComponentID ?? "none")" }
}

struct ProposalSyncPreview: Codable, Hashable {
    let candidates: [ProposalSyncCandidate]
}

struct ProposalCompositionDraft: Codable, Hashable {
    let proposalTitle: String
    let customerName: String?
    let sections: [ComposedProposalSection]
    let pricingGroups: [ComposedPricingGroup]

    var customerFacingSections: [ComposedProposalSection] {
        sections.filter { $0.isIncluded && !$0.customerFacingValues.isEmpty }
    }

    var internalSections: [ComposedProposalSection] {
        sections.filter { $0.isIncluded && !$0.internalValues.isEmpty }
    }

    var activePricingGroups: [ComposedPricingGroup] {
        pricingGroups.filter(\.isIncluded)
    }
}

struct ProposalFoundationSnapshot: Codable, Hashable {
    let template: ProposalTemplateDefinition
    let input: ProposalCompositionInput
    let proposal: ProposalCompositionDraft
    let syncPreview: ProposalSyncPreview
}

enum ProposalFoundationBuilder {
    static func compose(
        scope: JobScope,
        template: ProposalTemplateDefinition = .editableFoundationV1
    ) -> ProposalFoundationSnapshot {
        let input = makeCompositionInput(scope: scope, template: template)
        let proposal = makeProposalDraft(scope: scope, input: input, template: template)
        let syncPreview = makeSyncPreview(for: proposal, template: template)
        return ProposalFoundationSnapshot(
            template: template,
            input: input,
            proposal: proposal,
            syncPreview: syncPreview
        )
    }

    static func makeCompositionInput(
        scope: JobScope,
        template: ProposalTemplateDefinition = .editableFoundationV1
    ) -> ProposalCompositionInput {
        let documents = scope.documents
        let checkedPhotos = [
            scope.existingConditions?.photoChecklist?.frontOfHouse == true ? "Front of House" : nil,
            scope.existingConditions?.photoChecklist?.rearElevation == true ? "Rear Elevation" : nil,
            scope.existingConditions?.photoChecklist?.roofLine == true ? "Roof Line" : nil,
            scope.existingConditions?.photoChecklist?.electricalPanel == true ? "Electrical Panel" : nil,
            scope.existingConditions?.photoChecklist?.workArea == true ? "Work Area" : nil
        ].compactMap { $0 }

        let additionalDocuments = documents?.additionalAttachments ?? []
        let additionalDocumentNames = additionalDocuments.compactMap { attachment in
            attachment.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ??
                attachment.attachment?.originalFilename.nilIfBlank
        }

        let sections = [
            ScopeCaptureSectionSnapshot(
                section: .projectInfo,
                values: [
                    textValue(.scopeTitle, "Scope Title", scope.resolvedScopeTitle),
                    textValue(.customerName, "Customer Name", scope.resolvedCustomerDisplayName),
                    textValue(.linkedCustomerID, "Linked Customer ID", scope.jobTreadCustomer?.customerID),
                    textValue(.addressLine, "Address", scope.projectInfo.formattedAddressLine),
                    textValue(.cityStateZIP, "City / State / ZIP", combinedValue(scope.projectInfo.city, scope.projectInfo.state, scope.projectInfo.zip)),
                    textValue(.phone, "Phone", scope.projectInfo.phone),
                    textValue(.email, "Email", scope.projectInfo.email),
                    textValue(.salesperson, "Salesperson", scope.projectInfo.salesperson),
                    textValue(.estimator, "Estimator", scope.projectInfo.estimator),
                    enumValue(.projectType, "Project Type", scope.projectInfo.projectType == .notSet ? nil : scope.projectInfo.projectType),
                    dateValue(.siteVisitDate, "Site Visit Date", scope.projectInfo.siteVisitDate),
                    textValue(.projectNotes, "Project Notes", scope.projectInfo.notes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .existingConditions,
                values: [
                    enumValue(.houseStories, "House Stories", scope.existingConditions?.houseStories),
                    enumValue(.exteriorFinish, "Exterior Finish", scope.existingConditions?.exteriorFinish),
                    enumValue(.existingStructure, "Existing Structure", scope.existingConditions?.existingStructure),
                    textValue(.obstaclesNotes, "Obstacles Notes", scope.existingConditions?.obstaclesNotes),
                    textValue(.utilitiesNotes, "Utilities Notes", scope.existingConditions?.utilitiesNotes),
                    textValue(.hoaNotes, "HOA Notes", scope.existingConditions?.hoaNotes),
                    textValue(.photoChecklist, "Photo Checklist", checkedPhotos.isEmpty ? nil : checkedPhotos.joined(separator: ", "))
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .dimensions,
                values: [
                    measurementValue(.widthFeet, "Width", scope.dimensions?.width, suffix: "ft"),
                    measurementValue(.projectionFeet, "Projection", scope.dimensions?.projection, suffix: "ft"),
                    measurementValue(.fasciaHeightFeet, "Fascia Height", scope.dimensions?.fasciaHeight, suffix: "ft"),
                    measurementValue(.beamHeightFeet, "Beam Height", scope.dimensions?.beamHeight, suffix: "ft"),
                    enumValue(.roofStyle, "Roof Style", scope.dimensions?.roofStyle),
                    enumValue(.attachmentType, "Attachment Type", scope.dimensions?.attachmentType),
                    textValue(.elevationNotes, "Elevation Notes", scope.dimensions?.elevationNotes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .structuralSystem,
                values: [
                    enumValue(.frameMaterial, "Frame Material", scope.structuralSystem?.frameMaterial),
                    textValue(.structuralPostSize, "Post Size", scope.structuralSystem?.postSize),
                    textValue(.beamType, "Beam Type", scope.structuralSystem?.beamType),
                    enumValue(.roofSystem, "Roof System", scope.structuralSystem?.roofSystem),
                    textValue(.roofColor, "Roof Color", scope.structuralSystem?.roofColor),
                    textValue(.frameColor, "Frame Color", scope.structuralSystem?.frameColor),
                    textValue(.structuralNotes, "Structural Notes", scope.structuralSystem?.notes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .enclosure,
                values: [
                    enumValue(.enclosureType, "Enclosure Type", scope.enclosure?.enclosureType),
                    enumValue(.screenWallType, "Screen Wall Type", scope.enclosure?.screenWallType),
                    enumValue(.screenTint, "Screen Tint", scope.enclosure?.screenTint),
                    enumValue(.screenFrameSize, "Screen Frame Size", scope.enclosure?.screenFrameSize),
                    textValue(.screenFrameColor, "Screen Frame Color", resolvedScreenFrameColor(scope.enclosure)),
                    enumValue(.windowType, "Window Type", scope.enclosure?.windowSystem?.windowType),
                    enumValue(.windowFrameSystem, "Window Frame System", scope.enclosure?.windowSystem?.frameSystem),
                    enumValue(.glassType, "Glass Type", scope.enclosure?.windowSystem?.glassType),
                    enumValue(.glassSafety, "Glass Safety", scope.enclosure?.windowSystem?.glassSafety),
                    enumValue(.gridOption, "Grid Option", scope.enclosure?.windowSystem?.gridOption),
                    enumValue(.windowOperation, "Window Operation", scope.enclosure?.windowSystem?.operation),
                    textValue(.windowColor, "Window Color", resolvedWindowColor(scope.enclosure?.windowSystem)),
                    measurementValue(.windowHeight, "Window Height", scope.enclosure?.windowSystem?.windowHeight, suffix: "ft"),
                    measurementValue(.windowBayCount, "Number of Bays", scope.enclosure?.windowSystem?.numBays, suffix: nil),
                    enumValue(.windowConfiguration, "Window Configuration", scope.enclosure?.windowSystem?.configuration),
                    textValue(.windowNotes, "Window Notes", scope.enclosure?.windowSystem?.notes),
                    enumValue(.kneeWallOption, "Knee Wall Option", scope.enclosure?.kneeWall?.option),
                    enumValue(.kneeWallPanelHeight, "Knee Wall Panel Height", scope.enclosure?.kneeWall?.panelHeight),
                    textValue(.kneeWallPanelColor, "Knee Wall Panel Color", scope.enclosure?.kneeWall?.panelColor),
                    textValue(.kneeWallLinearFootage, "Knee Wall Linear Footage", scope.enclosure?.kneeWall?.linearFootage),
                    textValue(.kneeWallHeight, "Knee Wall Height", scope.enclosure?.kneeWall?.height),
                    enumValue(.kneeWallFraming, "Knee Wall Framing", scope.enclosure?.kneeWall?.framing),
                    enumValue(.doorType, "Door Type", resolvedDoorType(scope.enclosure?.doors?.doorType)),
                    enumValue(.doorStyle, "Door Style", scope.enclosure?.doors?.style),
                    enumValue(.doorOperableSide, "Door Operable Side", scope.enclosure?.doors?.operableSide),
                    enumValue(.doorHingeSide, "Door Hinge Side", scope.enclosure?.doors?.hingeSide),
                    textValue(.doorWidth, "Door Width", scope.enclosure?.doors?.width),
                    textValue(.doorHeight, "Door Height", scope.enclosure?.doors?.height),
                    textValue(.doorColor, "Door Color", scope.enclosure?.doors?.color),
                    textValue(.doorDimensions, "Door Dimensions", scope.enclosure?.doors?.dimensions),
                    textValue(.doorNotes, "Door Notes", scope.enclosure?.doors?.notes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .electrical,
                values: [
                    measurementValue(.outletCount, "Outlet Count", scope.electrical?.outletCount, suffix: nil),
                    enumValue(.lighting, "Lighting", resolvedLighting(scope.electrical?.lighting)),
                    boolValue(.fanInstall, "Fan Install", scope.electrical?.fanInstall),
                    textValue(.switchLocations, "Switch Locations", scope.electrical?.switchLocations),
                    textValue(.dedicatedCircuits, "Dedicated Circuits", scope.electrical?.dedicatedCircuits?.map(\.displayName).joined(separator: ", ")),
                    textValue(.electricalNotes, "Electrical Notes", scope.electrical?.notes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .drainage,
                values: [
                    boolValue(.gutters, "Gutters", scope.drainage?.gutters),
                    textValue(.downspoutLocations, "Downspout Locations", scope.drainage?.downspoutLocations),
                    boolValue(.drainTieIn, "Drain Tie-In", scope.drainage?.drainTieIn),
                    textValue(.slopeNotes, "Slope Notes", scope.drainage?.slopeNotes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .attachmentConditions,
                values: [
                    enumValue(.houseWallMaterial, "House Wall Material", scope.attachment?.houseWallMaterial),
                    textValue(.houseWallOther, "House Wall Other", scope.attachment?.houseWallOther),
                    enumValue(.houseMountingType, "House Mounting Type", scope.attachment?.houseMountingType),
                    enumValue(.postColumnMaterial, "Post / Column Material", scope.attachment?.postColumnMaterial),
                    textValue(.postColumnOther, "Post / Column Other", scope.attachment?.postColumnOther),
                    textValue(.attachmentPostSize, "Attachment Post Size", scope.attachment?.postSize),
                    textValue(.postSpacing, "Post Spacing", scope.attachment?.postSpacing),
                    boolValue(.trimPresent, "Trim Present", scope.attachment?.trimPresent),
                    textValue(.trimMaterial, "Trim Material", resolvedTrimMaterial(scope.attachment)),
                    textValue(.trimThickness, "Trim Thickness", resolvedTrimThickness(scope.attachment)),
                    enumValue(.mountCondition, "Mount Condition", scope.attachment?.mountCondition),
                    textValue(.fastenerPlan, "Fastener Plan", scope.attachment?.fastenerPlan?.map(\.displayName).joined(separator: ", ")),
                    textValue(.attachmentNotes, "Attachment Notes", scope.attachment?.notes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .documents,
                values: [
                    textValue(.irrigationDocument, "Irrigation", documents?.irrigation?.originalFilename),
                    textValue(.propertySurveyDocument, "Property Survey", documents?.propertySurvey?.originalFilename),
                    countValue(.additionalDocumentCount, "Additional Documents", additionalDocuments.count),
                    textValue(.additionalDocumentNames, "Additional Document Names", additionalDocumentNames.isEmpty ? nil : additionalDocumentNames.joined(separator: ", "))
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .finishes,
                values: [
                    textValue(.finishTrimType, "Trim Type", scope.finishes?.trimType),
                    textValue(.finishColor, "Paint / Powder Color", scope.finishes?.paintOrPowderColor),
                    boolValue(.sidingReplacementRequired, "Siding Replacement Required", scope.finishes?.sidingReplacementRequired),
                    textValue(.caulkingSealingNotes, "Caulking / Sealing Notes", scope.finishes?.caulkingSealingNotes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .permitsHOA,
                values: [
                    boolValue(.permitRequired, "Permit Required", scope.permitsHOA?.permitRequired),
                    textValue(.jurisdiction, "Jurisdiction", scope.permitsHOA?.jurisdiction),
                    boolValue(.hoaApprovalRequired, "HOA Approval Required", scope.permitsHOA?.hoaApprovalRequired),
                    boolValue(.engineeringRequired, "Engineering Required", scope.permitsHOA?.engineeringRequired),
                    textValue(.permitStatusNotes, "Permit Status Notes", scope.permitsHOA?.statusNotes)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .production,
                values: [
                    dateValue(.productionStartDate, "Start Date", scope.production?.startDate),
                    textValue(.crewLead, "Crew Lead", scope.production?.crewLead),
                    textValue(.durationEstimate, "Duration Estimate", scope.production?.durationEstimate),
                    enumValue(.materialOrderStatus, "Material Order Status", scope.production?.materialOrderStatus),
                    enumValue(.permitStatus, "Permit Status", scope.production?.permitStatus)
                ].compactMap { $0 }
            ),
            ScopeCaptureSectionSnapshot(
                section: .attachmentsAndSketches,
                values: [
                    textValue(.customerOptionsConfirmed, "Customer Options Confirmed", scope.customerApproval?.optionsConfirmedText),
                    dateValue(.signedDate, "Signed Date", scope.customerApproval?.signedDate),
                    countValue(.photoCount, "Photos", scope.photos?.count ?? 0),
                    countValue(.sketchCount, "Sketches", scope.sketches?.count ?? 0)
                ].compactMap { $0 }
            )
        ].filter { !$0.values.isEmpty }

        return ProposalCompositionInput(
            scopeID: scope.id,
            templateID: template.id,
            templateVersion: template.version,
            capturedAt: .now,
            customerContext: ProposalCustomerContext(
                linkedCustomerID: scope.jobTreadCustomer?.customerID,
                customerName: scope.resolvedCustomerDisplayName,
                scopeTitle: scope.resolvedScopeTitle,
                projectType: scope.projectInfo.projectType
            ),
            sections: sections
        )
    }

    private static func makeProposalDraft(
        scope: JobScope,
        input: ProposalCompositionInput,
        template: ProposalTemplateDefinition
    ) -> ProposalCompositionDraft {
        let sections = template.sections.map { definition in
            let customerFacingValues = uniqueValues(from: definition.customerFacingInputKeys.compactMap(input.value(for:)))
            let internalValues = uniqueValues(from: definition.internalInputKeys.compactMap(input.value(for:)))
            let isIncluded = include(definition.visibility, input: input)
            let inclusionReason = inclusionReason(for: definition.visibility, input: input)

            return ComposedProposalSection(
                id: definition.id,
                title: definition.title,
                isIncluded: isIncluded,
                inclusionReason: inclusionReason,
                sourceSections: definition.sourceSections,
                customerFacingValues: customerFacingValues,
                internalValues: internalValues,
                relatedPricingGroupIDs: definition.relatedPricingGroupIDs,
                highlights: customerFacingValues
                    .filter(\.isMeaningful)
                    .prefix(6)
                    .map { "\($0.label): \($0.displayValue)" }
            )
        }

        let pricingGroups = template.pricingGroups.map { group in
            let components = group.components.map { component in
                let mappedValues = component.mappedInputKeys.compactMap(input.value(for:))
                let quantityValue = quantity(for: component.quantitySource, input: input)
                let isIncluded = include(component.visibility, input: input)
                let bucketState = pricingBucketState(
                    isIncluded: isIncluded,
                    strategy: component.strategy,
                    quantityValue: quantityValue
                )
                let isCandidate = isIncluded

                return ComposedPricingComponent(
                    id: component.id,
                    title: component.title,
                    summary: component.summary,
                    outputChannels: component.outputChannels,
                    strategy: component.strategy,
                    inclusionReason: inclusionReason(for: component.visibility, input: input),
                    quantitySource: component.quantitySource,
                    quantityValue: quantityValue,
                    mappedValues: mappedValues,
                    bucketState: bucketState,
                    isCandidate: isCandidate
                )
            }

            let isIncluded = components.contains(where: \.isCandidate)

            return ComposedPricingGroup(
                id: group.id,
                title: group.title,
                sourceSections: group.sourceSections,
                outputChannels: group.outputChannels,
                isIncluded: isIncluded,
                components: components
            )
        }

        return ProposalCompositionDraft(
            proposalTitle: scope.resolvedDocumentTitle,
            customerName: scope.resolvedExportCustomerName,
            sections: sections,
            pricingGroups: pricingGroups
        )
    }

    private static func makeSyncPreview(
        for proposal: ProposalCompositionDraft,
        template: ProposalTemplateDefinition
    ) -> ProposalSyncPreview {
        var candidates: [ProposalSyncCandidate] = []

        for section in proposal.sections where section.isIncluded {
            guard let definition = template.sections.first(where: { $0.id == section.id }) else { continue }

            for target in definition.syncTargets {
                candidates.append(
                    ProposalSyncCandidate(
                        blueprint: target,
                        sourceSectionID: section.id,
                        pricingComponentID: nil,
                        previewValues: section.highlights
                    )
                )
            }
        }

        for group in proposal.pricingGroups {
            guard let definition = template.pricingGroups.first(where: { $0.id == group.id }) else { continue }

            for component in group.components where component.isCandidate {
                guard let componentDefinition = definition.components.first(where: { $0.id == component.id }) else { continue }
                let previewValues = component.mappedValues
                    .filter(\.isMeaningful)
                    .prefix(5)
                    .map { "\($0.label): \($0.displayValue)" }

                for target in componentDefinition.syncTargets {
                    candidates.append(
                        ProposalSyncCandidate(
                            blueprint: target,
                            sourceSectionID: nil,
                            pricingComponentID: component.id,
                            previewValues: previewValues
                        )
                    )
                }
            }
        }

        return ProposalSyncPreview(candidates: candidates)
    }

    private static func include(
        _ visibility: ProposalVisibilityDefinition,
        input: ProposalCompositionInput
    ) -> Bool {
        let triggerValues = visibility.triggerInputKeys.compactMap(input.value(for:))

        switch visibility.rule {
        case .always:
            return true
        case .whenAnyTriggerInputPresent:
            return triggerValues.contains(where: \.isMeaningful)
        case .whenAnyTriggerValueAffirmativeOrMeaningful:
            return triggerValues.contains(where: isAffirmativeOrMeaningful)
        case .whenProjectTypeIsSet:
            return input.customerContext.projectType != .notSet
        }
    }

    private static func inclusionReason(
        for visibility: ProposalVisibilityDefinition,
        input: ProposalCompositionInput
    ) -> String {
        let triggerValues = visibility.triggerInputKeys.compactMap(input.value(for:))
        let triggerLabels = triggerValues.map(\.label)

        switch visibility.rule {
        case .always:
            return "Always included."
        case .whenAnyTriggerInputPresent:
            if triggerValues.contains(where: \.isMeaningful) {
                return "Included because mapped scope inputs are present: \(triggerLabels.joined(separator: ", "))."
            }
            return "Excluded because no mapped scope inputs are present."
        case .whenAnyTriggerValueAffirmativeOrMeaningful:
            if triggerValues.contains(where: isAffirmativeOrMeaningful) {
                return "Included because relevant scope selections are active: \(triggerLabels.joined(separator: ", "))."
            }
            return "Excluded because no relevant scope selections are active."
        case .whenProjectTypeIsSet:
            if input.customerContext.projectType != .notSet {
                return "Included because project type is set to \(input.customerContext.projectType.displayName)."
            }
            return "Excluded because project type is not set."
        }
    }

    private static func quantity(
        for source: PricingQuantitySource?,
        input: ProposalCompositionInput
    ) -> Double? {
        guard let source else { return nil }

        switch source {
        case .widthFeet:
            return input.value(for: .widthFeet)?.numericValue
        case .projectionFeet:
            return input.value(for: .projectionFeet)?.numericValue
        case .areaSquareFeet:
            guard
                let width = input.value(for: .widthFeet)?.numericValue,
                let projection = input.value(for: .projectionFeet)?.numericValue
            else {
                return nil
            }
            return width * projection
        case .perimeterFeet:
            guard
                let width = input.value(for: .widthFeet)?.numericValue,
                let projection = input.value(for: .projectionFeet)?.numericValue
            else {
                return nil
            }
            return (width * 2) + (projection * 2)
        case .bayCount:
            return input.value(for: .windowBayCount)?.numericValue
        case .outletCount:
            return input.value(for: .outletCount)?.numericValue
        case .attachmentCount:
            return input.value(for: .additionalDocumentCount)?.numericValue
        }
    }

    private static func uniqueValues(from values: [ProposalInputValue]) -> [ProposalInputValue] {
        var seen = Set<ScopeInputKey>()
        return values.filter { value in
            seen.insert(value.key).inserted
        }
    }

    private static func isAffirmativeOrMeaningful(_ value: ProposalInputValue) -> Bool {
        if let boolValue = value.boolValue {
            return boolValue
        }

        if let numericValue = value.numericValue {
            return numericValue > 0
        }

        return value.isMeaningful
    }

    private static func pricingBucketState(
        isIncluded: Bool,
        strategy: PricingCalculationStrategyKind,
        quantityValue: Double?
    ) -> ProposalPricingBucketState {
        guard isIncluded else { return .excluded }

        if strategy == .quantityTimesRate, quantityValue != nil {
            return .quantitySeeded
        }

        return .placeholder
    }

    private static func textValue(_ key: ScopeInputKey, _ label: String, _ value: String?) -> ProposalInputValue? {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        guard let trimmedValue else { return nil }
        return ProposalInputValue(key: key, label: label, stringValue: trimmedValue, numericValue: nil, boolValue: nil)
    }

    private static func enumValue<Value: SchemaEnumDisplayable>(_ key: ScopeInputKey, _ label: String, _ value: Value?) -> ProposalInputValue? {
        guard let value else { return nil }
        return ProposalInputValue(key: key, label: label, stringValue: value.displayName, numericValue: nil, boolValue: nil)
    }

    private static func measurementValue(_ key: ScopeInputKey, _ label: String, _ value: Double?, suffix: String?) -> ProposalInputValue? {
        guard let value else { return nil }
        let number = ProposalFoundationFormatter.number.string(from: NSNumber(value: value)) ?? "\(value)"
        let stringValue = suffix.map { "\(number) \($0)" } ?? number
        return ProposalInputValue(key: key, label: label, stringValue: stringValue, numericValue: value, boolValue: nil)
    }

    private static func boolValue(_ key: ScopeInputKey, _ label: String, _ value: Bool?) -> ProposalInputValue? {
        guard let value else { return nil }
        return ProposalInputValue(key: key, label: label, stringValue: nil, numericValue: nil, boolValue: value)
    }

    private static func countValue(_ key: ScopeInputKey, _ label: String, _ count: Int) -> ProposalInputValue? {
        guard count > 0 else { return nil }
        return ProposalInputValue(
            key: key,
            label: label,
            stringValue: "\(count)",
            numericValue: Double(count),
            boolValue: nil
        )
    }

    private static func dateValue(_ key: ScopeInputKey, _ label: String, _ value: Date?) -> ProposalInputValue? {
        guard let value else { return nil }
        return ProposalInputValue(
            key: key,
            label: label,
            stringValue: value.formatted(date: .abbreviated, time: .omitted),
            numericValue: nil,
            boolValue: nil
        )
    }

    private static func combinedValue(_ city: String?, _ state: String?, _ zip: String?) -> String? {
        [city?.nilIfBlank, state?.nilIfBlank, zip?.nilIfBlank]
            .compactMap { $0 }
            .nilIfEmpty?
            .joined(separator: ", ")
    }

    private static func resolvedScreenFrameColor(_ enclosure: Enclosure?) -> String? {
        if let custom = enclosure?.screenFrameColorCustom?.nilIfBlank {
            return custom
        }

        return enclosure?.screenFrameColor?.displayName
    }

    private static func resolvedWindowColor(_ windowSystem: WindowSystem?) -> String? {
        if let custom = windowSystem?.colorCustom?.nilIfBlank {
            return custom
        }

        return windowSystem?.color?.displayName
    }

    private static func resolvedTrimMaterial(_ attachment: AttachmentConditions?) -> String? {
        if let other = attachment?.trimMaterialOther?.nilIfBlank {
            return other
        }

        return attachment?.trimMaterial?.displayName
    }

    private static func resolvedTrimThickness(_ attachment: AttachmentConditions?) -> String? {
        if let custom = attachment?.trimThicknessCustom {
            let formatted = ProposalFoundationFormatter.number.string(from: NSNumber(value: custom)) ?? "\(custom)"
            return "\(formatted) in"
        }

        return attachment?.trimThickness?.displayName
    }

    private static func resolvedDoorType(_ doorType: DoorType?) -> DoorType? {
        guard let doorType, doorType != DoorType.none else { return nil }
        return doorType
    }

    private static func resolvedLighting(_ lighting: LightingOption?) -> LightingOption? {
        guard let lighting, lighting != LightingOption.none else { return nil }
        return lighting
    }
}

extension ProposalTemplateDefinition {
    static let editableFoundationV1 = ProposalTemplateDefinition(
        id: "editable-pricing-proposal-foundation",
        version: 1,
        name: "Editable Pricing / Proposal Foundation",
        sections: [
            ProposalTemplateSectionDefinition(
                id: .projectSummary,
                title: "Project Summary",
                sourceSections: [.projectInfo, .dimensions],
                customerFacingInputKeys: [.scopeTitle, .customerName, .projectType, .widthFeet, .projectionFeet, .roofStyle, .attachmentType],
                internalInputKeys: [.linkedCustomerID, .salesperson, .estimator, .siteVisitDate, .projectNotes],
                visibility: ProposalVisibilityDefinition(rule: .always, triggerInputKeys: []),
                relatedPricingGroupIDs: ["site-readiness-and-coordination", "base-structure"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .jobField, targetKey: "job.title", title: "Job Title / Scope Title", notes: "Use local scope title when a native title field exists."),
                    FutureSyncTargetBlueprint(kind: .customField, targetKey: "project-summary", title: "Project Summary", notes: "Fallback for app-owned narrative fields.")
                ]
            ),
            ProposalTemplateSectionDefinition(
                id: .siteConditions,
                title: "Site Conditions",
                sourceSections: [.existingConditions, .attachmentConditions],
                customerFacingInputKeys: [.houseStories, .exteriorFinish, .existingStructure, .houseWallMaterial, .houseMountingType],
                internalInputKeys: [.obstaclesNotes, .utilitiesNotes, .hoaNotes, .mountCondition, .fastenerPlan, .attachmentNotes],
                visibility: ProposalVisibilityDefinition(
                    rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                    triggerInputKeys: [.houseStories, .exteriorFinish, .existingStructure, .obstaclesNotes, .utilitiesNotes, .houseWallMaterial, .houseMountingType]
                ),
                relatedPricingGroupIDs: ["site-readiness-and-coordination", "base-structure"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .customField, targetKey: "site-conditions", title: "Site Conditions", notes: "Operational capture likely belongs in custom fields.")
                ]
            ),
            ProposalTemplateSectionDefinition(
                id: .structuralSystem,
                title: "Structural System",
                sourceSections: [.dimensions, .structuralSystem, .attachmentConditions],
                customerFacingInputKeys: [.frameMaterial, .structuralPostSize, .beamType, .roofSystem, .roofColor, .frameColor],
                internalInputKeys: [.postSpacing, .fastenerPlan, .structuralNotes, .attachmentPostSize],
                visibility: ProposalVisibilityDefinition(
                    rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                    triggerInputKeys: [.frameMaterial, .structuralPostSize, .beamType, .roofSystem, .roofColor, .frameColor]
                ),
                relatedPricingGroupIDs: ["base-structure"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .costGroup, targetKey: "structure", title: "Structure Cost Group", notes: "Structure-related price rows can group here later."),
                    FutureSyncTargetBlueprint(kind: .customField, targetKey: "structural-specs", title: "Structural Specs", notes: "Useful for production notes and sync fallback.")
                ]
            ),
            ProposalTemplateSectionDefinition(
                id: .enclosureAndOpenings,
                title: "Enclosure and Openings",
                sourceSections: [.enclosure],
                customerFacingInputKeys: [.enclosureType, .screenWallType, .windowType, .glassType, .windowBayCount, .kneeWallOption, .doorType, .doorStyle],
                internalInputKeys: [.windowFrameSystem, .glassSafety, .gridOption, .windowOperation, .windowColor, .windowHeight, .windowConfiguration, .windowNotes, .kneeWallPanelHeight, .kneeWallPanelColor, .kneeWallLinearFootage, .kneeWallHeight, .kneeWallFraming, .doorOperableSide, .doorHingeSide, .doorWidth, .doorHeight, .doorColor, .doorDimensions, .doorNotes],
                visibility: ProposalVisibilityDefinition(
                    rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                    triggerInputKeys: [.enclosureType, .screenWallType, .windowType, .glassType, .windowBayCount, .kneeWallOption, .doorType]
                ),
                relatedPricingGroupIDs: ["enclosure-options"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .costGroup, targetKey: "enclosure-openings", title: "Enclosure / Openings Cost Group", notes: "Candidate parent group for screen/window/door items."),
                    FutureSyncTargetBlueprint(kind: .customField, targetKey: "enclosure-specs", title: "Enclosure Specs", notes: "Fallback structured sync bucket.")
                ]
            ),
            ProposalTemplateSectionDefinition(
                id: .electricalAndDrainage,
                title: "Electrical and Drainage",
                sourceSections: [.electrical, .drainage],
                customerFacingInputKeys: [.outletCount, .lighting, .fanInstall, .gutters, .drainTieIn],
                internalInputKeys: [.switchLocations, .dedicatedCircuits, .electricalNotes, .downspoutLocations, .slopeNotes],
                visibility: ProposalVisibilityDefinition(
                    rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                    triggerInputKeys: [.outletCount, .lighting, .fanInstall, .gutters, .drainTieIn, .dedicatedCircuits]
                ),
                relatedPricingGroupIDs: ["electrical-drainage"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .costGroup, targetKey: "electrical-drainage", title: "Electrical / Drainage Cost Group", notes: "For later line-item sync."),
                    FutureSyncTargetBlueprint(kind: .customField, targetKey: "electrical-drainage-specs", title: "Electrical / Drainage Specs", notes: "Fallback structured sync bucket.")
                ]
            ),
            ProposalTemplateSectionDefinition(
                id: .finishesAndPermitting,
                title: "Finishes and Permitting",
                sourceSections: [.finishes, .permitsHOA, .production],
                customerFacingInputKeys: [.finishTrimType, .finishColor, .permitRequired, .hoaApprovalRequired, .engineeringRequired],
                internalInputKeys: [.caulkingSealingNotes, .jurisdiction, .permitStatusNotes, .productionStartDate, .crewLead, .durationEstimate, .materialOrderStatus, .permitStatus],
                visibility: ProposalVisibilityDefinition(
                    rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                    triggerInputKeys: [.finishTrimType, .finishColor, .permitRequired, .hoaApprovalRequired, .engineeringRequired, .materialOrderStatus, .permitStatus]
                ),
                relatedPricingGroupIDs: ["finishes-permits-and-closeout"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .costGroup, targetKey: "finishes-permitting", title: "Finishes / Permitting Cost Group", notes: "Future allowance/cost items can land here."),
                    FutureSyncTargetBlueprint(kind: .customField, targetKey: "finishes-permitting-specs", title: "Finishes / Permitting Specs", notes: "Fallback structured sync bucket.")
                ]
            ),
            ProposalTemplateSectionDefinition(
                id: .attachmentsAndSupportingDocuments,
                title: "Attachments and Supporting Documents",
                sourceSections: [.documents, .attachmentsAndSketches],
                customerFacingInputKeys: [.irrigationDocument, .propertySurveyDocument, .additionalDocumentCount, .additionalDocumentNames],
                internalInputKeys: [.photoCount, .sketchCount, .signedDate, .customerOptionsConfirmed],
                visibility: ProposalVisibilityDefinition(
                    rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                    triggerInputKeys: [.irrigationDocument, .propertySurveyDocument, .additionalDocumentCount, .photoCount, .sketchCount, .signedDate]
                ),
                relatedPricingGroupIDs: ["site-readiness-and-coordination", "finishes-permits-and-closeout"],
                syncTargets: [
                    FutureSyncTargetBlueprint(kind: .document, targetKey: "supporting-documents", title: "Supporting Documents", notes: "Use file/document upload for presentation artifacts."),
                    FutureSyncTargetBlueprint(kind: .document, targetKey: "proposal-pdf", title: "Proposal PDF", notes: "Future polished proposal output belongs here.")
                ]
            )
        ],
        pricingGroups: [
            PricingGroupDefinition(
                id: "site-readiness-and-coordination",
                title: "Site Readiness and Coordination",
                sourceSections: [.projectInfo, .existingConditions, .attachmentConditions, .documents],
                outputChannels: [.internalOnly, .syncCandidate],
                components: [
                    PricingComponentDefinition(
                        id: "site-conditions-review",
                        title: "Site Conditions Review",
                        summary: "Existing conditions, obstacles, utilities, and attachment conditions that may affect setup or labor.",
                        mappedInputKeys: [.houseStories, .exteriorFinish, .existingStructure, .obstaclesNotes, .utilitiesNotes, .houseWallMaterial, .houseMountingType, .mountCondition],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.houseStories, .exteriorFinish, .existingStructure, .obstaclesNotes, .utilitiesNotes, .houseWallMaterial, .houseMountingType, .mountCondition]
                        ),
                        quantitySource: nil,
                        strategy: .lookupOnly,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "site-conditions-review", title: "Site Conditions Item", notes: "Placeholder operational bucket for future estimate rows.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "document-verification-and-layout",
                        title: "Document Verification and Layout",
                        summary: "Survey, irrigation, and supporting document review before final drafting and layout.",
                        mappedInputKeys: [.irrigationDocument, .propertySurveyDocument, .additionalDocumentCount, .additionalDocumentNames],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.irrigationDocument, .propertySurveyDocument, .additionalDocumentCount]
                        ),
                        quantitySource: .attachmentCount,
                        strategy: .lookupOnly,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "document-verification-layout", title: "Document Review Item", notes: "Future preconstruction or admin line item.")
                        ]
                    )
                ]
            ),
            PricingGroupDefinition(
                id: "base-structure",
                title: "Base Structure",
                sourceSections: [.projectInfo, .dimensions, .structuralSystem, .attachmentConditions],
                outputChannels: [.internalOnly, .syncCandidate],
                components: [
                    PricingComponentDefinition(
                        id: "frame-and-roof-package",
                        title: "Frame and Roof Package",
                        summary: "Core structure package driven by dimensions, structural system, and roof selections.",
                        mappedInputKeys: [.projectType, .widthFeet, .projectionFeet, .roofStyle, .frameMaterial, .roofSystem, .attachmentType],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.projectType, .widthFeet, .projectionFeet, .roofStyle, .frameMaterial, .roofSystem, .attachmentType]
                        ),
                        quantitySource: .areaSquareFeet,
                        strategy: .quantityTimesRate,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "frame-roof-package", title: "Frame / Roof Cost Item", notes: "Later line item generated from pricing rules.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "attachment-and-support-package",
                        title: "Attachment and Support Package",
                        summary: "Attachment, support posts, mounting, and fastener conditions.",
                        mappedInputKeys: [.houseWallMaterial, .houseMountingType, .postColumnMaterial, .attachmentPostSize, .postSpacing, .mountCondition, .fastenerPlan],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.houseWallMaterial, .houseMountingType, .postColumnMaterial, .attachmentPostSize, .postSpacing, .mountCondition, .fastenerPlan]
                        ),
                        quantitySource: .perimeterFeet,
                        strategy: .lookupOnly,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "attachment-support-package", title: "Attachment / Support Cost Item", notes: "May later become several discrete items.")
                        ]
                    )
                ]
            ),
            PricingGroupDefinition(
                id: "enclosure-options",
                title: "Enclosure Options",
                sourceSections: [.enclosure],
                outputChannels: [.internalOnly, .syncCandidate],
                components: [
                    PricingComponentDefinition(
                        id: "screen-or-wall-package",
                        title: "Screen / Wall Package",
                        summary: "Screen wall and enclosure selections independent of final vendor catalog.",
                        mappedInputKeys: [.enclosureType, .screenWallType, .screenTint, .screenFrameSize, .screenFrameColor],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.enclosureType, .screenWallType, .screenTint, .screenFrameSize, .screenFrameColor]
                        ),
                        quantitySource: .perimeterFeet,
                        strategy: .lookupOnly,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "screen-wall-package", title: "Screen / Wall Cost Item", notes: "Maps to future enclosure product rows.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "window-system-package",
                        title: "Window System Package",
                        summary: "Window/glass configuration captured separately from proposal wording.",
                        mappedInputKeys: [.windowType, .windowFrameSystem, .glassType, .glassSafety, .gridOption, .windowOperation, .windowColor, .windowHeight, .windowBayCount, .windowConfiguration],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.windowType, .windowFrameSystem, .glassType, .windowBayCount, .windowConfiguration]
                        ),
                        quantitySource: .bayCount,
                        strategy: .quantityTimesRate,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "window-system-package", title: "Window System Cost Item", notes: "Candidate sync row for structured estimate output.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "knee-wall-package",
                        title: "Knee Wall Package",
                        summary: "Knee wall selections with allowance until full formulas are known.",
                        mappedInputKeys: [.kneeWallOption, .kneeWallPanelHeight, .kneeWallPanelColor, .kneeWallLinearFootage, .kneeWallHeight, .kneeWallFraming],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.kneeWallOption, .kneeWallPanelHeight, .kneeWallLinearFootage, .kneeWallHeight, .kneeWallFraming]
                        ),
                        quantitySource: nil,
                        strategy: .allowance,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "knee-wall-package", title: "Knee Wall Cost Item", notes: "Future structured allowance or item set.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "door-package",
                        title: "Door Package",
                        summary: "Door selections kept separate so naming/vendor swaps are centralized.",
                        mappedInputKeys: [.doorType, .doorStyle, .doorOperableSide, .doorHingeSide, .doorWidth, .doorHeight, .doorColor, .doorDimensions],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.doorType, .doorStyle, .doorWidth, .doorHeight, .doorDimensions]
                        ),
                        quantitySource: nil,
                        strategy: .manualAmount,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "door-package", title: "Door Cost Item", notes: "Future structured opening line item.")
                        ]
                    )
                ]
            ),
            PricingGroupDefinition(
                id: "electrical-drainage",
                title: "Electrical and Drainage",
                sourceSections: [.electrical, .drainage],
                outputChannels: [.internalOnly, .syncCandidate],
                components: [
                    PricingComponentDefinition(
                        id: "electrical-package",
                        title: "Electrical Package",
                        summary: "Outlets, lighting, fans, switches, and dedicated circuits.",
                        mappedInputKeys: [.outletCount, .lighting, .fanInstall, .switchLocations, .dedicatedCircuits],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.outletCount, .lighting, .fanInstall, .switchLocations, .dedicatedCircuits]
                        ),
                        quantitySource: .outletCount,
                        strategy: .lookupOnly,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "electrical-package", title: "Electrical Cost Item", notes: "Could split into several cost rows later.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "drainage-package",
                        title: "Drainage Package",
                        summary: "Gutters, downspouts, tie-ins, and slope considerations.",
                        mappedInputKeys: [.gutters, .downspoutLocations, .drainTieIn, .slopeNotes],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.gutters, .downspoutLocations, .drainTieIn, .slopeNotes]
                        ),
                        quantitySource: nil,
                        strategy: .manualAmount,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "drainage-package", title: "Drainage Cost Item", notes: "Future gutter/downspout/tie-in rows.")
                        ]
                    )
                ]
            ),
            PricingGroupDefinition(
                id: "finishes-permits-and-closeout",
                title: "Finishes, Permits, and Closeout",
                sourceSections: [.finishes, .permitsHOA, .production, .attachmentsAndSketches],
                outputChannels: [.internalOnly, .syncCandidate],
                components: [
                    PricingComponentDefinition(
                        id: "finish-package",
                        title: "Finish Package",
                        summary: "Trim, color, sealing, and siding-related scope.",
                        mappedInputKeys: [.finishTrimType, .finishColor, .sidingReplacementRequired, .caulkingSealingNotes],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.finishTrimType, .finishColor, .sidingReplacementRequired, .caulkingSealingNotes]
                        ),
                        quantitySource: nil,
                        strategy: .manualAmount,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "finish-package", title: "Finish Cost Item", notes: "Later finish/paint/trim rows.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "permit-and-engineering-allowance",
                        title: "Permit and Engineering Allowance",
                        summary: "Permit, HOA, and engineering decisions separated from proposal copy.",
                        mappedInputKeys: [.permitRequired, .jurisdiction, .hoaApprovalRequired, .engineeringRequired],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.permitRequired, .jurisdiction, .hoaApprovalRequired, .engineeringRequired]
                        ),
                        quantitySource: nil,
                        strategy: .allowance,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "permit-engineering-allowance", title: "Permit / Engineering Item", notes: "Allowance or service item later.")
                        ]
                    ),
                    PricingComponentDefinition(
                        id: "project-coordination-and-closeout",
                        title: "Project Coordination and Closeout",
                        summary: "Production timing, customer approval, and closeout artifacts kept separate from customer-facing wording.",
                        mappedInputKeys: [.productionStartDate, .crewLead, .durationEstimate, .materialOrderStatus, .permitStatus, .customerOptionsConfirmed, .signedDate, .photoCount, .sketchCount],
                        visibility: ProposalVisibilityDefinition(
                            rule: .whenAnyTriggerValueAffirmativeOrMeaningful,
                            triggerInputKeys: [.productionStartDate, .crewLead, .durationEstimate, .materialOrderStatus, .permitStatus, .customerOptionsConfirmed, .signedDate, .photoCount, .sketchCount]
                        ),
                        quantitySource: .attachmentCount,
                        strategy: .lookupOnly,
                        outputChannels: [.internalOnly, .syncCandidate],
                        syncTargets: [
                            FutureSyncTargetBlueprint(kind: .costItem, targetKey: "project-coordination-closeout", title: "Project Coordination Item", notes: "Future coordination/closeout line item or sync row."),
                            FutureSyncTargetBlueprint(kind: .document, targetKey: "supporting-artifacts", title: "Supporting Artifacts Upload", notes: "Upload or attach where operationally useful.")
                        ]
                    )
                ]
            )
        ]
    )
}

extension JobScope {
    var proposalFoundationSnapshot: ProposalFoundationSnapshot {
        ProposalFoundationBuilder.compose(scope: self)
    }
}

private enum ProposalFoundationFormatter {
    static let number: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}

private extension Array where Element == String {
    var nilIfEmpty: [String]? {
        isEmpty ? nil : self
    }
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
