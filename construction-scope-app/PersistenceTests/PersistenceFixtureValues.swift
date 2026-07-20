import Foundation

enum PersistenceFixtureValues {
    static let scopeID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    static let irrigationDocumentID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    static let additionalDocumentID = UUID(uuidString: "ABABABAB-CDCD-EFEF-0101-232323232323")!
    static let additionalAttachmentID = UUID(uuidString: "BCBCBCBC-DEDE-F0F0-1212-343434343434")!
    static let photoID = UUID(uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF")!
    static let sketchID = UUID(uuidString: "CCCCCCCC-DDDD-EEEE-FFFF-AAAAAAAAAAAA")!
    static let electricalMeasurementID = UUID(uuidString: "10101010-2020-3030-4040-505050505050")!
    static let drainageMeasurementID = UUID(uuidString: "20202020-3030-4040-5050-606060606060")!
    static let attachmentMeasurementID = UUID(uuidString: "30303030-4040-5050-6060-707070707070")!
    static let finishMeasurementID = UUID(uuidString: "40404040-5050-6060-7070-808080808080")!
    static let fixtureDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func makeBaselineScope() -> JobScope {
        let irrigationDocument = DocumentAttachmentFile(
            id: irrigationDocumentID,
            originalFilename: "fixture-irrigation.pdf",
            filePath: "/sanitized/ScopeAssets/fixture/fixture-irrigation.pdf",
            contentTypeIdentifier: "com.adobe.pdf",
            source: .files,
            createdAt: fixtureDate
        )
        let additionalDocument = AdditionalDocumentAttachment(
            id: additionalDocumentID,
            name: "Fixture additional document",
            attachment: DocumentAttachmentFile(
                id: additionalAttachmentID,
                originalFilename: "fixture-additional.jpg",
                filePath: "/sanitized/ScopeAssets/fixture/fixture-additional.jpg",
                contentTypeIdentifier: "public.jpeg",
                source: .camera,
                createdAt: fixtureDate
            )
        )

        return JobScope(
            id: scopeID,
            createdAt: fixtureDate,
            lastOpenedAt: fixtureDate,
            updatedAt: fixtureDate,
            status: .sold,
            jobNumber: "COMPAT-001",
            scopeTitle: "Persistence Compatibility Fixture",
            jobTreadCustomer: JobTreadCustomerRef(
                customerID: "fixture-customer-id",
                displayName: "Fixture Customer",
                accountType: "customer",
                primaryAddress: "100 Fixture Lane",
                fetchedAt: fixtureDate
            ),
            jobTreadJob: JobTreadJobRef(
                jobID: "fixture-job-id",
                jobNumber: "COMPAT-001",
                title: "Fixture Job",
                fetchedAt: fixtureDate
            ),
            jobTreadSync: JobTreadSyncMetadata(
                status: .succeeded,
                lastAttemptAt: fixtureDate,
                lastSucceededAt: fixtureDate
            ),
            projectInfo: ProjectInfo(
                clientName: "Fixture Customer",
                address: "100 Fixture Lane",
                city: "Fixture City",
                state: "CO",
                zip: "80000",
                salesperson: "Fixture Salesperson",
                projectType: .screenRoom,
                notes: "Baseline continuity marker"
            ),
            existingConditions: ExistingConditions(
                houseStories: .oneStory,
                existingStructure: [.existingPatioCover],
                obstaclesNotes: "Fixture obstacle note",
                photoChecklist: PhotoChecklist(frontOfHouse: true)
            ),
            dimensions: Dimensions(
                width: 12,
                projection: 16,
                fasciaHeight: 9,
                beamHeight: 8,
                roofStyle: .gable,
                elevationNotes: "Fixture elevation note"
            ),
            electrical: Electrical(
                outletCount: 2,
                fanInstall: true,
                switchLocations: "Fixture switch location",
                notes: "Fixture electrical note",
                measurements: measurementBlock(
                    id: electricalMeasurementID,
                    type: "Electrical fixture",
                    value: "2 outlets"
                )
            ),
            drainage: Drainage(
                gutters: true,
                downspoutLocations: "Fixture downspout location",
                drainTieIn: false,
                slopeNotes: "Fixture slope note",
                measurements: measurementBlock(
                    id: drainageMeasurementID,
                    type: "Drainage fixture",
                    value: "16 ft"
                )
            ),
            attachment: AttachmentConditions(
                houseWallMaterial: .brick,
                trimPresent: true,
                notes: "Fixture attachment note",
                measurements: measurementBlock(
                    id: attachmentMeasurementID,
                    type: "Attachment fixture",
                    value: "9 ft"
                )
            ),
            documents: DocumentsSection(
                irrigation: irrigationDocument,
                propertySurvey: nil,
                additionalAttachments: [additionalDocument]
            ),
            finishes: Finishes(
                trimType: "Fixture trim",
                paintOrPowderColor: "Fixture color",
                sidingReplacementRequired: false,
                measurements: measurementBlock(
                    id: finishMeasurementID,
                    type: "Finish fixture",
                    value: "4 pieces"
                )
            ),
            permitsHOA: PermitsHOA(
                permitRequired: true,
                jurisdiction: "Fixture jurisdiction",
                hoaApprovalRequired: false,
                engineeringRequired: true
            ),
            production: ProductionOrderMeta(
                startDate: fixtureDate,
                crewLead: "Fixture Crew",
                durationEstimate: "2 days",
                materialOrderStatus: .ordered,
                permitStatus: .approved
            ),
            customerApproval: CustomerApproval(
                optionsConfirmedText: "Fixture approval",
                signaturePNGPath: "/sanitized/ScopeAssets/fixture/customer-signature.png",
                signedDate: fixtureDate
            ),
            photos: [
                PhotoAttachment(
                    id: photoID,
                    caption: "Fixture photo",
                    imagePath: "/sanitized/ScopeAssets/fixture/photo.jpg",
                    createdAt: fixtureDate
                )
            ],
            sketches: [
                SketchAttachment(
                    id: sketchID,
                    title: "Fixture sketch",
                    drawingDataPath: "/sanitized/ScopeAssets/fixture/sketch.drawing",
                    previewPNGPath: "/sanitized/ScopeAssets/fixture/sketch.png",
                    createdAt: fixtureDate
                )
            ]
        )
    }

    private static func measurementBlock(id: UUID, type: String, value: String) -> MeasurementsBlock {
        MeasurementsBlock(
            isEnabled: true,
            items: [
                MeasurementItem(
                    id: id,
                    type: type,
                    value: value,
                    notes: "Sanitized measurement marker"
                )
            ]
        )
    }
}
