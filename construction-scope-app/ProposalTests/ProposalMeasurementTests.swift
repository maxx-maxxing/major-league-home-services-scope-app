import Foundation

// Asset enumeration is outside this mapping test. Never read a user's app data.
enum ChecklistPhotoAssetStore {
    static func summary(scopeID: UUID) -> String? { nil }
}

private struct CheckFailure: Error { let label: String }

@main
struct ProposalMeasurementTests {
    static func require(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try condition() else { throw CheckFailure(label: label) }
    }

    static func scope(_ types: [ProjectType] = [.screenRoom, .sunroom]) -> JobScope {
        let scope = ScopeTemplate.makeNewScope()
        scope.projectInfo.projectTypes = types
        return scope
    }

    static func block(_ value: String, enabled: Bool? = true) -> MeasurementsBlock {
        MeasurementsBlock(isEnabled: enabled, items: [MeasurementItem(type: "Width", value: value)])
    }

    static func populate(_ scope: JobScope, enabled: Bool? = true) {
        scope.structuralSystem = StructuralSystem(measurements: block("12' 6\"", enabled: enabled))
        scope.enclosure = Enclosure(
            screenMeasurements: block("screen width", enabled: enabled),
            sunroomMeasurements: block("sunroom width", enabled: enabled)
        )
        scope.electrical = Electrical(measurements: block("electrical run", enabled: enabled))
        scope.drainage = Drainage(measurements: block("drain drop", enabled: enabled))
        scope.attachment = AttachmentConditions(measurements: block("attachment offset", enabled: enabled))
        scope.finishes = Finishes(measurements: block("finish thickness", enabled: enabled))
    }

    static let measurementKeys: [ScopeInputKey] = [
        .structuralMeasurements, .screenMeasurements, .sunroomMeasurements,
        .electricalMeasurements, .drainageMeasurements, .attachmentMeasurements, .finishMeasurements
    ]

    static func testAllOwnersAndProposalRouting() throws {
        let scope = scope()
        populate(scope)
        let snapshot = ProposalFoundationBuilder.compose(scope: scope)
        let owners: [(ScopeInputKey, ScopeCaptureSectionKey, ProposalTemplateSectionID, String)] = [
            (.structuralMeasurements, .structuralSystem, .structuralSystem, "12' 6\""),
            (.screenMeasurements, .enclosure, .enclosureAndOpenings, "screen width"),
            (.sunroomMeasurements, .enclosure, .enclosureAndOpenings, "sunroom width"),
            (.electricalMeasurements, .electrical, .electricalAndDrainage, "electrical run"),
            (.drainageMeasurements, .drainage, .electricalAndDrainage, "drain drop"),
            (.attachmentMeasurements, .attachmentConditions, .siteConditions, "attachment offset"),
            (.finishMeasurements, .finishes, .finishesAndPermitting, "finish thickness")
        ]
        for (key, owner, destination, value) in owners {
            try require(snapshot.input.values(for: owner).contains { $0.key == key && $0.displayValue == "Width: \(value)" }, "measurement missing from owning input section")
            guard let section = snapshot.proposal.sections.first(where: { $0.id == destination }) else {
                throw CheckFailure(label: "proposal destination missing")
            }
            try require(section.isIncluded, "measurements-only proposal destination excluded")
            try require((section.customerFacingValues + section.internalValues).contains { $0.key == key }, "measurement missing from composed proposal")
            try require(snapshot.input.value(for: key)?.numericValue == nil, "free-form measurement became a numeric quantity")
        }
        try require(snapshot.template.version == 2 && snapshot.input.templateVersion == 2, "new composition contract not versioned")
        let decoded = try JSONDecoder().decode(ProposalFoundationSnapshot.self, from: JSONEncoder().encode(snapshot))
        try require(decoded == snapshot, "proposal snapshot failed Codable round trip")
    }

    static func testRepeatedCustomAndPartialRows() throws {
        let scope = scope([.patioCover])
        scope.structuralSystem = StructuralSystem(measurements: MeasurementsBlock(isEnabled: true, items: [
            MeasurementItem(type: "Width", value: " 12' 6\" ", notes: "confirm on site"),
            MeasurementItem(type: "Width", value: "approx 8 feet"),
            MeasurementItem(type: "Other", customType: " Roof offset ", value: "2 1/2 inches"),
            MeasurementItem(notes: "measure after trim removal"),
            MeasurementItem(type: "Other", value: "unknown"),
            MeasurementItem(type: "Width", value: " \n "),
            MeasurementItem()
        ]))
        let expected = "Width: 12' 6\"\nNotes: confirm on site\n\nWidth: approx 8 feet\n\nRoof offset: 2 1/2 inches\n\nMeasurement: Notes: measure after trim removal\n\nOther: unknown"
        let input = ProposalFoundationBuilder.makeCompositionInput(scope: scope)
        try require(input.value(for: .structuralMeasurements)?.displayValue == expected, "row order, units, custom label, or notes changed")
        let ids = input.sections.flatMap(\.values).map(\.id)
        try require(Set(ids).count == ids.count, "repeat rows produced duplicate proposal value identities")
    }

    static func testDisabledAndEmptyBlocks() throws {
        for enabled: Bool? in [false, nil] {
            let scope = scope()
            populate(scope, enabled: enabled)
            let input = ProposalFoundationBuilder.makeCompositionInput(scope: scope)
            try require(measurementKeys.allSatisfy { input.value(for: $0) == nil }, "disabled block leaked into proposal")
            try require(scope.structuralSystem?.measurements?.items?.first?.value == "12' 6\"", "disabled stored rows were erased")
        }
        let scope = scope()
        scope.structuralSystem = StructuralSystem(measurements: MeasurementsBlock(isEnabled: true, items: [MeasurementItem(type: "Width", value: " ", notes: "\n")]))
        try require(ProposalFoundationBuilder.makeCompositionInput(scope: scope).value(for: .structuralMeasurements) == nil, "label-only row emitted")
    }

    static func testProjectVisibilityAndSeparateEnclosureOwners() throws {
        for type in ProjectType.selectableCases {
            let scope = scope([type])
            populate(scope)
            let input = ProposalFoundationBuilder.makeCompositionInput(scope: scope)
            let visible = ScopeSection.visibleSectionSet(for: scope)
            let owners: [(ScopeInputKey, ScopeSection)] = [
                (.structuralMeasurements, .structuralSystem), (.screenMeasurements, .enclosure),
                (.sunroomMeasurements, .windowsAndGlass), (.electricalMeasurements, .electrical),
                (.drainageMeasurements, .drainage), (.attachmentMeasurements, .attachmentConditions),
                (.finishMeasurements, .finishes)
            ]
            for (key, owner) in owners {
                try require((input.value(for: key) != nil) == visible.contains(owner), "project-hidden or visible owner mapped incorrectly")
            }
        }
        let scope = scope([])
        populate(scope)
        let input = ProposalFoundationBuilder.makeCompositionInput(scope: scope)
        try require(measurementKeys.allSatisfy { input.value(for: $0) == nil }, "measurements emitted before project selection")
    }

    static func testLegacyExcludedAndNoPricingInference() throws {
        let scope = scope([.screenRoom])
        populate(scope)
        scope.dimensions = Dimensions(width: 900, projection: 800, fasciaHeight: 7, beamHeight: 6, roofStyle: .gable, attachmentType: .wallMount, elevationNotes: "legacy-only-marker")
        let before = scope.dimensions
        let snapshot = ProposalFoundationBuilder.compose(scope: scope)
        let legacyKeys: [ScopeInputKey] = [.widthFeet, .projectionFeet, .fasciaHeightFeet, .beamHeightFeet, .roofStyle, .attachmentType, .elevationNotes]
        try require(snapshot.input.values(for: .dimensions).isEmpty, "retired global dimensions section emitted")
        try require(legacyKeys.allSatisfy { snapshot.input.value(for: $0) == nil }, "hidden legacy dimensions leaked")
        for component in snapshot.proposal.pricingGroups.flatMap(\.components) {
            if let source = component.quantitySource, [.widthFeet, .projectionFeet, .areaSquareFeet, .perimeterFeet].contains(source) {
                try require(component.quantityValue == nil, "legacy or free-form measurement seeded draft pricing")
            }
        }
        try require(scope.dimensions == before, "legacy source data mutated")
        try require(scope.structuralSystem?.measurements?.items?.first?.value == "12' 6\"", "current source measurement mutated")
        try require(try JSONDecoder().decode(ScopeCaptureSectionKey.self, from: Data("\"dimensions\"".utf8)) == .dimensions, "legacy snapshot section no longer decodes")
        try require(try JSONDecoder().decode(ScopeInputKey.self, from: Data("\"widthFeet\"".utf8)) == .widthFeet, "legacy snapshot field no longer decodes")
    }

    static func testUnrelatedNumericInputsPreserved() throws {
        let scope = scope([.sunroom])
        scope.enclosure = Enclosure(windowSystem: WindowSystem(numBays: 3))
        scope.electrical = Electrical(outletCount: 2)
        let snapshot = ProposalFoundationBuilder.compose(scope: scope)
        try require(snapshot.input.value(for: .windowBayCount)?.numericValue == 3, "window bay input regressed")
        try require(snapshot.input.value(for: .outletCount)?.numericValue == 2, "outlet count input regressed")
    }

    static func main() throws {
        try testAllOwnersAndProposalRouting()
        try testRepeatedCustomAndPartialRows()
        try testDisabledAndEmptyBlocks()
        try testProjectVisibilityAndSeparateEnclosureOwners()
        try testLegacyExcludedAndNoPricingInference()
        try testUnrelatedNumericInputsPreserved()
        print("Proposal measurement regression tests passed (6 groups)")
    }
}
