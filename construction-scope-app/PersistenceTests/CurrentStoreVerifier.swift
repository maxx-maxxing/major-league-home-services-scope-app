import Foundation
import SwiftData

@main
struct CurrentStoreVerifier {
    private static let voiceNoteID = UUID(uuidString: "DDDDDDDD-EEEE-FFFF-AAAA-BBBBBBBBBBBB")!
    private static let draftID = UUID(uuidString: "EEEEEEEE-FFFF-AAAA-BBBB-CCCCCCCCCCCC")!
    private static let suggestionID = UUID(uuidString: "FFFFFFFF-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!
    private static let aiCreatedAt = Date(timeIntervalSince1970: 1_700_000_100)
    private static let aiUpdatedAt = Date(timeIntervalSince1970: 1_700_000_200)

    static func main() {
        do {
            try run()
        } catch {
            FileHandle.standardError.write(
                Data("Current fixture verifier failed: \(error)\n".utf8)
            )
            exit(EXIT_FAILURE)
        }
    }

    private static func run() throws {
        guard CommandLine.arguments.count == 3 else {
            throw PersistenceCompatibilityHarnessError.invalidArguments
        }

        let storeURL = try PersistenceHarnessPathGuard.validatedStoreURL(
            CommandLine.arguments[1],
            mustExist: true
        )
        let mode = CommandLine.arguments[2]
        let schema = Schema([JobScope.self])
        let configuration = ModelConfiguration(
            "ContinuityFixture",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let scopes = try context.fetch(FetchDescriptor<JobScope>())

        guard scopes.count == 1, let scope = scopes.first else {
            throw PersistenceCompatibilityHarnessError.unexpectedScopeCount(scopes.count)
        }
        try verifyBaselineValues(in: scope)

        switch mode {
        case "upgrade":
            guard scope.voiceNotes == nil, scope.aiExtractionDrafts == nil else {
                throw PersistenceCompatibilityHarnessError.newFieldsUnexpectedlyPopulated
            }

            scope.voiceNotes = [expectedVoiceNote]
            scope.aiExtractionDrafts = [expectedDraft]
            try context.save()
            print("Current schema opened baseline store and saved additive fields")
        case "verify":
            guard scope.voiceNotes == [expectedVoiceNote],
                  scope.aiExtractionDrafts == [expectedDraft] else {
                throw PersistenceCompatibilityHarnessError.additiveDataDidNotPersist
            }
            print("Current schema reopened upgraded store with baseline and additive data intact")
        default:
            throw PersistenceCompatibilityHarnessError.invalidMode(mode)
        }
    }

    private static func verifyBaselineValues(in scope: JobScope) throws {
        let expected = PersistenceFixtureValues.makeBaselineScope()
        try require(scope.id == expected.id, field: "id")
        try require(scope.createdAt == expected.createdAt, field: "createdAt")
        try require(scope.lastOpenedAt == expected.lastOpenedAt, field: "lastOpenedAt")
        try require(scope.updatedAt == expected.updatedAt, field: "updatedAt")
        try require(scope.status == expected.status, field: "status")
        try require(scope.jobNumber == expected.jobNumber, field: "jobNumber")
        try require(scope.scopeTitle == expected.scopeTitle, field: "scopeTitle")
        try require(scope.jobTreadCustomer == expected.jobTreadCustomer, field: "jobTreadCustomer")
        try require(scope.jobTreadJob == expected.jobTreadJob, field: "jobTreadJob")
        try require(scope.jobTreadSync == expected.jobTreadSync, field: "jobTreadSync")
        try require(scope.projectInfo == expected.projectInfo, field: "projectInfo")
        try require(scope.existingConditions == expected.existingConditions, field: "existingConditions")
        try require(scope.dimensions == expected.dimensions, field: "dimensions")
        try require(scope.structuralSystem == expected.structuralSystem, field: "structuralSystem")
        try require(scope.enclosure == expected.enclosure, field: "enclosure")
        try require(scope.electrical?.outletCount == expected.electrical?.outletCount, field: "electrical.outletCount")
        try require(scope.electrical?.lighting == expected.electrical?.lighting, field: "electrical.lighting")
        try require(scope.electrical?.fanInstall == expected.electrical?.fanInstall, field: "electrical.fanInstall")
        try require(scope.electrical?.switchLocations == expected.electrical?.switchLocations, field: "electrical.switchLocations")
        try require(scope.electrical?.dedicatedCircuits == expected.electrical?.dedicatedCircuits, field: "electrical.dedicatedCircuits")
        try require(scope.electrical?.notes == expected.electrical?.notes, field: "electrical.notes")
        try require(scope.electrical?.measurements == expected.electrical?.measurements, field: "electrical.measurements")
        try require(scope.drainage == expected.drainage, field: "drainage")
        try require(scope.attachment == expected.attachment, field: "attachment")
        try require(scope.documents == expected.documents, field: "documents")
        try require(scope.finishes == expected.finishes, field: "finishes")
        try require(scope.permitsHOA == expected.permitsHOA, field: "permitsHOA")
        try require(scope.production == expected.production, field: "production")
        try require(scope.customerApproval == expected.customerApproval, field: "customerApproval")
        try require(scope.photos == expected.photos, field: "photos")
        try require(scope.sketches == expected.sketches, field: "sketches")
    }

    private static func require(_ matches: Bool, field: String) throws {
        guard matches else {
            throw PersistenceCompatibilityHarnessError.baselineDataChanged(field)
        }
    }

    private static var expectedVoiceNote: ScopeVoiceNote {
        ScopeVoiceNote(
            id: voiceNoteID,
            audioPath: "ScopeAssets/fixture/voice-note.m4a",
            transcript: "Sanitized fixture transcript",
            transcriptStatus: .succeeded,
            transcriptErrorMessage: "Sanitized recovered retry marker",
            durationSeconds: 12.5,
            createdAt: aiCreatedAt,
            updatedAt: aiUpdatedAt
        )
    }

    private static var expectedDraft: ScopeAIExtractionDraft {
        ScopeAIExtractionDraft(
            id: draftID,
            sourceVoiceNoteID: voiceNoteID,
            status: .applied,
            summary: "Sanitized fixture draft",
            suggestedFields: [
                ScopeAIFieldSuggestion(
                    id: suggestionID,
                    sectionKey: "project_info",
                    fieldKey: "notes",
                    label: "Notes",
                    proposedValue: "Fixture suggestion",
                    confidence: .high,
                    isApplied: true,
                    createdAt: aiCreatedAt
                )
            ],
            remainingSectionKeys: ["dimensions", "electrical"],
            createdAt: aiCreatedAt,
            updatedAt: aiUpdatedAt
        )
    }
}

private enum PersistenceCompatibilityHarnessError: Error {
    case invalidArguments
    case invalidMode(String)
    case unexpectedScopeCount(Int)
    case baselineDataChanged(String)
    case newFieldsUnexpectedlyPopulated
    case additiveDataDidNotPersist
}
