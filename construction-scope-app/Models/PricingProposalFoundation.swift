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

enum PricingRuleDefinitionKind: String, Codable, CaseIterable {
    case scopeEvaluation
    case packageLookup
    case quantityRate
    case allowance
}

enum PricingFormulaStrategyKind: String, Codable, CaseIterable {
    case flatScopeAllowance
    case quantityTimesDraftRate
    case quantityWithLookupAdjustments
    case packageSelection
}

enum PricingSubtotalDerivationKind: String, Codable, CaseIterable {
    case manualEntry
    case quantityTimesUnitPrice
    case allowanceEntry
    case deferredLookup
}

enum PricingGroupRollupStatus: String, Codable, CaseIterable {
    case pendingBucketSubtotals
    case readyForFutureRollup
    case inactive
}

enum PricingQuantitySource: String, Codable, CaseIterable {
    case widthFeet
    case projectionFeet
    case areaSquareFeet
    case perimeterFeet
    case bayCount
    case outletCount
    case attachmentCount
    case kneeWallLinearFeet
    case supportingArtifactCount
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
    let quantityBasisLabel: String?
    let unitLabel: String?
    let defaultQuantitySeed: Double?
    let strategy: PricingCalculationStrategyKind
    let draftRuleKey: String?
    let draftFormulaKey: String?
    let draftUnitCostPlaceholderKey: String
    let draftUnitPricePlaceholderKey: String
    let subtotalPlaceholderKey: String
    let seedNotes: [String]
    let assumptions: [String]
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
    let seedConfig: PricingBucketSeedConfig
}

struct PricingDraftAmountSlot: Codable, Hashable {
    let placeholderKey: String
    let amount: Double?
    let status: String
}

struct PricingSubtotalSeed: Codable, Hashable {
    let placeholderKey: String
    let amount: Double?
    let status: String
}

struct PricingRateSlotReference: Codable, Hashable {
    let slotKey: String
    let title: String
    let notes: String?
}

struct PricingFormulaInputReference: Codable, Hashable, Identifiable {
    let key: String
    let title: String
    let detail: String
    let isResolvedFromScope: Bool

    var id: String { key }
}

struct PricingFormulaDefinition: Codable, Hashable {
    let key: String
    let title: String
    let strategy: PricingFormulaStrategyKind
    let description: String
    let rateSlots: [PricingRateSlotReference]
    let inputReferences: [PricingFormulaInputReference]
}

struct PricingSubtotalDerivationDraft: Codable, Hashable {
    let placeholderKey: String
    let kind: PricingSubtotalDerivationKind
    let formulaKey: String?
    let inputs: [PricingFormulaInputReference]
    let status: String
}

struct PricingGroupRollupReference: Codable, Hashable {
    let groupID: String
    let placeholderKey: String
    let status: PricingGroupRollupStatus
    let notes: String
}

struct PricingRuleDefinition: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let kind: PricingRuleDefinitionKind
    let summary: String
    let formula: PricingFormulaDefinition?
    let subtotalDerivation: PricingSubtotalDerivationDraft
    let futureGroupRollup: PricingGroupRollupReference
    let notes: [String]
    let isExternallyConfigurable: Bool
}

struct ResolvedPricingRule: Codable, Hashable {
    let requestedRuleKey: String?
    let resolvedRuleID: String?
    let status: String
    let definition: PricingRuleDefinition?
}

enum PricingConfigurationValueKind: String, Codable, CaseIterable {
    case draftUnitCost
    case draftUnitPrice
    case allowanceAmount
    case feeAmount
    case markupPercent
}

enum PricingImportedRowValueKind: String, Codable, CaseIterable {
    case draftUnitCost
    case draftUnitPrice
    case allowanceAmount
    case feeAmount
    case markupPercent
    case scheduleInput
}

enum PricingConfigurationSourceKind: String, Codable, CaseIterable {
    case embeddedDraftBaseline
    case returnedSheetNormalizedMerged
    case returnedSheetNormalizedFallback
    case importedJSONMerged
    case importedJSONFallback
}

enum PricingImportIssueSeverity: String, Codable, CaseIterable {
    case warning
    case error
}

enum PricingImportIssueStage: String, Codable, CaseIterable {
    case adapter
    case normalization
    case merge
}

struct PricingConfiguredNumericValue: Codable, Hashable, Identifiable {
    let key: String
    let title: String
    let kind: PricingConfigurationValueKind
    let amount: Double
    let unitLabel: String?
    let notes: String?

    var id: String { key }
}

struct PricingScheduleInputValue: Codable, Hashable, Identifiable {
    let key: String
    let title: String
    let numericValue: Double?
    let stringValue: String?
    let unitLabel: String?
    let notes: String?

    var id: String { key }

    var displayValue: String {
        if let numericValue {
            let formatted = ProposalFoundationFormatter.number.string(from: NSNumber(value: numericValue)) ?? "\(numericValue)"
            if let unitLabel = unitLabel?.nilIfBlank {
                return "\(formatted) \(unitLabel)"
            }
            return formatted
        }

        return stringValue ?? ""
    }
}

struct ImportedPricingRow: Codable, Hashable, Identifiable {
    let ruleID: String
    let groupID: String?
    let scheduleInputKey: String?
    let valueKind: PricingImportedRowValueKind
    let numericValue: Double?
    let stringValue: String?
    let title: String?
    let unitLabel: String?
    let notes: String?
    let assumptions: String?

    var id: String {
        let groupPart = groupID?.nilIfBlank ?? "any_group"
        let schedulePart = scheduleInputKey?.nilIfBlank ?? "primary"
        return "\(ruleID):\(groupPart):\(valueKind.rawValue):\(schedulePart)"
    }
}

struct ReturnedPricingSheetRow: Codable, Hashable, Identifiable {
    let fillStatus: String?
    let pricingGroupTitle: String?
    let pricingItemTitle: String?
    let businessLabel: String?
    let whatToEnter: String?
    let ruleID: String?
    let groupID: String?
    let valueKind: String?
    let scheduleInputKey: String?
    let expectedValueType: String?
    let unitLabel: String?
    let currentDraftBaseline: String?
    let businessNumericValue: String?
    let businessTextValue: String?
    let businessNotes: String?

    var id: String {
        [
            ruleID?.nilIfBlank ?? "missing_rule",
            groupID?.nilIfBlank ?? "missing_group",
            valueKind?.nilIfBlank ?? "missing_value_kind",
            scheduleInputKey?.nilIfBlank ?? businessLabel?.nilIfBlank ?? "row"
        ]
        .joined(separator: ":")
    }
}

struct PricingImportIssue: Codable, Hashable, Identifiable {
    let id: String
    let severity: PricingImportIssueSeverity
    let stage: PricingImportIssueStage
    let rowID: String?
    let message: String
}

struct PricingReturnedSheetNormalizationReport: Codable, Hashable {
    let sourceRowCount: Int
    let normalizedRowCount: Int
    let skippedRowCount: Int
    let intentionallySkippedRowCount: Int
    let notReadyRowCount: Int
    let status: String
}

struct PricingConfigurationProfileImportMetadata: Codable, Hashable {
    let sourceKind: PricingConfigurationSourceKind
    let sourceDescription: String
    let importedRowCount: Int
    let importedValueKinds: [PricingConfigurationValueKind]
    let importedScheduleInputKeys: [String]
}

struct PricingRuleConfigurationProfile: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let draftUnitCost: Double?
    let draftUnitPrice: Double?
    let allowanceAmount: Double?
    let feeAmount: Double?
    let markupPercent: Double?
    let scheduleInputs: [PricingScheduleInputValue]
    let notes: [String]
    let importMetadata: PricingConfigurationProfileImportMetadata?
}

struct PricingConfigurationImportReport: Codable, Hashable {
    let sourceKind: PricingConfigurationSourceKind
    let adapterID: String
    let sourceDescription: String
    let status: String
    let importedRowCount: Int
    let appliedRowCount: Int
    let normalizationReport: PricingReturnedSheetNormalizationReport?
    let issues: [PricingImportIssue]
}

struct PricingConfigurationSnapshot: Codable, Hashable {
    let id: String
    let version: Int
    let sourceKind: PricingConfigurationSourceKind
    let sourceDescription: String
    let profiles: [PricingRuleConfigurationProfile]
    let importReport: PricingConfigurationImportReport?

    func profile(for ruleID: String) -> PricingRuleConfigurationProfile? {
        profiles.first(where: { $0.id == ruleID })
    }
}

struct ResolvedPricingConfiguration: Codable, Hashable {
    let snapshotID: String
    let sourceDescription: String
    let profileID: String?
    let profileTitle: String?
    let profileSourceKind: PricingConfigurationSourceKind?
    let profileSourceDescription: String?
    let status: String
    let draftUnitCost: PricingConfiguredNumericValue?
    let draftUnitPrice: PricingConfiguredNumericValue?
    let allowanceAmount: PricingConfiguredNumericValue?
    let feeAmount: PricingConfiguredNumericValue?
    let markupPercent: PricingConfiguredNumericValue?
    let scheduleInputs: [PricingScheduleInputValue]
    let notes: [String]
    let importedValueKinds: [PricingConfigurationValueKind]
    let importedScheduleInputKeys: [String]
}

struct PricingBucketSeedConfig: Codable, Hashable {
    let bucketID: String
    let groupID: String
    let displayName: String
    let quantityBasisLabel: String?
    let quantitySource: PricingQuantitySource?
    let quantitySeed: Double?
    let unitLabel: String?
    let draftUnitCost: PricingDraftAmountSlot
    let draftUnitPrice: PricingDraftAmountSlot
    let draftRuleKey: String?
    let draftFormulaKey: String?
    let subtotal: PricingSubtotalSeed
    let notes: [String]
    let assumptions: [String]
    let explanation: String
    let outputChannelHints: [ProposalOutputChannel]
    let resolvedRule: ResolvedPricingRule
    let resolvedConfiguration: ResolvedPricingConfiguration
}

struct ComposedPricingGroup: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let sourceSections: [ScopeCaptureSectionKey]
    let outputChannels: [ProposalOutputChannel]
    let isIncluded: Bool
    let components: [ComposedPricingComponent]
    let futureTotal: PricingGroupRollupDraft
}

struct PricingGroupRollupDraft: Codable, Hashable {
    let placeholderKey: String
    let componentSubtotalKeys: [String]
    let status: PricingGroupRollupStatus
    let explanation: String
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
    let pricingConfiguration: PricingConfigurationSnapshot
    let input: ProposalCompositionInput
    let proposal: ProposalCompositionDraft
    let syncPreview: ProposalSyncPreview
}

enum ProposalFoundationBuilder {
    static func compose(
        scope: JobScope,
        template: ProposalTemplateDefinition = .editableFoundationV1
    ) -> ProposalFoundationSnapshot {
        let pricingConfiguration = PricingConfigurationProvider.activeSnapshot()
        let input = makeCompositionInput(scope: scope, template: template)
        let proposal = makeProposalDraft(
            scope: scope,
            input: input,
            template: template,
            pricingConfiguration: pricingConfiguration
        )
        let syncPreview = makeSyncPreview(for: proposal, template: template)
        return ProposalFoundationSnapshot(
            template: template,
            pricingConfiguration: pricingConfiguration,
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
        template: ProposalTemplateDefinition,
        pricingConfiguration: PricingConfigurationSnapshot
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
                let quantityValue = quantity(
                    for: component.quantitySource,
                    defaultValue: component.defaultQuantitySeed,
                    input: input
                )
                let isIncluded = include(component.visibility, input: input)
                let bucketState = pricingBucketState(
                    isIncluded: isIncluded,
                    strategy: component.strategy,
                    quantityValue: quantityValue
                )
                let isCandidate = isIncluded
                let resolvedRule = resolvePricingRule(
                    for: component,
                    in: group,
                    mappedValues: mappedValues,
                    quantityValue: quantityValue,
                    isIncluded: isIncluded
                )
                let resolvedConfiguration = resolvePricingConfiguration(
                    for: component,
                    resolvedRule: resolvedRule,
                    pricingConfiguration: pricingConfiguration
                )
                let seedConfig = makePricingSeedConfig(
                    for: component,
                    in: group,
                    mappedValues: mappedValues,
                    quantityValue: quantityValue,
                    isIncluded: isIncluded,
                    resolvedRule: resolvedRule,
                    resolvedConfiguration: resolvedConfiguration
                )

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
                    isCandidate: isCandidate,
                    seedConfig: seedConfig
                )
            }

            let isIncluded = components.contains(where: \.isCandidate)
            let futureTotal = makePricingGroupRollupDraft(
                for: group,
                components: components,
                isIncluded: isIncluded
            )

            return ComposedPricingGroup(
                id: group.id,
                title: group.title,
                sourceSections: group.sourceSections,
                outputChannels: group.outputChannels,
                isIncluded: isIncluded,
                components: components,
                futureTotal: futureTotal
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
        defaultValue: Double?,
        input: ProposalCompositionInput
    ) -> Double? {
        guard let source else {
            return defaultValue
        }

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
        case .kneeWallLinearFeet:
            return parsedNumber(from: input.value(for: .kneeWallLinearFootage))
        case .supportingArtifactCount:
            let irrigationCount = input.value(for: .irrigationDocument)?.isMeaningful == true ? 1.0 : 0.0
            let propertySurveyCount = input.value(for: .propertySurveyDocument)?.isMeaningful == true ? 1.0 : 0.0
            let additionalDocumentCount = input.value(for: .additionalDocumentCount)?.numericValue ?? 0
            let photoCount = input.value(for: .photoCount)?.numericValue ?? 0
            let sketchCount = input.value(for: .sketchCount)?.numericValue ?? 0
            let total = irrigationCount + propertySurveyCount + additionalDocumentCount + photoCount + sketchCount
            return total > 0 ? total : defaultValue
        }
    }

    private static func makePricingSeedConfig(
        for component: PricingComponentDefinition,
        in group: PricingGroupDefinition,
        mappedValues: [ProposalInputValue],
        quantityValue: Double?,
        isIncluded: Bool,
        resolvedRule: ResolvedPricingRule,
        resolvedConfiguration: ResolvedPricingConfiguration
    ) -> PricingBucketSeedConfig {
        let quantityBasisLabel = component.quantityBasisLabel ?? defaultQuantityBasisLabel(for: component.quantitySource)
        let unitCostStatus = rateSlotStatus(
            quantityValue: quantityValue,
            quantityBasisLabel: quantityBasisLabel,
            isIncluded: isIncluded,
            configuredAmount: resolvedConfiguration.draftUnitCost?.amount,
            configuredTitle: resolvedConfiguration.draftUnitCost?.title
        )
        let unitPriceStatus = rateSlotStatus(
            quantityValue: quantityValue,
            quantityBasisLabel: quantityBasisLabel,
            isIncluded: isIncluded,
            configuredAmount: resolvedConfiguration.draftUnitPrice?.amount,
            configuredTitle: resolvedConfiguration.draftUnitPrice?.title
        )
        let subtotalSeed = makeSubtotalSeed(
            for: component,
            quantityValue: quantityValue,
            isIncluded: isIncluded,
            resolvedRule: resolvedRule,
            resolvedConfiguration: resolvedConfiguration
        )

        return PricingBucketSeedConfig(
            bucketID: component.id,
            groupID: group.id,
            displayName: component.title,
            quantityBasisLabel: quantityBasisLabel,
            quantitySource: component.quantitySource,
            quantitySeed: quantityValue,
            unitLabel: component.unitLabel,
            draftUnitCost: PricingDraftAmountSlot(
                placeholderKey: component.draftUnitCostPlaceholderKey,
                amount: resolvedConfiguration.draftUnitCost?.amount,
                status: unitCostStatus
            ),
            draftUnitPrice: PricingDraftAmountSlot(
                placeholderKey: component.draftUnitPricePlaceholderKey,
                amount: resolvedConfiguration.draftUnitPrice?.amount,
                status: unitPriceStatus
            ),
            draftRuleKey: component.draftRuleKey,
            draftFormulaKey: component.draftFormulaKey,
            subtotal: subtotalSeed,
            notes: component.seedNotes,
            assumptions: component.assumptions,
            explanation: seedExplanation(
                for: component,
                in: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                resolvedRule: resolvedRule,
                resolvedConfiguration: resolvedConfiguration
            ),
            outputChannelHints: component.outputChannels,
            resolvedRule: resolvedRule,
            resolvedConfiguration: resolvedConfiguration
        )
    }

    private static func resolvePricingRule(
        for component: PricingComponentDefinition,
        in group: PricingGroupDefinition,
        mappedValues: [ProposalInputValue],
        quantityValue: Double?,
        isIncluded: Bool
    ) -> ResolvedPricingRule {
        guard let ruleKey = component.draftRuleKey?.nilIfBlank else {
            return ResolvedPricingRule(
                requestedRuleKey: nil,
                resolvedRuleID: nil,
                status: "No draft rule key is assigned to this bucket yet.",
                definition: nil
            )
        }

        guard let registryEntry = PricingRuleRegistry.definition(
            for: ruleKey,
            component: component,
            group: group,
            mappedValues: mappedValues,
            quantityValue: quantityValue,
            isIncluded: isIncluded
        ) else {
            return ResolvedPricingRule(
                requestedRuleKey: ruleKey,
                resolvedRuleID: nil,
                status: "No registry definition exists yet for \(ruleKey).",
                definition: nil
            )
        }

        return ResolvedPricingRule(
            requestedRuleKey: ruleKey,
            resolvedRuleID: registryEntry.id,
            status: isIncluded
                ? "Resolved through the pricing rule registry."
                : "Resolved through the pricing rule registry while the bucket remains inactive.",
            definition: registryEntry
        )
    }

    private static func resolvePricingConfiguration(
        for component: PricingComponentDefinition,
        resolvedRule: ResolvedPricingRule,
        pricingConfiguration: PricingConfigurationSnapshot
    ) -> ResolvedPricingConfiguration {
        guard let resolvedRuleID = resolvedRule.resolvedRuleID else {
            return ResolvedPricingConfiguration(
                snapshotID: pricingConfiguration.id,
                sourceDescription: pricingConfiguration.sourceDescription,
                profileID: nil,
                profileTitle: nil,
                profileSourceKind: nil,
                profileSourceDescription: nil,
                status: "No pricing configuration profile can resolve until the bucket resolves to a stable rule ID.",
                draftUnitCost: nil,
                draftUnitPrice: nil,
                allowanceAmount: nil,
                feeAmount: nil,
                markupPercent: nil,
                scheduleInputs: [],
                notes: [],
                importedValueKinds: [],
                importedScheduleInputKeys: []
            )
        }

        guard let profile = pricingConfiguration.profile(for: resolvedRuleID) else {
            return ResolvedPricingConfiguration(
                snapshotID: pricingConfiguration.id,
                sourceDescription: pricingConfiguration.sourceDescription,
                profileID: nil,
                profileTitle: nil,
                profileSourceKind: nil,
                profileSourceDescription: nil,
                status: "No pricing configuration profile exists yet for \(resolvedRuleID).",
                draftUnitCost: nil,
                draftUnitPrice: nil,
                allowanceAmount: nil,
                feeAmount: nil,
                markupPercent: nil,
                scheduleInputs: [],
                notes: [],
                importedValueKinds: [],
                importedScheduleInputKeys: []
            )
        }

        return ResolvedPricingConfiguration(
            snapshotID: pricingConfiguration.id,
            sourceDescription: pricingConfiguration.sourceDescription,
            profileID: profile.id,
            profileTitle: profile.title,
            profileSourceKind: profile.importMetadata?.sourceKind ?? .embeddedDraftBaseline,
            profileSourceDescription: profile.importMetadata?.sourceDescription ?? "Embedded draft pricing baseline.",
            status: profile.importMetadata == nil
                ? "Resolved from embedded pricing configuration baseline."
                : "Resolved from imported pricing rows merged onto the embedded baseline.",
            draftUnitCost: configuredValue(
                amount: profile.draftUnitCost,
                key: component.draftUnitCostPlaceholderKey,
                title: "Draft Unit Cost",
                kind: .draftUnitCost,
                unitLabel: component.unitLabel,
                notes: "Config-fed draft cost for the bucket's unit slot."
            ),
            draftUnitPrice: configuredValue(
                amount: profile.draftUnitPrice,
                key: component.draftUnitPricePlaceholderKey,
                title: "Draft Unit Price",
                kind: .draftUnitPrice,
                unitLabel: component.unitLabel,
                notes: "Config-fed draft sell price for the bucket's unit slot."
            ),
            allowanceAmount: configuredValue(
                amount: profile.allowanceAmount,
                key: "\(profile.id).allowance",
                title: "Allowance Placeholder",
                kind: .allowanceAmount,
                unitLabel: nil,
                notes: "Config-fed allowance placeholder for allowance-oriented buckets."
            ),
            feeAmount: configuredValue(
                amount: profile.feeAmount,
                key: "\(profile.id).fee",
                title: "Fee Placeholder",
                kind: .feeAmount,
                unitLabel: nil,
                notes: "Config-fed fee or package placeholder."
            ),
            markupPercent: configuredValue(
                amount: profile.markupPercent,
                key: "\(profile.id).markup_percent",
                title: "Markup Placeholder",
                kind: .markupPercent,
                unitLabel: "%",
                notes: "Future markup placeholder retained separately from rule definitions."
            ),
            scheduleInputs: profile.scheduleInputs,
            notes: profile.notes,
            importedValueKinds: profile.importMetadata?.importedValueKinds ?? [],
            importedScheduleInputKeys: profile.importMetadata?.importedScheduleInputKeys ?? []
        )
    }

    private static func makePricingGroupRollupDraft(
        for group: PricingGroupDefinition,
        components: [ComposedPricingComponent],
        isIncluded: Bool
    ) -> PricingGroupRollupDraft {
        let placeholderKey = "draft.group.\(group.id).total"
        let activeComponents = components.filter(\.isCandidate)
        let componentSubtotalKeys = activeComponents.map(\.seedConfig.subtotal.placeholderKey)
        let unresolvedCount = activeComponents.filter { $0.seedConfig.resolvedRule.definition == nil }.count
        let status: PricingGroupRollupStatus
        let explanation: String

        if !isIncluded {
            status = .inactive
            explanation = "Group total scaffolding remains defined but inactive because no pricing buckets are currently included."
        } else if componentSubtotalKeys.isEmpty || unresolvedCount > 0 {
            status = .pendingBucketSubtotals
            explanation = "Future group rollup will sum resolved bucket subtotals after each active bucket has a usable subtotal derivation."
        } else {
            status = .readyForFutureRollup
            explanation = "Group total can later roll up the resolved bucket subtotal placeholders without changing proposal composition."
        }

        return PricingGroupRollupDraft(
            placeholderKey: placeholderKey,
            componentSubtotalKeys: componentSubtotalKeys,
            status: status,
            explanation: explanation
        )
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

    private static func parsedNumber(from value: ProposalInputValue?) -> Double? {
        guard let value else { return nil }

        if let numericValue = value.numericValue {
            return numericValue
        }

        guard let stringValue = value.stringValue?.nilIfBlank else { return nil }

        let matches = stringValue
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
            .filter { !$0.isEmpty }

        guard let first = matches.first else { return nil }
        return Double(first)
    }

    private static func defaultQuantityBasisLabel(for source: PricingQuantitySource?) -> String? {
        switch source {
        case .widthFeet:
            return "Width"
        case .projectionFeet:
            return "Projection"
        case .areaSquareFeet:
            return "Footprint Area"
        case .perimeterFeet:
            return "Perimeter"
        case .bayCount:
            return "Window Bays"
        case .outletCount:
            return "Outlet Count"
        case .attachmentCount:
            return "Additional Documents"
        case .kneeWallLinearFeet:
            return "Knee Wall Linear Footage"
        case .supportingArtifactCount:
            return "Supporting Artifacts"
        case .none:
            return nil
        }
    }

    private static func rateSlotStatus(
        quantityValue: Double?,
        quantityBasisLabel: String?,
        isIncluded: Bool,
        configuredAmount: Double?,
        configuredTitle: String?
    ) -> String {
        guard isIncluded else {
            return "Inactive until the bucket is included by current scope selections."
        }

        if let configuredAmount {
            let formatted = ProposalFoundationFormatter.currencyString(from: configuredAmount)
            if let configuredTitle = configuredTitle?.nilIfBlank {
                return "\(configuredTitle) is configured at \(formatted)."
            }
            return "Configured at \(formatted)."
        }

        guard let quantityBasisLabel else {
            return "No quantity basis is seeded yet; enter draft pricing as a scoped/manual bucket later."
        }

        if let quantityValue {
            let formatted = ProposalFoundationFormatter.number.string(from: NSNumber(value: quantityValue)) ?? "\(quantityValue)"
            return "Seeded from \(quantityBasisLabel.lowercased()) with quantity \(formatted)."
        }

        return "Quantity basis is \(quantityBasisLabel.lowercased()), but the current scope does not provide a seed yet."
    }

    private static func makeSubtotalSeed(
        for component: PricingComponentDefinition,
        quantityValue: Double?,
        isIncluded: Bool,
        resolvedRule: ResolvedPricingRule,
        resolvedConfiguration: ResolvedPricingConfiguration
    ) -> PricingSubtotalSeed {
        guard isIncluded else {
            return PricingSubtotalSeed(
                placeholderKey: component.subtotalPlaceholderKey,
                amount: nil,
                status: "Subtotal placeholder is inactive because the bucket is excluded."
            )
        }

        let subtotalKind = resolvedRule.definition?.subtotalDerivation.kind
        switch subtotalKind {
        case .quantityTimesUnitPrice:
            guard let quantityValue else {
                return PricingSubtotalSeed(
                    placeholderKey: component.subtotalPlaceholderKey,
                    amount: nil,
                    status: "Awaiting a seeded quantity before draft subtotal derivation can use the configured unit price."
                )
            }

            guard let unitPrice = resolvedConfiguration.draftUnitPrice?.amount else {
                return PricingSubtotalSeed(
                    placeholderKey: component.subtotalPlaceholderKey,
                    amount: nil,
                    status: "Awaiting configured draft unit price before subtotal derivation can use the seeded quantity."
                )
            }

            return PricingSubtotalSeed(
                placeholderKey: component.subtotalPlaceholderKey,
                amount: quantityValue * unitPrice,
                status: "Derived from seeded quantity and configured draft unit price."
            )
        case .manualEntry:
            if let feeAmount = resolvedConfiguration.feeAmount?.amount {
                return PricingSubtotalSeed(
                    placeholderKey: component.subtotalPlaceholderKey,
                    amount: feeAmount,
                    status: "Seeded from configured fee/package placeholder."
                )
            }

            if let quantityValue,
               quantityValue == 1,
               let unitPrice = resolvedConfiguration.draftUnitPrice?.amount {
                return PricingSubtotalSeed(
                    placeholderKey: component.subtotalPlaceholderKey,
                    amount: unitPrice,
                    status: "Seeded from configured package price with one scoped unit."
                )
            }

            return PricingSubtotalSeed(
                placeholderKey: component.subtotalPlaceholderKey,
                amount: nil,
                status: "Awaiting configured package or fee amount for manual subtotal scaffolding."
            )
        case .allowanceEntry:
            if let allowanceAmount = resolvedConfiguration.allowanceAmount?.amount {
                return PricingSubtotalSeed(
                    placeholderKey: component.subtotalPlaceholderKey,
                    amount: allowanceAmount,
                    status: "Seeded from configured allowance placeholder."
                )
            }

            return PricingSubtotalSeed(
                placeholderKey: component.subtotalPlaceholderKey,
                amount: nil,
                status: "Awaiting configured allowance placeholder."
            )
        case .deferredLookup:
            if resolvedConfiguration.draftUnitPrice?.amount != nil || resolvedConfiguration.feeAmount?.amount != nil {
                return PricingSubtotalSeed(
                    placeholderKey: component.subtotalPlaceholderKey,
                    amount: nil,
                    status: "Config-fed draft values are present, but subtotal derivation remains deferred until lookup adjustments are finalized."
                )
            }

            return PricingSubtotalSeed(
                placeholderKey: component.subtotalPlaceholderKey,
                amount: nil,
                status: "Awaiting config-fed draft values and future lookup adjustment logic before deriving a subtotal."
            )
        case .none:
            return PricingSubtotalSeed(
                placeholderKey: component.subtotalPlaceholderKey,
                amount: nil,
                status: "Awaiting subtotal derivation definition."
            )
        }
    }

    private static func configuredValue(
        amount: Double?,
        key: String,
        title: String,
        kind: PricingConfigurationValueKind,
        unitLabel: String?,
        notes: String?
    ) -> PricingConfiguredNumericValue? {
        guard let amount else { return nil }
        return PricingConfiguredNumericValue(
            key: key,
            title: title,
            kind: kind,
            amount: amount,
            unitLabel: unitLabel,
            notes: notes
        )
    }

    private static func seedExplanation(
        for component: PricingComponentDefinition,
        in group: PricingGroupDefinition,
        mappedValues: [ProposalInputValue],
        quantityValue: Double?,
        isIncluded: Bool,
        resolvedRule: ResolvedPricingRule,
        resolvedConfiguration: ResolvedPricingConfiguration
    ) -> String {
        var parts = ["Draft pricing seed for \(component.title) in \(group.title)."]

        if let quantityBasisLabel = component.quantityBasisLabel ?? defaultQuantityBasisLabel(for: component.quantitySource) {
            if let quantityValue {
                let formatted = ProposalFoundationFormatter.number.string(from: NSNumber(value: quantityValue)) ?? "\(quantityValue)"
                parts.append("Current scope seeds \(quantityBasisLabel.lowercased()) at \(formatted).")
            } else {
                parts.append("The bucket keeps \(quantityBasisLabel.lowercased()) as the intended quantity basis.")
            }
        } else {
            parts.append("This bucket is intentionally scoped without a committed quantity basis yet.")
        }

        if let resolvedRuleID = resolvedRule.resolvedRuleID {
            parts.append("Rule registry resolved \(resolvedRuleID) for this bucket.")
        } else if let requestedRuleKey = resolvedRule.requestedRuleKey {
            parts.append("Rule registry still needs a definition for \(requestedRuleKey).")
        }

        if !mappedValues.isEmpty {
            parts.append("Mapped scope inputs currently provide \(mappedValues.count) pricing signals.")
        }

        if let profileID = resolvedConfiguration.profileID {
            parts.append("Pricing config profile \(profileID) is attached to the bucket.")
        } else {
            parts.append("No external pricing profile is attached yet.")
        }

        parts.append(isIncluded ? "No final business pricing is hardcoded." : "The bucket remains defined even while excluded.")
        return parts.joined(separator: " ")
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

private enum PricingRuleRegistry {
    static func definition(
        for ruleKey: String,
        component: PricingComponentDefinition,
        group: PricingGroupDefinition,
        mappedValues: [ProposalInputValue],
        quantityValue: Double?,
        isIncluded: Bool
    ) -> PricingRuleDefinition? {
        switch ruleKey {
        case "site_review.scope_complexity":
            return buildDefinition(
                id: ruleKey,
                title: "Site Review Scope Complexity",
                kind: .scopeEvaluation,
                summary: "Evaluates site-condition signals to support a future scoped review amount or labor tier.",
                formulaStrategy: .packageSelection,
                formulaTitle: "Complexity Signal Review",
                formulaDescription: "Use scope condition signals to choose a future review tier or scoped admin/labor amount.",
                subtotalKind: .deferredLookup,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Tier thresholds remain external configuration.",
                    "Real labor pricing stays outside the registry."
                ]
            )
        case "documents.review_tier":
            return buildDefinition(
                id: ruleKey,
                title: "Document Review Tier",
                kind: .scopeEvaluation,
                summary: "Turns supporting-document volume into a future review tier plus setup logic.",
                formulaStrategy: .quantityWithLookupAdjustments,
                formulaTitle: "Document Count Tiering",
                formulaDescription: "Use document count and fixed document presence as signals for a future review tier or setup fee.",
                subtotalKind: .deferredLookup,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Count thresholds and setup fees remain external.",
                    "Fixed-slot documents remain context inputs, not hardcoded charges."
                ]
            )
        case "structure.base_package":
            return buildDefinition(
                id: ruleKey,
                title: "Structure Base Package",
                kind: .quantityRate,
                summary: "Uses footprint area as the stable base quantity for future structural pricing formulas.",
                formulaStrategy: .quantityTimesDraftRate,
                formulaTitle: "Area x Draft Structure Rate",
                formulaDescription: "Multiply footprint area by an externally configured draft unit rate, then apply future structural modifiers separately.",
                subtotalKind: .quantityTimesUnitPrice,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Vendor rates, waste factors, and modifiers remain external.",
                    "This rule defines the formula shape only."
                ]
            )
        case "structure.attachment_support_conditions":
            return buildDefinition(
                id: ruleKey,
                title: "Attachment and Support Conditions",
                kind: .packageLookup,
                summary: "Keeps attachment and support conditions in one stable lookup-driven package rule until the business splits them further.",
                formulaStrategy: .quantityWithLookupAdjustments,
                formulaTitle: "Perimeter with Condition Adjustments",
                formulaDescription: "Use perimeter as a sizing signal and combine it later with lookup-based support and mounting condition adjustments.",
                subtotalKind: .deferredLookup,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Condition adders remain externally configurable.",
                    "This prevents premature splitting into guessed cost items."
                ]
            )
        case "enclosure.screen_wall_selection":
            return buildDefinition(
                id: ruleKey,
                title: "Screen / Wall Selection",
                kind: .packageLookup,
                summary: "Resolves enclosure wall selections into a future lookup-driven pricing family without binding to a vendor catalog yet.",
                formulaStrategy: .quantityWithLookupAdjustments,
                formulaTitle: "Perimeter with Product Family Lookup",
                formulaDescription: "Use perimeter plus enclosure selections to choose a future product family and modifier set.",
                subtotalKind: .deferredLookup,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Product families and rates remain configurable later.",
                    "Views only consume the resolved definition, not pricing logic."
                ]
            )
        case "windows.system_selection":
            return buildDefinition(
                id: ruleKey,
                title: "Window System Selection",
                kind: .quantityRate,
                summary: "Uses bay count as the stable base quantity for future window package formulas and per-bay modifiers.",
                formulaStrategy: .quantityTimesDraftRate,
                formulaTitle: "Bay Count x Draft Window Rate",
                formulaDescription: "Multiply window bay count by a future externally configured draft rate, with glass/operation/configuration modifiers layered later.",
                subtotalKind: .quantityTimesUnitPrice,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Height and glass modifiers remain deferred inputs.",
                    "No vendor-specific catalog logic is hardcoded."
                ]
            )
        case "knee_wall.selection":
            return buildDefinition(
                id: ruleKey,
                title: "Knee Wall Selection",
                kind: .allowance,
                summary: "Keeps knee wall work on an allowance-capable rule while preserving linear-footage input when available.",
                formulaStrategy: .flatScopeAllowance,
                formulaTitle: "Scoped Allowance with Optional LF Signal",
                formulaDescription: "Use linear footage as a draft signal when present, but keep subtotal entry allowance-driven until wall build-up rules are confirmed.",
                subtotalKind: .allowanceEntry,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Allowance values remain external.",
                    "Linear-footage input is preserved for future migration to a true formula."
                ]
            )
        case "doors.package_selection":
            return buildDefinition(
                id: ruleKey,
                title: "Door Package Selection",
                kind: .packageLookup,
                summary: "Defines a stable package-selection rule for door work until explicit multi-door quantities exist.",
                formulaStrategy: .packageSelection,
                formulaTitle: "Door Package Lookup",
                formulaDescription: "Use captured door selections to choose a future package or variant from external pricing configuration.",
                subtotalKind: .manualEntry,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Door package prices remain configurable later.",
                    "Quantity assumptions remain intentionally conservative."
                ]
            )
        case "electrical.scope_package":
            return buildDefinition(
                id: ruleKey,
                title: "Electrical Scope Package",
                kind: .packageLookup,
                summary: "Preserves outlet count as a strong quantity seed while holding lighting/fan/circuit adders for future external rule config.",
                formulaStrategy: .quantityWithLookupAdjustments,
                formulaTitle: "Outlet Count with Electrical Adders",
                formulaDescription: "Use outlet count as the base quantity and apply future lookup adders for lighting, fan, switches, and dedicated circuits.",
                subtotalKind: .deferredLookup,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Electrical adders remain external.",
                    "The registry keeps the adders discoverable without pricing them."
                ]
            )
        case "drainage.scope_package":
            return buildDefinition(
                id: ruleKey,
                title: "Drainage Scope Package",
                kind: .packageLookup,
                summary: "Provides a stable manual/package rule for drainage until structural quantity capture is more complete.",
                formulaStrategy: .packageSelection,
                formulaTitle: "Drainage Package Lookup",
                formulaDescription: "Use drainage selections to choose a future package amount or package family from external configuration.",
                subtotalKind: .manualEntry,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Gutter/downspout/tie-in rates are intentionally deferred.",
                    "This avoids pretending to know unsupported quantities."
                ]
            )
        case "finishes.scope_package":
            return buildDefinition(
                id: ruleKey,
                title: "Finish Scope Package",
                kind: .packageLookup,
                summary: "Captures finish selections in a stable package rule until finish quantities and vendor catalogs are finalized.",
                formulaStrategy: .packageSelection,
                formulaTitle: "Finish Package Lookup",
                formulaDescription: "Use finish selections to choose a future package or scoped amount from external pricing configuration.",
                subtotalKind: .manualEntry,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Paint, trim, and siding pricing remain external.",
                    "The structure is ready for later package splitting if needed."
                ]
            )
        case "permits.requirements":
            return buildDefinition(
                id: ruleKey,
                title: "Permit and Engineering Requirements",
                kind: .allowance,
                summary: "Keeps permit, HOA, and engineering requirements in an allowance-oriented rule until real fee schedules are available.",
                formulaStrategy: .flatScopeAllowance,
                formulaTitle: "Permit / Engineering Allowance",
                formulaDescription: "Use requirement flags and jurisdiction metadata to choose a future allowance or fee schedule externally.",
                subtotalKind: .allowanceEntry,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Fee schedules remain external.",
                    "The registry preserves a stable target for later jurisdiction logic."
                ]
            )
        case "closeout.coordination":
            return buildDefinition(
                id: ruleKey,
                title: "Project Coordination and Closeout",
                kind: .scopeEvaluation,
                summary: "Preserves closeout/admin complexity signals for a future coordination rule without embedding project-management amounts.",
                formulaStrategy: .quantityWithLookupAdjustments,
                formulaTitle: "Artifact Count with Coordination Signals",
                formulaDescription: "Use supporting artifact count plus production/approval signals to determine a future coordination package or adders.",
                subtotalKind: .deferredLookup,
                component: component,
                group: group,
                mappedValues: mappedValues,
                quantityValue: quantityValue,
                isIncluded: isIncluded,
                notes: [
                    "Project management fees remain external.",
                    "This keeps closeout pricing logic out of views and PDF rendering."
                ]
            )
        default:
            return nil
        }
    }

    private static func buildDefinition(
        id: String,
        title: String,
        kind: PricingRuleDefinitionKind,
        summary: String,
        formulaStrategy: PricingFormulaStrategyKind,
        formulaTitle: String,
        formulaDescription: String,
        subtotalKind: PricingSubtotalDerivationKind,
        component: PricingComponentDefinition,
        group: PricingGroupDefinition,
        mappedValues: [ProposalInputValue],
        quantityValue: Double?,
        isIncluded: Bool,
        notes: [String]
    ) -> PricingRuleDefinition {
        let formulaInputReferences = makeFormulaInputReferences(
            component: component,
            mappedValues: mappedValues,
            quantityValue: quantityValue
        )
        let formula = PricingFormulaDefinition(
            key: component.draftFormulaKey ?? "\(id).draft_formula",
            title: formulaTitle,
            strategy: formulaStrategy,
            description: formulaDescription,
            rateSlots: [
                PricingRateSlotReference(
                    slotKey: component.draftUnitCostPlaceholderKey,
                    title: "Draft Unit Cost Slot",
                    notes: "Future vendor/business cost configuration can populate this slot."
                ),
                PricingRateSlotReference(
                    slotKey: component.draftUnitPricePlaceholderKey,
                    title: "Draft Unit Price Slot",
                    notes: "Future customer-facing draft pricing can populate this slot."
                )
            ],
            inputReferences: formulaInputReferences
        )
        let subtotalDerivation = PricingSubtotalDerivationDraft(
            placeholderKey: component.subtotalPlaceholderKey,
            kind: subtotalKind,
            formulaKey: formula.key,
            inputs: formulaInputReferences,
            status: subtotalDerivationStatus(
                quantityValue: quantityValue,
                unitLabel: component.unitLabel,
                isIncluded: isIncluded
            )
        )
        let futureGroupRollup = PricingGroupRollupReference(
            groupID: group.id,
            placeholderKey: "draft.group.\(group.id).total",
            status: isIncluded ? .pendingBucketSubtotals : .inactive,
            notes: "Future group totals should roll up bucket subtotal placeholders after bucket-level derivation is configured."
        )

        return PricingRuleDefinition(
            id: id,
            title: title,
            kind: kind,
            summary: summary,
            formula: formula,
            subtotalDerivation: subtotalDerivation,
            futureGroupRollup: futureGroupRollup,
            notes: notes,
            isExternallyConfigurable: true
        )
    }

    private static func makeFormulaInputReferences(
        component: PricingComponentDefinition,
        mappedValues: [ProposalInputValue],
        quantityValue: Double?
    ) -> [PricingFormulaInputReference] {
        var references = mappedValues.map { value in
            PricingFormulaInputReference(
                key: value.key.rawValue,
                title: value.label,
                detail: value.displayValue,
                isResolvedFromScope: value.isMeaningful
            )
        }

        if let quantityValue,
           let quantityBasisLabel = component.quantityBasisLabel ?? defaultQuantityBasisLabel(for: component.quantitySource) {
            let quantityDisplay = ProposalFoundationFormatter.number.string(from: NSNumber(value: quantityValue)) ?? "\(quantityValue)"
            let unitSuffix = component.unitLabel?.nilIfBlank.map { " \($0)" } ?? ""
            references.insert(
                PricingFormulaInputReference(
                    key: component.quantitySource?.rawValue ?? "quantity_seed",
                    title: quantityBasisLabel,
                    detail: "\(quantityDisplay)\(unitSuffix)",
                    isResolvedFromScope: true
                ),
                at: 0
            )
        }

        return references
    }

    private static func defaultQuantityBasisLabel(for source: PricingQuantitySource?) -> String? {
        switch source {
        case .widthFeet:
            return "Width"
        case .projectionFeet:
            return "Projection"
        case .areaSquareFeet:
            return "Footprint Area"
        case .perimeterFeet:
            return "Perimeter"
        case .bayCount:
            return "Window Bays"
        case .outletCount:
            return "Outlet Count"
        case .attachmentCount:
            return "Additional Documents"
        case .kneeWallLinearFeet:
            return "Knee Wall Linear Footage"
        case .supportingArtifactCount:
            return "Supporting Artifacts"
        case .none:
            return nil
        }
    }

    private static func subtotalDerivationStatus(
        quantityValue: Double?,
        unitLabel: String?,
        isIncluded: Bool
    ) -> String {
        guard isIncluded else {
            return "Subtotal placeholder is inactive because the bucket is excluded."
        }

        if quantityValue != nil {
            if let unitLabel = unitLabel?.nilIfBlank {
                return "Awaiting draft unit price per \(unitLabel) to derive a subtotal."
            }
            return "Awaiting draft unit price to derive a subtotal."
        }

        return "Awaiting manual amount, allowance, or future lookup details before deriving a subtotal."
    }
}

private enum PricingConfigurationProvider {
    static func activeSnapshot() -> PricingConfigurationSnapshot {
        let baseline = PricingConfigurationSnapshot.embeddedDraftBaselineV1
        if let returnedSheetSnapshot = ReturnedPricingSheetImportAdapter.activeSnapshot(fallback: baseline) {
            return returnedSheetSnapshot
        }
        return BundlePricingConfigurationImportAdapter.activeSnapshot(fallback: baseline)
    }
}

private enum ReturnedPricingSheetImportAdapter {
    private static let adapterID = "returned-sheet-json-normalizer-v1"
    private static let resourceName = "ReturnedPricingSheetRows"

    static func activeSnapshot(fallback baseline: PricingConfigurationSnapshot) -> PricingConfigurationSnapshot? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let rows = try JSONDecoder().decode([ReturnedPricingSheetRow].self, from: data)
            let normalizationResult = PricingReturnedSheetRowNormalizer.normalize(
                rows: rows,
                template: .editableFoundationV1
            )

            return PricingImportedConfigurationMerger.merge(
                rows: normalizationResult.rows,
                onto: baseline,
                template: .editableFoundationV1,
                adapterID: adapterID,
                sourceDescription: "Returned pricing sheet rows normalized and merged onto the embedded draft baseline.",
                mergedSourceKind: .returnedSheetNormalizedMerged,
                fallbackSourceKind: .returnedSheetNormalizedFallback,
                additionalIssues: normalizationResult.issues,
                normalizationReport: normalizationResult.report
            )
        } catch let decodingError as DecodingError {
            return baseline.withImportReport(
                sourceKind: .returnedSheetNormalizedFallback,
                sourceDescription: "Embedded draft pricing baseline only. Returned pricing sheet rows could not be decoded.",
                report: PricingConfigurationImportReport(
                    sourceKind: .returnedSheetNormalizedFallback,
                    adapterID: adapterID,
                    sourceDescription: "Returned pricing sheet normalization failed to decode, so the embedded draft baseline remains active.",
                    status: "Using embedded fallback because returned pricing sheet JSON could not be decoded.",
                    importedRowCount: 0,
                    appliedRowCount: 0,
                    normalizationReport: nil,
                    issues: [
                        PricingImportIssue(
                            id: "returned-sheet-decode-failed",
                            severity: .error,
                            stage: .adapter,
                            rowID: nil,
                            message: "Failed to decode \(resourceName).json: \(decodingError.localizedDescription)"
                        )
                    ]
                )
            )
        } catch {
            return baseline.withImportReport(
                sourceKind: .returnedSheetNormalizedFallback,
                sourceDescription: "Embedded draft pricing baseline only. Returned pricing sheet rows hit an unexpected error.",
                report: PricingConfigurationImportReport(
                    sourceKind: .returnedSheetNormalizedFallback,
                    adapterID: adapterID,
                    sourceDescription: "Returned pricing sheet normalization failed unexpectedly, so the embedded draft baseline remains active.",
                    status: "Using embedded fallback because returned pricing sheet JSON could not be read safely.",
                    importedRowCount: 0,
                    appliedRowCount: 0,
                    normalizationReport: nil,
                    issues: [
                        PricingImportIssue(
                            id: "returned-sheet-unexpected-error",
                            severity: .error,
                            stage: .adapter,
                            rowID: nil,
                            message: error.localizedDescription
                        )
                    ]
                )
            )
        }
    }
}

private enum BundlePricingConfigurationImportAdapter {
    private static let adapterID = "bundle-json-pricing-import-v1"
    private static let resourceName = "BusinessOwnedPricingRows"

    static func activeSnapshot(fallback baseline: PricingConfigurationSnapshot) -> PricingConfigurationSnapshot {
        do {
            let rows = try loadRows()
            return PricingImportedConfigurationMerger.merge(
                rows: rows,
                onto: baseline,
                template: .editableFoundationV1,
                adapterID: adapterID,
                sourceDescription: "Bundle JSON pricing import merged onto the embedded draft baseline.",
                mergedSourceKind: .importedJSONMerged,
                fallbackSourceKind: .importedJSONFallback,
                additionalIssues: [],
                normalizationReport: nil
            )
        } catch PricingImportAdapterError.missingResource {
            return baseline.withImportReport(
                sourceKind: .importedJSONFallback,
                sourceDescription: "Embedded draft pricing baseline only. No bundle JSON pricing import resource was found.",
                report: PricingConfigurationImportReport(
                    sourceKind: .importedJSONFallback,
                    adapterID: adapterID,
                    sourceDescription: "Bundle JSON pricing import was not found, so the embedded draft baseline remains active.",
                    status: "Using embedded fallback because \(resourceName).json is missing from the app bundle.",
                    importedRowCount: 0,
                    appliedRowCount: 0,
                    normalizationReport: nil,
                    issues: [
                        PricingImportIssue(
                            id: "missing-resource",
                            severity: .warning,
                            stage: .adapter,
                            rowID: nil,
                            message: "\(resourceName).json is missing from the app bundle."
                        )
                    ]
                )
            )
        } catch PricingImportAdapterError.decodingFailed(let description) {
            return baseline.withImportReport(
                sourceKind: .importedJSONFallback,
                sourceDescription: "Embedded draft pricing baseline only. Bundle JSON pricing import could not be decoded.",
                report: PricingConfigurationImportReport(
                    sourceKind: .importedJSONFallback,
                    adapterID: adapterID,
                    sourceDescription: "Bundle JSON pricing import failed to decode, so the embedded draft baseline remains active.",
                    status: "Using embedded fallback because imported pricing JSON could not be decoded.",
                    importedRowCount: 0,
                    appliedRowCount: 0,
                    normalizationReport: nil,
                    issues: [
                        PricingImportIssue(
                            id: "decode-failed",
                            severity: .error,
                            stage: .adapter,
                            rowID: nil,
                            message: description
                        )
                    ]
                )
            )
        } catch {
            return baseline.withImportReport(
                sourceKind: .importedJSONFallback,
                sourceDescription: "Embedded draft pricing baseline only. Bundle JSON pricing import hit an unexpected error.",
                report: PricingConfigurationImportReport(
                    sourceKind: .importedJSONFallback,
                    adapterID: adapterID,
                    sourceDescription: "Bundle JSON pricing import failed unexpectedly, so the embedded draft baseline remains active.",
                    status: "Using embedded fallback because imported pricing JSON could not be read safely.",
                    importedRowCount: 0,
                    appliedRowCount: 0,
                    normalizationReport: nil,
                    issues: [
                        PricingImportIssue(
                            id: "unexpected-error",
                            severity: .error,
                            stage: .adapter,
                            rowID: nil,
                            message: error.localizedDescription
                        )
                    ]
                )
            )
        }
    }

    private static func loadRows() throws -> [ImportedPricingRow] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw PricingImportAdapterError.missingResource
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ImportedPricingRow].self, from: data)
        } catch let decodingError as DecodingError {
            throw PricingImportAdapterError.decodingFailed("Failed to decode \(resourceName).json: \(decodingError.localizedDescription)")
        } catch {
            throw PricingImportAdapterError.decodingFailed("Failed to read \(resourceName).json: \(error.localizedDescription)")
        }
    }
}

private enum PricingImportAdapterError: Error {
    case missingResource
    case decodingFailed(String)
}

private struct PricingReturnedSheetNormalizationResult {
    let rows: [ImportedPricingRow]
    let issues: [PricingImportIssue]
    let report: PricingReturnedSheetNormalizationReport
}

private enum PricingReturnedSheetRowNormalizer {
    static func normalize(
        rows: [ReturnedPricingSheetRow],
        template: ProposalTemplateDefinition
    ) -> PricingReturnedSheetNormalizationResult {
        let expectedGroupByRuleID = PricingImportedConfigurationMerger.ruleGroupMap(template: template)
        var candidatesByRowID: [String: [ImportedPricingRow]] = [:]
        var issues: [PricingImportIssue] = []
        var skippedRowCount = 0
        var intentionallySkippedRowCount = 0
        var notReadyRowCount = 0

        for (index, row) in rows.enumerated() {
            let issuePrefix = "returned-row-\(index + 1)"
            let fillStatus = row.fillStatus?.nilIfBlank?.uppercased()
            let numericEntry = row.businessNumericValue?.nilIfBlank
            let textEntry = row.businessTextValue?.nilIfBlank
            let hasBusinessValue = numericEntry != nil || textEntry != nil

            if fillStatus == "SKIP" {
                intentionallySkippedRowCount += 1
                skippedRowCount += 1

                if hasBusinessValue {
                    issues.append(
                        PricingImportIssue(
                            id: "\(issuePrefix)-skip-with-value",
                            severity: .warning,
                            stage: .normalization,
                            rowID: row.id,
                            message: "Row marked SKIP still contains a business value. The row was ignored."
                        )
                    )
                }
                continue
            }

            if !hasBusinessValue {
                skippedRowCount += 1
                if fillStatus == "TODO" || fillStatus == "HOLD" || fillStatus == "NOT_READY" {
                    notReadyRowCount += 1
                }
                continue
            }

            guard let ruleID = row.ruleID?.nilIfBlank else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-missing-rule-id",
                        severity: .error,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row is missing ruleID. The row was ignored."
                    )
                )
                continue
            }

            guard expectedGroupByRuleID[ruleID] != nil else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-unknown-rule-id",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row references unknown rule ID \(ruleID). The row was ignored."
                    )
                )
                continue
            }

            guard let valueKindRawValue = row.valueKind?.nilIfBlank,
                  let valueKind = PricingImportedRowValueKind(rawValue: valueKindRawValue) else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-invalid-value-kind",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row for \(ruleID) does not provide a supported valueKind. The row was ignored."
                    )
                )
                continue
            }

            if numericEntry != nil && textEntry != nil {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-conflicting-filled-values",
                        severity: .error,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row for \(ruleID) contains both businessNumericValue and businessTextValue. The row was ignored."
                    )
                )
                continue
            }

            if let suppliedGroupID = row.groupID?.nilIfBlank,
               let expectedGroupID = expectedGroupByRuleID[ruleID],
               suppliedGroupID != expectedGroupID {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-group-mismatch",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row for \(ruleID) supplied pricing group \(suppliedGroupID), but the registry expects \(expectedGroupID). The row was ignored."
                    )
                )
                continue
            }

            guard let normalizedRow = normalizedImportedRow(
                from: row,
                ruleID: ruleID,
                valueKind: valueKind,
                issuePrefix: issuePrefix,
                issues: &issues
            ) else {
                continue
            }

            candidatesByRowID[normalizedRow.id, default: []].append(normalizedRow)
        }

        let duplicateResolution = PricingImportedConfigurationMerger.deduplicatedRows(
            candidatesByRowID: candidatesByRowID,
            stage: .normalization
        )
        issues.append(contentsOf: duplicateResolution.issues)

        let normalizedRowCount = duplicateResolution.rows.count
        let report = PricingReturnedSheetNormalizationReport(
            sourceRowCount: rows.count,
            normalizedRowCount: normalizedRowCount,
            skippedRowCount: skippedRowCount,
            intentionallySkippedRowCount: intentionallySkippedRowCount,
            notReadyRowCount: notReadyRowCount,
            status: normalizationStatus(
                sourceRowCount: rows.count,
                normalizedRowCount: normalizedRowCount,
                skippedRowCount: skippedRowCount,
                notReadyRowCount: notReadyRowCount,
                issueCount: issues.count
            )
        )

        return PricingReturnedSheetNormalizationResult(
            rows: duplicateResolution.rows,
            issues: issues.sorted { $0.id < $1.id },
            report: report
        )
    }

    private static func normalizedImportedRow(
        from row: ReturnedPricingSheetRow,
        ruleID: String,
        valueKind: PricingImportedRowValueKind,
        issuePrefix: String,
        issues: inout [PricingImportIssue]
    ) -> ImportedPricingRow? {
        let numericEntry = row.businessNumericValue?.nilIfBlank
        let textEntry = row.businessTextValue?.nilIfBlank

        switch valueKind {
        case .draftUnitCost, .draftUnitPrice, .allowanceAmount, .feeAmount, .markupPercent:
            guard let numericEntry else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-missing-numeric-value",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row for \(ruleID) requires a numeric business value for \(valueKind.rawValue). The row was ignored."
                    )
                )
                return nil
            }

            guard let numericValue = parsedNumericValue(from: numericEntry) else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-invalid-numeric-value",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet row for \(ruleID) contains an invalid numeric value '\(numericEntry)' for \(valueKind.rawValue). The row was ignored."
                    )
                )
                return nil
            }

            return ImportedPricingRow(
                ruleID: ruleID,
                groupID: row.groupID?.nilIfBlank,
                scheduleInputKey: nil,
                valueKind: valueKind,
                numericValue: numericValue,
                stringValue: nil,
                title: nil,
                unitLabel: row.unitLabel?.nilIfBlank,
                notes: row.businessNotes?.nilIfBlank,
                assumptions: nil
            )

        case .scheduleInput:
            guard let scheduleInputKey = row.scheduleInputKey?.nilIfBlank else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-missing-schedule-input-key",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet scheduleInput row for \(ruleID) is missing scheduleInputKey. The row was ignored."
                    )
                )
                return nil
            }

            if let numericEntry {
                guard let numericValue = parsedNumericValue(from: numericEntry) else {
                    issues.append(
                        PricingImportIssue(
                            id: "\(issuePrefix)-invalid-schedule-numeric-value",
                            severity: .warning,
                            stage: .normalization,
                            rowID: row.id,
                            message: "Returned sheet scheduleInput row for \(ruleID) contains an invalid numeric value '\(numericEntry)'. The row was ignored."
                        )
                    )
                    return nil
                }

                return ImportedPricingRow(
                    ruleID: ruleID,
                    groupID: row.groupID?.nilIfBlank,
                    scheduleInputKey: scheduleInputKey,
                    valueKind: .scheduleInput,
                    numericValue: numericValue,
                    stringValue: nil,
                    title: row.businessLabel?.nilIfBlank,
                    unitLabel: row.unitLabel?.nilIfBlank,
                    notes: row.businessNotes?.nilIfBlank,
                    assumptions: nil
                )
            }

            guard let stringValue = textEntry else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-missing-schedule-value",
                        severity: .warning,
                        stage: .normalization,
                        rowID: row.id,
                        message: "Returned sheet scheduleInput row for \(ruleID) must provide either businessNumericValue or businessTextValue. The row was ignored."
                    )
                )
                return nil
            }

            return ImportedPricingRow(
                ruleID: ruleID,
                groupID: row.groupID?.nilIfBlank,
                scheduleInputKey: scheduleInputKey,
                valueKind: .scheduleInput,
                numericValue: nil,
                stringValue: stringValue,
                title: row.businessLabel?.nilIfBlank,
                unitLabel: row.unitLabel?.nilIfBlank,
                notes: row.businessNotes?.nilIfBlank,
                assumptions: nil
            )
        }
    }

    private static func normalizationStatus(
        sourceRowCount: Int,
        normalizedRowCount: Int,
        skippedRowCount: Int,
        notReadyRowCount: Int,
        issueCount: Int
    ) -> String {
        guard sourceRowCount > 0 else {
            return "No returned pricing sheet rows were supplied."
        }

        var parts = ["\(normalizedRowCount) row(s) normalized from \(sourceRowCount) returned sheet row(s)."]
        if skippedRowCount > 0 {
            parts.append("\(skippedRowCount) row(s) skipped.")
        }
        if notReadyRowCount > 0 {
            parts.append("\(notReadyRowCount) row(s) were marked TODO/HOLD/NOT_READY with no business value.")
        }
        if issueCount > 0 {
            parts.append("\(issueCount) validation issue(s) were reported.")
        }
        return parts.joined(separator: " ")
    }

    private static func parsedNumericValue(from entry: String) -> Double? {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let isNegative = trimmed.hasPrefix("(") && trimmed.hasSuffix(")")
        let sanitized = trimmed
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let value = Double(sanitized) else { return nil }
        return isNegative ? (value * -1) : value
    }
}

private enum PricingImportedConfigurationMerger {
    static func merge(
        rows: [ImportedPricingRow],
        onto baseline: PricingConfigurationSnapshot,
        template: ProposalTemplateDefinition,
        adapterID: String,
        sourceDescription: String,
        mergedSourceKind: PricingConfigurationSourceKind,
        fallbackSourceKind: PricingConfigurationSourceKind,
        additionalIssues: [PricingImportIssue],
        normalizationReport: PricingReturnedSheetNormalizationReport?
    ) -> PricingConfigurationSnapshot {
        let expectedGroupByRuleID = ruleGroupMap(template: template)
        var profilesByRuleID = Dictionary(
            uniqueKeysWithValues: baseline.profiles.map { ($0.id, MutablePricingRuleConfigurationProfile(profile: $0)) }
        )
        let deduplicated = deduplicatedRows(
            candidatesByRowID: Dictionary(grouping: rows, by: \.id),
            stage: .merge
        )
        var issues: [PricingImportIssue] = additionalIssues + deduplicated.issues
        var appliedRowCount = 0

        for (index, row) in deduplicated.rows.enumerated() {
            let issuePrefix = "row-\(index + 1)"
            guard var profile = profilesByRuleID[row.ruleID] else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-unknown-rule",
                        severity: .warning,
                        stage: .merge,
                        rowID: row.id,
                        message: "Unknown rule ID \(row.ruleID). The row was ignored."
                    )
                )
                continue
            }

            if let suppliedGroupID = row.groupID?.nilIfBlank,
               let expectedGroupID = expectedGroupByRuleID[row.ruleID],
               suppliedGroupID != expectedGroupID {
                issues.append(
                    PricingImportIssue(
                        id: "\(issuePrefix)-group-mismatch",
                        severity: .warning,
                        stage: .merge,
                        rowID: row.id,
                        message: "Rule \(row.ruleID) belongs to pricing group \(expectedGroupID), not \(suppliedGroupID). The row was ignored."
                    )
                )
                continue
            }

            guard apply(row: row, to: &profile, issueIDPrefix: issuePrefix, issues: &issues) else {
                continue
            }

            profilesByRuleID[row.ruleID] = profile
            appliedRowCount += 1
        }

        let mergedProfiles = baseline.profiles.compactMap { baselineProfile in
            profilesByRuleID[baselineProfile.id]?.resolvedProfile(
                sourceKind: mergedSourceKind,
                sourceDescription: sourceDescription
            )
        }

        let sourceKind: PricingConfigurationSourceKind = appliedRowCount > 0 ? mergedSourceKind : fallbackSourceKind
        let sourceSummary = appliedRowCount > 0
            ? sourceDescription
            : "Embedded draft pricing baseline remains active because no imported rows were applied."

        let report = PricingConfigurationImportReport(
            sourceKind: sourceKind,
            adapterID: adapterID,
            sourceDescription: sourceDescription,
            status: importStatus(
                importedRowCount: deduplicated.rows.count,
                appliedRowCount: appliedRowCount,
                issueCount: issues.count,
                normalizationReport: normalizationReport
            ),
            importedRowCount: deduplicated.rows.count,
            appliedRowCount: appliedRowCount,
            normalizationReport: normalizationReport,
            issues: issues.sorted { $0.id < $1.id }
        )

        return PricingConfigurationSnapshot(
            id: appliedRowCount > 0 ? "imported-business-owned-pricing-config" : baseline.id,
            version: appliedRowCount > 0 ? baseline.version + 1 : baseline.version,
            sourceKind: sourceKind,
            sourceDescription: sourceSummary,
            profiles: mergedProfiles,
            importReport: report
        )
    }

    private static func apply(
        row: ImportedPricingRow,
        to profile: inout MutablePricingRuleConfigurationProfile,
        issueIDPrefix: String,
        issues: inout [PricingImportIssue]
    ) -> Bool {
        switch row.valueKind {
        case .draftUnitCost:
            guard let amount = row.numericValue else {
                issues.append(missingNumericValueIssue(prefix: issueIDPrefix, row: row))
                return false
            }
            profile.draftUnitCost = amount
            profile.importedValueKinds.insert(.draftUnitCost)
        case .draftUnitPrice:
            guard let amount = row.numericValue else {
                issues.append(missingNumericValueIssue(prefix: issueIDPrefix, row: row))
                return false
            }
            profile.draftUnitPrice = amount
            profile.importedValueKinds.insert(.draftUnitPrice)
        case .allowanceAmount:
            guard let amount = row.numericValue else {
                issues.append(missingNumericValueIssue(prefix: issueIDPrefix, row: row))
                return false
            }
            profile.allowanceAmount = amount
            profile.importedValueKinds.insert(.allowanceAmount)
        case .feeAmount:
            guard let amount = row.numericValue else {
                issues.append(missingNumericValueIssue(prefix: issueIDPrefix, row: row))
                return false
            }
            profile.feeAmount = amount
            profile.importedValueKinds.insert(.feeAmount)
        case .markupPercent:
            guard let amount = row.numericValue else {
                issues.append(missingNumericValueIssue(prefix: issueIDPrefix, row: row))
                return false
            }
            profile.markupPercent = amount
            profile.importedValueKinds.insert(.markupPercent)
        case .scheduleInput:
            guard let key = row.scheduleInputKey?.nilIfBlank else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issueIDPrefix)-missing-schedule-key",
                        severity: .warning,
                        stage: .merge,
                        rowID: row.id,
                        message: "Schedule input rows must provide a scheduleInputKey. The row was ignored."
                    )
                )
                return false
            }

            let stringValue = row.stringValue?.nilIfBlank
            guard row.numericValue != nil || stringValue != nil else {
                issues.append(
                    PricingImportIssue(
                        id: "\(issueIDPrefix)-missing-schedule-value",
                        severity: .warning,
                        stage: .merge,
                        rowID: row.id,
                        message: "Schedule input row \(key) must provide either numericValue or stringValue. The row was ignored."
                    )
                )
                return false
            }

            let existingInput = profile.scheduleInputs.first(where: { $0.key == key })
            let mergedInput = PricingScheduleInputValue(
                key: key,
                title: row.title?.nilIfBlank ?? existingInput?.title ?? humanizedTitle(from: key),
                numericValue: row.numericValue,
                stringValue: stringValue,
                unitLabel: row.unitLabel?.nilIfBlank ?? existingInput?.unitLabel,
                notes: mergedNotes(row.notes, row.assumptions, existing: existingInput?.notes)
            )
            profile.upsertScheduleInput(mergedInput)
            profile.importedScheduleInputKeys.insert(key)
        }

        if let notes = mergedNotes(row.notes, row.assumptions, existing: nil) {
            profile.appendNoteIfNeeded("Imported row: \(notes)")
        }

        profile.importedRowCount += 1
        return true
    }

    private static func missingNumericValueIssue(prefix: String, row: ImportedPricingRow) -> PricingImportIssue {
        PricingImportIssue(
            id: "\(prefix)-missing-numeric-value",
            severity: .warning,
            stage: .merge,
            rowID: row.id,
            message: "Imported row for \(row.ruleID) requires numericValue for \(row.valueKind.rawValue). The row was ignored."
        )
    }

    private static func mergedNotes(_ notes: String?, _ assumptions: String?, existing: String?) -> String? {
        [
            existing?.nilIfBlank,
            notes?.nilIfBlank,
            assumptions?.nilIfBlank.map { "Assumption: \($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: " | ")
        .nilIfBlank
    }

    private static func importStatus(
        importedRowCount: Int,
        appliedRowCount: Int,
        issueCount: Int,
        normalizationReport: PricingReturnedSheetNormalizationReport?
    ) -> String {
        if let normalizationReport {
            if normalizationReport.normalizedRowCount == 0 {
                return "Returned sheet loaded, but no rows normalized into trusted pricing rows. Embedded draft pricing remains active."
            }

            if appliedRowCount == 0 {
                return "Returned sheet normalized, but no rows passed merge validation. Embedded draft pricing remains active."
            }

            if issueCount == 0 {
                return "Returned sheet rows normalized successfully and merged onto the embedded draft baseline."
            }

            return "Returned sheet rows normalized and merged with validation issues. Invalid rows were skipped and embedded values remain in place where needed."
        }

        if importedRowCount == 0 {
            return "No imported pricing rows were found. Embedded draft pricing remains active."
        }

        if appliedRowCount == 0 {
            return "Imported pricing file loaded, but no rows passed validation. Embedded draft pricing remains active."
        }

        if issueCount == 0 {
            return "Imported pricing rows loaded successfully and merged onto the embedded draft baseline."
        }

        return "Imported pricing rows merged with validation issues. Invalid rows were skipped and embedded values remain in place where needed."
    }

    private static func humanizedTitle(from key: String) -> String {
        key
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    static func ruleGroupMap(template: ProposalTemplateDefinition) -> [String: String] {
        var map: [String: String] = [:]
        for group in template.pricingGroups {
            for component in group.components {
                guard let ruleID = component.draftRuleKey?.nilIfBlank else { continue }
                map[ruleID] = group.id
            }
        }
        return map
    }

    static func deduplicatedRows(
        candidatesByRowID: [String: [ImportedPricingRow]],
        stage: PricingImportIssueStage
    ) -> (rows: [ImportedPricingRow], issues: [PricingImportIssue]) {
        var uniqueRows: [ImportedPricingRow] = []
        var issues: [PricingImportIssue] = []

        for key in candidatesByRowID.keys.sorted() {
            guard let candidates = candidatesByRowID[key], let first = candidates.first else { continue }

            if candidates.count == 1 {
                uniqueRows.append(first)
                continue
            }

            let equivalent = candidates.dropFirst().allSatisfy { candidate in
                candidate.isPricingEquivalent(to: first)
            }

            if equivalent {
                uniqueRows.append(first)
                issues.append(
                    PricingImportIssue(
                        id: "\(stage.rawValue)-duplicate-\(key)",
                        severity: .warning,
                        stage: stage,
                        rowID: key,
                        message: "Duplicate rows were supplied for \(key). The first normalized value was kept."
                    )
                )
            } else {
                issues.append(
                    PricingImportIssue(
                        id: "\(stage.rawValue)-conflicting-duplicate-\(key)",
                        severity: .error,
                        stage: stage,
                        rowID: key,
                        message: "Conflicting duplicate rows were supplied for \(key). All duplicates for this pricing slot were ignored."
                    )
                )
            }
        }

        return (uniqueRows.sorted { $0.id < $1.id }, issues.sorted { $0.id < $1.id })
    }
}

private struct MutablePricingRuleConfigurationProfile {
    let id: String
    let title: String
    var draftUnitCost: Double?
    var draftUnitPrice: Double?
    var allowanceAmount: Double?
    var feeAmount: Double?
    var markupPercent: Double?
    var scheduleInputs: [PricingScheduleInputValue]
    var notes: [String]
    var importedRowCount: Int
    var importedValueKinds: Set<PricingConfigurationValueKind>
    var importedScheduleInputKeys: Set<String>

    init(profile: PricingRuleConfigurationProfile) {
        id = profile.id
        title = profile.title
        draftUnitCost = profile.draftUnitCost
        draftUnitPrice = profile.draftUnitPrice
        allowanceAmount = profile.allowanceAmount
        feeAmount = profile.feeAmount
        markupPercent = profile.markupPercent
        scheduleInputs = profile.scheduleInputs
        notes = profile.notes
        importedRowCount = 0
        importedValueKinds = []
        importedScheduleInputKeys = []
    }

    mutating func upsertScheduleInput(_ input: PricingScheduleInputValue) {
        if let index = scheduleInputs.firstIndex(where: { $0.key == input.key }) {
            scheduleInputs[index] = input
        } else {
            scheduleInputs.append(input)
        }
    }

    mutating func appendNoteIfNeeded(_ note: String) {
        guard !notes.contains(note) else { return }
        notes.append(note)
    }

    func resolvedProfile(
        sourceKind: PricingConfigurationSourceKind,
        sourceDescription: String
    ) -> PricingRuleConfigurationProfile {
        PricingRuleConfigurationProfile(
            id: id,
            title: title,
            draftUnitCost: draftUnitCost,
            draftUnitPrice: draftUnitPrice,
            allowanceAmount: allowanceAmount,
            feeAmount: feeAmount,
            markupPercent: markupPercent,
            scheduleInputs: scheduleInputs,
            notes: notes,
            importMetadata: importedRowCount > 0
                ? PricingConfigurationProfileImportMetadata(
                    sourceKind: sourceKind,
                    sourceDescription: sourceDescription,
                    importedRowCount: importedRowCount,
                    importedValueKinds: importedValueKinds.sorted { $0.rawValue < $1.rawValue },
                    importedScheduleInputKeys: importedScheduleInputKeys.sorted()
                )
                : nil
        )
    }
}

private extension PricingConfigurationSnapshot {
    static let embeddedDraftBaselineV1 = PricingConfigurationSnapshot(
        id: "embedded-draft-pricing-config",
        version: 1,
        sourceKind: .embeddedDraftBaseline,
        sourceDescription: "Embedded draft pricing baseline. Replaceable later with imported business-owned pricing data keyed by stable rule IDs.",
        profiles: [
            profile(id: "site_review.scope_complexity", title: "Site Review Scope Complexity", feeAmount: 275, markupPercent: 18, scheduleInputs: [
                PricingScheduleInputValue(key: "complexity_tier", title: "Complexity Tier", numericValue: nil, stringValue: "standard_review", unitLabel: nil, notes: "Future sheet-owned tier key."),
                PricingScheduleInputValue(key: "crew_visit_hours", title: "Crew Visit Hours", numericValue: 2, stringValue: nil, unitLabel: "hrs", notes: "Draft schedule placeholder.")
            ], notes: ["Draft only. Replace with business-owned review tiers later."]),
            profile(id: "documents.review_tier", title: "Document Review Tier", feeAmount: 185, markupPercent: 15, scheduleInputs: [
                PricingScheduleInputValue(key: "document_review_tier", title: "Document Review Tier", numericValue: nil, stringValue: "up_to_three_docs", unitLabel: nil, notes: "Future doc-count schedule bucket.")
            ], notes: ["Draft document review placeholder."]),
            profile(id: "structure.base_package", title: "Structure Base Package", draftUnitCost: 24, draftUnitPrice: 36, markupPercent: 33, scheduleInputs: [
                PricingScheduleInputValue(key: "material_factor", title: "Material Factor", numericValue: 1, stringValue: nil, unitLabel: "multiplier", notes: "Future supplier factor input."),
                PricingScheduleInputValue(key: "lead_time_weeks", title: "Lead Time", numericValue: 4, stringValue: nil, unitLabel: "weeks", notes: "Future schedule input.")
            ], notes: ["Draft area-rate placeholder only."]),
            profile(id: "structure.attachment_support_conditions", title: "Attachment and Support Conditions", draftUnitCost: 8, draftUnitPrice: 12, feeAmount: 240, markupPercent: 22, scheduleInputs: [
                PricingScheduleInputValue(key: "mount_condition_table", title: "Mount Condition Table", numericValue: nil, stringValue: "baseline", unitLabel: nil, notes: "Future lookup schedule key.")
            ], notes: ["Lookup modifiers still deferred."]),
            profile(id: "enclosure.screen_wall_selection", title: "Screen / Wall Selection", draftUnitCost: 16, draftUnitPrice: 24, markupPercent: 25, scheduleInputs: [
                PricingScheduleInputValue(key: "product_family", title: "Product Family", numericValue: nil, stringValue: "screen_wall_standard", unitLabel: nil, notes: "Future product-family lookup key.")
            ], notes: ["Draft perimeter-rate placeholder."]),
            profile(id: "windows.system_selection", title: "Window System Selection", draftUnitCost: 850, draftUnitPrice: 1195, markupPercent: 29, scheduleInputs: [
                PricingScheduleInputValue(key: "glass_modifier_table", title: "Glass Modifier Table", numericValue: nil, stringValue: "glass_default", unitLabel: nil, notes: "Future glass schedule key."),
                PricingScheduleInputValue(key: "bay_lead_time_weeks", title: "Bay Lead Time", numericValue: 6, stringValue: nil, unitLabel: "weeks", notes: "Future schedule input.")
            ], notes: ["Draft per-bay rate placeholder."]),
            profile(id: "knee_wall.selection", title: "Knee Wall Selection", allowanceAmount: 1450, markupPercent: 20, scheduleInputs: [
                PricingScheduleInputValue(key: "wall_buildup_schedule", title: "Wall Build-Up Schedule", numericValue: nil, stringValue: "allowance_only", unitLabel: nil, notes: "Future wall assembly schedule.")
            ], notes: ["Allowance placeholder only."]),
            profile(id: "doors.package_selection", title: "Door Package Selection", draftUnitCost: 1400, draftUnitPrice: 1895, feeAmount: 1895, markupPercent: 26, scheduleInputs: [
                PricingScheduleInputValue(key: "door_family", title: "Door Family", numericValue: nil, stringValue: "single_package", unitLabel: nil, notes: "Future door-family key.")
            ], notes: ["Draft package placeholder."]),
            profile(id: "electrical.scope_package", title: "Electrical Scope Package", draftUnitCost: 145, draftUnitPrice: 225, feeAmount: 320, markupPercent: 28, scheduleInputs: [
                PricingScheduleInputValue(key: "circuit_adder_table", title: "Circuit Adder Table", numericValue: nil, stringValue: "baseline", unitLabel: nil, notes: "Future adder schedule key.")
            ], notes: ["Outlet-driven draft baseline only."]),
            profile(id: "drainage.scope_package", title: "Drainage Scope Package", feeAmount: 980, markupPercent: 21, scheduleInputs: [
                PricingScheduleInputValue(key: "drainage_package_type", title: "Drainage Package Type", numericValue: nil, stringValue: "standard_package", unitLabel: nil, notes: "Future package schedule key.")
            ], notes: ["Manual package placeholder only."]),
            profile(id: "finishes.scope_package", title: "Finish Scope Package", feeAmount: 720, markupPercent: 24, scheduleInputs: [
                PricingScheduleInputValue(key: "finish_system", title: "Finish System", numericValue: nil, stringValue: "standard_finish", unitLabel: nil, notes: "Future finish schedule key.")
            ], notes: ["Manual finish placeholder only."]),
            profile(id: "permits.requirements", title: "Permit and Engineering Requirements", allowanceAmount: 1650, feeAmount: 450, markupPercent: 0, scheduleInputs: [
                PricingScheduleInputValue(key: "jurisdiction_schedule", title: "Jurisdiction Schedule", numericValue: nil, stringValue: "default_jurisdiction", unitLabel: nil, notes: "Future jurisdiction fee table key.")
            ], notes: ["Allowance + admin placeholder only."]),
            profile(id: "closeout.coordination", title: "Project Coordination and Closeout", feeAmount: 360, markupPercent: 18, scheduleInputs: [
                PricingScheduleInputValue(key: "closeout_hours", title: "Closeout Hours", numericValue: 3, stringValue: nil, unitLabel: "hrs", notes: "Draft coordination schedule placeholder.")
            ], notes: ["Draft coordination placeholder only."])
        ],
        importReport: nil
    )

    private static func profile(
        id: String,
        title: String,
        draftUnitCost: Double? = nil,
        draftUnitPrice: Double? = nil,
        allowanceAmount: Double? = nil,
        feeAmount: Double? = nil,
        markupPercent: Double? = nil,
        scheduleInputs: [PricingScheduleInputValue] = [],
        notes: [String] = []
        ) -> PricingRuleConfigurationProfile {
        PricingRuleConfigurationProfile(
            id: id,
            title: title,
            draftUnitCost: draftUnitCost,
            draftUnitPrice: draftUnitPrice,
            allowanceAmount: allowanceAmount,
            feeAmount: feeAmount,
            markupPercent: markupPercent,
            scheduleInputs: scheduleInputs,
            notes: notes,
            importMetadata: nil
        )
    }

    func withImportReport(
        sourceKind: PricingConfigurationSourceKind,
        sourceDescription: String,
        report: PricingConfigurationImportReport
    ) -> PricingConfigurationSnapshot {
        PricingConfigurationSnapshot(
            id: id,
            version: version,
            sourceKind: sourceKind,
            sourceDescription: sourceDescription,
            profiles: profiles,
            importReport: report
        )
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
                        quantityBasisLabel: "Per Scope Review",
                        unitLabel: "scope",
                        defaultQuantitySeed: 1,
                        strategy: .lookupOnly,
                        draftRuleKey: "site_review.scope_complexity",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.site-conditions-review.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.site-conditions-review.unit_price",
                        subtotalPlaceholderKey: "draft.site-conditions-review.subtotal",
                        seedNotes: ["Mapped inputs identify site complexity factors without pricing them yet."],
                        assumptions: ["Treat as one review bucket until labor tiers and adders are defined."],
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
                        quantityBasisLabel: "Supporting Document Count",
                        unitLabel: "document",
                        defaultQuantitySeed: nil,
                        strategy: .lookupOnly,
                        draftRuleKey: "documents.review_tier",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.document-verification-and-layout.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.document-verification-and-layout.unit_price",
                        subtotalPlaceholderKey: "draft.document-verification-and-layout.subtotal",
                        seedNotes: ["Counts only repeatable additional documents today; fixed slots remain separate mapped context."],
                        assumptions: ["Administrative review effort may later combine count thresholds with flat setup fees."],
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
                        quantityBasisLabel: "Footprint Area",
                        unitLabel: "sq ft",
                        defaultQuantitySeed: nil,
                        strategy: .quantityTimesRate,
                        draftRuleKey: "structure.base_package",
                        draftFormulaKey: "structure.area_times_rate",
                        draftUnitCostPlaceholderKey: "draft.frame-and-roof-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.frame-and-roof-package.unit_price",
                        subtotalPlaceholderKey: "draft.frame-and-roof-package.subtotal",
                        seedNotes: ["Area is derived from width x projection from the current scope."],
                        assumptions: ["Real structural formulas, waste factors, and vendor rates remain deferred."],
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
                        quantityBasisLabel: "Perimeter",
                        unitLabel: "lf",
                        defaultQuantitySeed: nil,
                        strategy: .lookupOnly,
                        draftRuleKey: "structure.attachment_support_conditions",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.attachment-and-support-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.attachment-and-support-package.unit_price",
                        subtotalPlaceholderKey: "draft.attachment-and-support-package.subtotal",
                        seedNotes: ["Perimeter is available now as a useful draft sizing proxy for support and attachment work."],
                        assumptions: ["Later formulas may split wall attachment, posts, and special mounting into separate buckets."],
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
                        quantityBasisLabel: "Perimeter",
                        unitLabel: "lf",
                        defaultQuantitySeed: nil,
                        strategy: .lookupOnly,
                        draftRuleKey: "enclosure.screen_wall_selection",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.screen-or-wall-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.screen-or-wall-package.unit_price",
                        subtotalPlaceholderKey: "draft.screen-or-wall-package.subtotal",
                        seedNotes: ["Screen and wall selections are seeded separately from window and door pricing."],
                        assumptions: ["Final product families and vendor-specific rates are intentionally deferred."],
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
                        quantityBasisLabel: "Window Bays",
                        unitLabel: "bay",
                        defaultQuantitySeed: nil,
                        strategy: .quantityTimesRate,
                        draftRuleKey: "windows.system_selection",
                        draftFormulaKey: "windows.bay_times_rate",
                        draftUnitCostPlaceholderKey: "draft.window-system-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.window-system-package.unit_price",
                        subtotalPlaceholderKey: "draft.window-system-package.subtotal",
                        seedNotes: ["Bay count is pulled directly from the current enclosure selections when available."],
                        assumptions: ["Later rules may include per-bay modifiers for height, glass, operation, and configuration."],
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
                        quantitySource: .kneeWallLinearFeet,
                        quantityBasisLabel: "Knee Wall Linear Footage",
                        unitLabel: "lf",
                        defaultQuantitySeed: 1,
                        strategy: .allowance,
                        draftRuleKey: "knee_wall.selection",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.knee-wall-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.knee-wall-package.unit_price",
                        subtotalPlaceholderKey: "draft.knee-wall-package.subtotal",
                        seedNotes: ["Uses linear footage from the scope when parseable and otherwise falls back to one scoped allowance bucket."],
                        assumptions: ["Keep as an allowance-style bucket until wall build-up and finish rules are confirmed."],
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
                        quantityBasisLabel: "Per Door Package",
                        unitLabel: "door",
                        defaultQuantitySeed: 1,
                        strategy: .manualAmount,
                        draftRuleKey: "doors.package_selection",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.door-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.door-package.unit_price",
                        subtotalPlaceholderKey: "draft.door-package.subtotal",
                        seedNotes: ["Door selections stay centralized here so later vendor/product swaps do not affect views."],
                        assumptions: ["Assumes one bucket per scoped door package until multi-door counting is captured explicitly."],
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
                        quantityBasisLabel: "Outlet Count",
                        unitLabel: "outlet",
                        defaultQuantitySeed: 1,
                        strategy: .lookupOnly,
                        draftRuleKey: "electrical.scope_package",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.electrical-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.electrical-package.unit_price",
                        subtotalPlaceholderKey: "draft.electrical-package.subtotal",
                        seedNotes: ["Outlet count is currently the strongest structured quantity seed for the electrical bucket."],
                        assumptions: ["Lighting, fan, switching, and circuit adders remain deferred rule inputs."],
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
                        quantityBasisLabel: "Per Drainage Package",
                        unitLabel: "package",
                        defaultQuantitySeed: 1,
                        strategy: .manualAmount,
                        draftRuleKey: "drainage.scope_package",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.drainage-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.drainage-package.unit_price",
                        subtotalPlaceholderKey: "draft.drainage-package.subtotal",
                        seedNotes: ["Drainage remains a scoped package until gutter lengths and tie-in quantities are captured structurally."],
                        assumptions: ["Manual package pricing is safer than inventing unsupported gutter/downspout formulas now."],
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
                        quantityBasisLabel: "Per Finish Package",
                        unitLabel: "package",
                        defaultQuantitySeed: 1,
                        strategy: .manualAmount,
                        draftRuleKey: "finishes.scope_package",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.finish-package.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.finish-package.unit_price",
                        subtotalPlaceholderKey: "draft.finish-package.subtotal",
                        seedNotes: ["Finish selections are seeded as one package until trim and paint quantities are captured more granularly."],
                        assumptions: ["Do not force vendor paint or trim logic until the business inputs are finalized."],
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
                        quantityBasisLabel: "Per Permit / Engineering Package",
                        unitLabel: "package",
                        defaultQuantitySeed: 1,
                        strategy: .allowance,
                        draftRuleKey: "permits.requirements",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.permit-and-engineering-allowance.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.permit-and-engineering-allowance.unit_price",
                        subtotalPlaceholderKey: "draft.permit-and-engineering-allowance.subtotal",
                        seedNotes: ["Requirement flags are captured now even though jurisdictional pricing is not finalized."],
                        assumptions: ["Permit and engineering costs remain allowance-style until external fee schedules are supplied."],
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
                        quantitySource: .supportingArtifactCount,
                        quantityBasisLabel: "Supporting Artifact Count",
                        unitLabel: "artifact",
                        defaultQuantitySeed: 1,
                        strategy: .lookupOnly,
                        draftRuleKey: "closeout.coordination",
                        draftFormulaKey: nil,
                        draftUnitCostPlaceholderKey: "draft.project-coordination-and-closeout.unit_cost",
                        draftUnitPricePlaceholderKey: "draft.project-coordination-and-closeout.unit_price",
                        subtotalPlaceholderKey: "draft.project-coordination-and-closeout.subtotal",
                        seedNotes: ["Seeds from attached documents, photos, and sketches to reflect current closeout/admin complexity."],
                        assumptions: ["Coordination pricing may later combine flat project management fees with artifact-based adders."],
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

    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func currencyString(from amount: Double) -> String {
        currency.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

private extension Array where Element == String {
    var nilIfEmpty: [String]? {
        isEmpty ? nil : self
    }
}

private extension ImportedPricingRow {
    func isPricingEquivalent(to other: ImportedPricingRow) -> Bool {
        ruleID == other.ruleID &&
            groupID?.nilIfBlank == other.groupID?.nilIfBlank &&
            scheduleInputKey?.nilIfBlank == other.scheduleInputKey?.nilIfBlank &&
            valueKind == other.valueKind &&
            numericValue == other.numericValue &&
            stringValue?.nilIfBlank == other.stringValue?.nilIfBlank
    }
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
