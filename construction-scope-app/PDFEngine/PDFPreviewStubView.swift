import SwiftUI
import PDFKit
import UIKit

struct ScopePDFPreviewSheet: View {
    let scope: JobScope

    @Environment(\.dismiss) private var dismiss
    @State private var pdfData: Data?
    @State private var missingFields: [String] = []
    @State private var errorMessage: String?
    @State private var exportURL: URL?
    @State private var showingShareSheet = false

    var body: some View {
        Group {
            if let pdfData {
                VStack(spacing: 12) {
                    if !missingFields.isEmpty {
                        GlassChromePanel(cornerRadius: 24) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Missing Required Fields")
                                    .font(.headline)

                                ForEach(missingFields, id: \.self) { field in
                                    Text("• \(field)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    PDFDocumentView(data: pdfData)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            } else if let errorMessage {
                ContentUnavailableView(
                    "Preview Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                ProgressView("Generating Preview")
            }
        }
        .background(LiquidGlassBackdrop())
        .navigationTitle("PDF Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportPreviewPDF()
                } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .disabled(pdfData == nil)
            }
        }
        .onAppear {
            loadPreview()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let exportURL {
                ActivityShareSheet(items: [exportURL])
            }
        }
    }

    private func loadPreview() {
        do {
            let render = try ScopePDFExporter.render(scope: scope)
            pdfData = render.data
            missingFields = render.missingFields
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportPreviewPDF() {
        do {
            exportURL = try ScopePDFExporter.generate(scope: scope).fileURL
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PDFExportResult {
    let fileURL: URL
    let missingFields: [String]
}

enum ScopePDFExporter {
    enum ExportError: LocalizedError {
        case renderFailed

        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "The PDF could not be generated."
            }
        }
    }

    static func generate(scope: JobScope) throws -> PDFExportResult {
        let render = try render(scope: scope)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(render.filename)
            .appendingPathExtension("pdf")

        try render.data.write(to: outputURL, options: .atomic)
        return PDFExportResult(fileURL: outputURL, missingFields: render.missingFields)
    }

    static func render(scope: JobScope) throws -> (data: Data, missingFields: [String], filename: String) {
        let missing = missingRequiredFields(for: scope)
        let filename = makeFilename(for: scope)

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            let pages: [(String, [PDFSection])] = [
                pageOne(scope),
                pageTwo(scope),
                pageThree(scope),
                pageFour(scope),
                pageFive(scope)
            ] + appendixPages(scope)

            for (index, page) in pages.enumerated() {
                context.beginPage()
                let cg = context.cgContext
                drawHeader(in: cg, rect: pageRect, scope: scope)
                drawPageContent(in: cg, rect: pageRect, title: page.0, sections: page.1)
                drawFooter(in: cg, rect: pageRect, pageNumber: index + 1, totalPages: pages.count)
            }
        }

        guard !data.isEmpty else {
            throw ExportError.renderFailed
        }

        return (data: data, missingFields: missing, filename: filename)
    }

    private static func drawHeader(in context: CGContext, rect: CGRect, scope: JobScope) {
        let title = scope.projectInfo.clientName.nilIfBlank ?? "Untitled Scope"
        let address = scope.projectInfo.address.nilIfBlank ?? "No address"
        let type = scope.projectInfo.projectType.displayName
        let jobNumber = scope.jobNumber ?? "N/A"

        drawText(title, font: .boldSystemFont(ofSize: 18), in: CGRect(x: 40, y: 34, width: rect.width - 80, height: 22), context: context)
        drawText(address, font: .systemFont(ofSize: 11), in: CGRect(x: 40, y: 58, width: rect.width - 80, height: 16), context: context)
        drawText("Project Type: \(type)", font: .systemFont(ofSize: 10), in: CGRect(x: 40, y: 74, width: 260, height: 14), context: context)
        drawText("Job #: \(jobNumber)", font: .systemFont(ofSize: 10), in: CGRect(x: rect.width - 180, y: 74, width: 140, height: 14), context: context, alignment: .right)

        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: 94))
        context.addLine(to: CGPoint(x: rect.width - 40, y: 94))
        context.strokePath()
    }

    private static func drawFooter(in context: CGContext, rect: CGRect, pageNumber: Int, totalPages: Int) {
        let dateText = "Generated: \(Date.now.formatted(date: .abbreviated, time: .shortened))"
        drawText(dateText, font: .systemFont(ofSize: 9), in: CGRect(x: 40, y: rect.height - 32, width: 260, height: 12), context: context)
        drawText("Page \(pageNumber) of \(totalPages)", font: .systemFont(ofSize: 9), in: CGRect(x: rect.width - 160, y: rect.height - 32, width: 120, height: 12), context: context, alignment: .right)
    }

    private static func drawPageContent(in context: CGContext, rect: CGRect, title: String, sections: [PDFSection]) {
        drawText(title, font: .boldSystemFont(ofSize: 16), in: CGRect(x: 40, y: 108, width: rect.width - 80, height: 20), context: context)

        var y: CGFloat = 134
        for section in sections {
            if y > rect.height - 150 { break }
            drawText(section.title, font: .boldSystemFont(ofSize: 12), in: CGRect(x: 40, y: y, width: rect.width - 80, height: 16), context: context)
            y += 18

            for row in section.rows {
                let valueHeight = heightForText(row.value, font: .systemFont(ofSize: 10), width: 350)
                drawText(row.label, font: .systemFont(ofSize: 10), in: CGRect(x: 48, y: y, width: 150, height: max(14, valueHeight)), context: context)
                drawText(row.value, font: .systemFont(ofSize: 10), in: CGRect(x: 200, y: y, width: 350, height: max(14, valueHeight)), context: context)
                y += max(14, valueHeight) + 4
            }

            if let image = section.image {
                let imageRect = CGRect(x: 200, y: y + 4, width: 260, height: 90)
                image.draw(in: imageRect)
                y += 100
            }

            y += 10
        }
    }

    private static func pageOne(_ scope: JobScope) -> (String, [PDFSection]) {
        let project = scope.projectInfo
        let dims = scope.dimensions

        return (
            "Page 1: Job Header + Project Info + Key Dimensions",
            [
                PDFSection(title: "Project Information", rows: [
                    .init(label: "Client", value: project.clientName.nilIfBlank ?? "Not set"),
                    .init(label: "Address", value: project.address.nilIfBlank ?? "Not set"),
                    .init(label: "City / ZIP", value: combinedValue(project.city, project.zip)),
                    .init(label: "Phone", value: project.phone?.nilIfBlank ?? "Not set"),
                    .init(label: "Email", value: project.email?.nilIfBlank ?? "Not set"),
                    .init(label: "Salesperson", value: project.salesperson?.nilIfBlank ?? "Not set"),
                    .init(label: "Estimator", value: project.estimator?.nilIfBlank ?? "Not set"),
                    .init(label: "Site Visit", value: formattedDate(project.siteVisitDate)),
                    .init(label: "Project Type", value: project.projectType.displayName),
                    .init(label: "Notes", value: project.notes?.nilIfBlank ?? "None")
                ]),
                PDFSection(title: "Key Dimensions", rows: [
                    .init(label: "Width", value: formatNumber(dims?.width, suffix: "ft")),
                    .init(label: "Projection", value: formatNumber(dims?.projection, suffix: "ft")),
                    .init(label: "Fascia Height", value: formatNumber(dims?.fasciaHeight, suffix: "ft")),
                    .init(label: "Beam Height", value: formatNumber(dims?.beamHeight, suffix: "ft")),
                    .init(label: "Roof Style", value: dims?.roofStyle?.displayName ?? "Not set"),
                    .init(label: "Attachment Type", value: dims?.attachmentType?.displayName ?? "Not set"),
                    .init(label: "Elevation Notes", value: dims?.elevationNotes?.nilIfBlank ?? "None")
                ])
            ]
        )
    }

    private static func pageTwo(_ scope: JobScope) -> (String, [PDFSection]) {
        let existing = scope.existingConditions
        let attachment = scope.attachment

        return (
            "Page 2: Existing Conditions + Attachment Conditions",
            [
                PDFSection(title: "Existing Conditions", rows: [
                    .init(label: "House Stories", value: existing?.houseStories?.displayName ?? "Not set"),
                    .init(label: "Exterior Finish", value: existing?.exteriorFinish?.displayName ?? "Not set"),
                    .init(label: "Existing Structure", value: existing?.existingStructure?.displayName ?? "Not set"),
                    .init(label: "Obstacles", value: existing?.obstaclesNotes?.nilIfBlank ?? "None"),
                    .init(label: "Utilities", value: existing?.utilitiesNotes?.nilIfBlank ?? "None"),
                    .init(label: "HOA Notes", value: existing?.hoaNotes?.nilIfBlank ?? "None"),
                    .init(label: "Photo Checklist", value: photoChecklistSummary(existing?.photoChecklist))
                ]),
                PDFSection(title: "Attachment Conditions", rows: [
                    .init(label: "House Material", value: resolvedHouseWallMaterial(attachment)),
                    .init(label: "Mounting Type", value: attachment?.houseMountingType?.displayName ?? "Not set"),
                    .init(label: "Mount Condition", value: attachment?.mountCondition?.displayName ?? "Not set"),
                    .init(label: "Post Material", value: resolvedPostMaterial(attachment)),
                    .init(label: "Post Size / Spacing", value: combinedValue(attachment?.postSize, attachment?.postSpacing)),
                    .init(label: "Trim Present", value: boolString(attachment?.trimPresent)),
                    .init(label: "Trim Material", value: resolvedTrimMaterial(attachment)),
                    .init(label: "Trim Thickness", value: resolvedTrimThickness(attachment)),
                    .init(label: "Fastener Plan", value: attachment?.fastenerPlan?.map(\.displayName).joined(separator: ", ") ?? "Not set"),
                    .init(label: "Notes", value: attachment?.notes?.nilIfBlank ?? "None")
                ])
            ]
        )
    }

    private static func pageThree(_ scope: JobScope) -> (String, [PDFSection]) {
        let structural = scope.structuralSystem
        let enclosure = scope.enclosure

        return (
            "Page 3: Structural + Roof System + Enclosure",
            [
                PDFSection(title: "Structural System", rows: [
                    .init(label: "Frame Material", value: structural?.frameMaterial?.displayName ?? "Not set"),
                    .init(label: "Post Size", value: structural?.postSize?.nilIfBlank ?? "Not set"),
                    .init(label: "Beam Type", value: structural?.beamType?.nilIfBlank ?? "Not set"),
                    .init(label: "Roof System", value: structural?.roofSystem?.displayName ?? "Not set"),
                    .init(label: "Roof Color", value: structural?.roofColor?.nilIfBlank ?? "Not set"),
                    .init(label: "Frame Color", value: structural?.frameColor?.nilIfBlank ?? "Not set")
                ]),
                PDFSection(title: "Enclosure", rows: [
                    .init(label: "Type", value: enclosure?.enclosureType?.displayName ?? "Not set"),
                    .init(label: "Screen Type", value: enclosure?.screenWallType?.displayName ?? "Not set"),
                    .init(label: "Frame Color", value: resolvedStandardColor(enclosure?.screenFrameColor, custom: enclosure?.screenFrameColorCustom)),
                    .init(label: "Knee Wall", value: enclosure?.kneeWall?.option?.displayName ?? "Not set"),
                    .init(label: "Knee Wall Details", value: kneeWallSummary(enclosure?.kneeWall)),
                    .init(label: "Door Type", value: enclosure?.doors?.doorType?.displayName ?? "Not set"),
                    .init(label: "Door Notes", value: enclosure?.doors?.notes?.nilIfBlank ?? "None")
                ])
            ]
        )
    }

    private static func pageFour(_ scope: JobScope) -> (String, [PDFSection]) {
        let window = scope.enclosure?.windowSystem
        let electrical = scope.electrical
        let drainage = scope.drainage

        return (
            "Page 4: Windows/Glass + Knee Wall + Electrical + Drainage",
            [
                PDFSection(title: "Windows & Glass", rows: [
                    .init(label: "Window Type", value: window?.windowType?.displayName ?? "Not set"),
                    .init(label: "Frame System", value: window?.frameSystem?.displayName ?? "Not set"),
                    .init(label: "Glass Type", value: window?.glassType?.displayName ?? "Not set"),
                    .init(label: "Safety", value: window?.glassSafety?.displayName ?? "Not set"),
                    .init(label: "Grid", value: window?.gridOption?.displayName ?? "Not set"),
                    .init(label: "Operation", value: window?.operation?.displayName ?? "Not set"),
                    .init(label: "Frame Color", value: resolvedStandardColor(window?.color, custom: window?.colorCustom)),
                    .init(label: "Height / Bays", value: combinedValue(formatOptionalPDFNumber(window?.windowHeight, suffix: "ft"), formatOptionalPDFNumber(window?.numBays, suffix: "bays"))),
                    .init(label: "Configuration", value: window?.configuration?.displayName ?? "Not set")
                ]),
                PDFSection(title: "Electrical", rows: [
                    .init(label: "Outlets", value: formatNumber(electrical?.outletCount, suffix: "")),
                    .init(label: "Lighting", value: electrical?.lighting?.displayName ?? "Not set"),
                    .init(label: "Fan Install", value: boolString(electrical?.fanInstall)),
                    .init(label: "Switch Locations", value: electrical?.switchLocations?.nilIfBlank ?? "Not set"),
                    .init(label: "Dedicated Circuits", value: electrical?.dedicatedCircuits?.map(\.displayName).joined(separator: ", ") ?? "Not set"),
                    .init(label: "Notes", value: electrical?.notes?.nilIfBlank ?? "None")
                ]),
                PDFSection(title: "Drainage", rows: [
                    .init(label: "Gutters", value: boolString(drainage?.gutters)),
                    .init(label: "Downspouts", value: drainage?.downspoutLocations?.nilIfBlank ?? "Not set"),
                    .init(label: "Drain Tie-In", value: boolString(drainage?.drainTieIn)),
                    .init(label: "Drain Notes", value: drainage?.slopeNotes?.nilIfBlank ?? "None")
                ])
            ]
        )
    }

    private static func pageFive(_ scope: JobScope) -> (String, [PDFSection]) {
        let finishes = scope.finishes
        let permits = scope.permitsHOA
        let production = scope.production

        var signatureRows: [PDFRow] = [
            .init(label: "Signed Date", value: scope.customerApproval?.signedDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
        ]

        if let path = scope.customerApproval?.signaturePNGPath,
           let image = UIImage(contentsOfFile: path) {
            signatureRows.append(.init(label: "Signature", value: "Embedded"))

            return (
                "Page 5: Permits/HOA + Production Notes + Customer Signature",
                [
                    PDFSection(title: "Finishes", rows: [
                        .init(label: "Trim Type", value: finishes?.trimType?.nilIfBlank ?? "Not set"),
                        .init(label: "Paint / Powder", value: finishes?.paintOrPowderColor?.nilIfBlank ?? "Not set"),
                        .init(label: "Siding Replacement", value: boolString(finishes?.sidingReplacementRequired)),
                        .init(label: "Caulking / Sealing", value: finishes?.caulkingSealingNotes?.nilIfBlank ?? "None")
                    ]),
                    PDFSection(title: "Permits / HOA", rows: [
                        .init(label: "Permit Required", value: boolString(permits?.permitRequired)),
                        .init(label: "HOA Required", value: boolString(permits?.hoaApprovalRequired)),
                        .init(label: "Engineering Required", value: boolString(permits?.engineeringRequired)),
                        .init(label: "Jurisdiction", value: permits?.jurisdiction?.nilIfBlank ?? "Not set"),
                        .init(label: "Status Notes", value: permits?.statusNotes?.nilIfBlank ?? "None")
                    ]),
                    PDFSection(title: "Production", rows: [
                        .init(label: "Crew Lead", value: production?.crewLead?.nilIfBlank ?? "Not set"),
                        .init(label: "Start Date", value: production?.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"),
                        .init(label: "Duration", value: production?.durationEstimate?.nilIfBlank ?? "Not set"),
                        .init(label: "Material Status", value: production?.materialOrderStatus?.displayName ?? "Not set"),
                        .init(label: "Permit Status", value: production?.permitStatus?.displayName ?? "Not set"),
                        .init(label: "Notes", value: scope.customerApproval?.optionsConfirmedText?.nilIfBlank ?? "None")
                    ]),
                    PDFSection(title: "Customer Signature", rows: signatureRows, image: image)
                ]
            )
        }

        signatureRows.append(.init(label: "Signature", value: "Not captured"))
        return (
            "Page 5: Permits/HOA + Production Notes + Customer Signature",
            [
                PDFSection(title: "Finishes", rows: [
                    .init(label: "Trim Type", value: finishes?.trimType?.nilIfBlank ?? "Not set"),
                    .init(label: "Paint / Powder", value: finishes?.paintOrPowderColor?.nilIfBlank ?? "Not set"),
                    .init(label: "Siding Replacement", value: boolString(finishes?.sidingReplacementRequired)),
                    .init(label: "Caulking / Sealing", value: finishes?.caulkingSealingNotes?.nilIfBlank ?? "None")
                ]),
                PDFSection(title: "Permits / HOA", rows: [
                    .init(label: "Permit Required", value: boolString(permits?.permitRequired)),
                    .init(label: "HOA Required", value: boolString(permits?.hoaApprovalRequired)),
                    .init(label: "Engineering Required", value: boolString(permits?.engineeringRequired)),
                    .init(label: "Jurisdiction", value: permits?.jurisdiction?.nilIfBlank ?? "Not set"),
                    .init(label: "Status Notes", value: permits?.statusNotes?.nilIfBlank ?? "None")
                ]),
                PDFSection(title: "Production", rows: [
                    .init(label: "Crew Lead", value: production?.crewLead?.nilIfBlank ?? "Not set"),
                    .init(label: "Start Date", value: production?.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"),
                    .init(label: "Duration", value: production?.durationEstimate?.nilIfBlank ?? "Not set"),
                    .init(label: "Material Status", value: production?.materialOrderStatus?.displayName ?? "Not set"),
                    .init(label: "Permit Status", value: production?.permitStatus?.displayName ?? "Not set"),
                    .init(label: "Notes", value: scope.customerApproval?.optionsConfirmedText?.nilIfBlank ?? "None")
                ]),
                PDFSection(title: "Customer Signature", rows: signatureRows)
            ]
        )
    }

    private static func appendixPages(_ scope: JobScope) -> [(String, [PDFSection])] {
        var pages: [(String, [PDFSection])] = []

        if let photos = scope.photos, !photos.isEmpty {
            for (index, photo) in photos.enumerated() {
                guard let image = UIImage(contentsOfFile: photo.imagePath) else { continue }

                pages.append(
                    (
                        "Appendix: Photo \(index + 1)",
                        [PDFSection(title: photo.caption?.nilIfBlank ?? "Scope Photo \(index + 1)", rows: [
                            .init(label: "Captured", value: photo.createdAt.formatted(date: .abbreviated, time: .shortened)),
                            .init(label: "Caption", value: photo.caption?.nilIfBlank ?? "None")
                        ], image: image)]
                    )
                )
            }
        }

        if let diagram = scope.sketches?.first(where: { $0.title == "Site Diagram" }),
           let image = UIImage(contentsOfFile: diagram.previewPNGPath) {
            pages.append(
                (
                    "Appendix: Site Diagram",
                    [PDFSection(title: "Site Diagram", rows: [
                        .init(label: "Captured", value: diagram.createdAt.formatted(date: .abbreviated, time: .shortened))
                    ], image: image)]
                )
            )
        }

        return pages
    }

    private static func missingRequiredFields(for scope: JobScope) -> [String] {
        var missing: [String] = []
        if scope.projectInfo.clientName.nilIfBlank == nil { missing.append("Project Info: Client Name") }
        if scope.projectInfo.address.nilIfBlank == nil { missing.append("Project Info: Address") }
        return missing
    }

    private static func makeFilename(for scope: JobScope) -> String {
        let client = (scope.projectInfo.clientName.nilIfBlank ?? "Client")
            .components(separatedBy: .whitespacesAndNewlines)
            .last ?? "Client"
        let address = (scope.projectInfo.address.nilIfBlank ?? "Address")
            .replacingOccurrences(of: " ", with: "")
        let projectType = scope.projectInfo.projectType.displayName.replacingOccurrences(of: " ", with: "")
        return "\(sanitize(client))-\(sanitize(address))-\(sanitize(projectType))-Scope"
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "", options: .regularExpression)
    }

    private static func drawText(
        _ text: String,
        font: UIFont,
        in rect: CGRect,
        context: CGContext,
        alignment: NSTextAlignment = .left
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: style
        ]

        NSAttributedString(string: text, attributes: attributes).draw(with: rect, options: [.usesLineFragmentOrigin], context: nil)
    }

    private static func heightForText(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = (text as NSString).boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }

    private static func boolString(_ value: Bool?) -> String {
        guard let value else { return "Not set" }
        return value ? "Yes" : "No"
    }

    private static func formatNumber(_ value: Double?, suffix: String) -> String {
        guard let value else { return "Not set" }
        let rendered: String
        if value.rounded() == value {
            rendered = String(Int(value))
        } else {
            rendered = String(format: "%.2f", value)
        }
        return suffix.isEmpty ? rendered : "\(rendered) \(suffix)"
    }

    private static func formatOptionalPDFNumber(_ value: Double?, suffix: String) -> String? {
        guard let value else { return nil }
        return formatNumber(value, suffix: suffix)
    }

    private static func formattedDate(_ value: Date?) -> String {
        value?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"
    }

    private static func combinedValue(_ left: String?, _ right: String?) -> String {
        let values = [left?.nilIfBlank, right?.nilIfBlank].compactMap { $0 }
        return values.isEmpty ? "Not set" : values.joined(separator: " / ")
    }

    private static func resolvedStandardColor(_ color: StandardColorOption?, custom: String?) -> String {
        guard let color else { return "Not set" }
        if color == .custom {
            return custom?.nilIfBlank ?? color.displayName
        }
        return color.displayName
    }

    private static func resolvedHouseWallMaterial(_ attachment: AttachmentConditions?) -> String {
        guard let material = attachment?.houseWallMaterial else { return "Not set" }
        if material == .other {
            return attachment?.houseWallOther?.nilIfBlank ?? material.displayName
        }
        return material.displayName
    }

    private static func resolvedPostMaterial(_ attachment: AttachmentConditions?) -> String {
        guard let material = attachment?.postColumnMaterial else { return "Not set" }
        if material == .other {
            return attachment?.postColumnOther?.nilIfBlank ?? material.displayName
        }
        return material.displayName
    }

    private static func resolvedTrimMaterial(_ attachment: AttachmentConditions?) -> String {
        guard attachment?.trimPresent == true else { return "Not applicable" }
        guard let material = attachment?.trimMaterial else { return "Not set" }
        if material == .other {
            return attachment?.trimMaterialOther?.nilIfBlank ?? material.displayName
        }
        return material.displayName
    }

    private static func resolvedTrimThickness(_ attachment: AttachmentConditions?) -> String {
        guard attachment?.trimPresent == true else { return "Not applicable" }
        guard let thickness = attachment?.trimThickness else { return "Not set" }
        if thickness == .custom {
            return formatNumber(attachment?.trimThicknessCustom, suffix: "in")
        }
        return thickness.displayName
    }

    private static func kneeWallSummary(_ kneeWall: KneeWall?) -> String {
        guard let kneeWall else { return "Not set" }
        var parts: [String] = []
        if let height = kneeWall.panelHeight {
            parts.append(formatNumber(height, suffix: "ft"))
        }
        if let color = kneeWall.panelColor?.nilIfBlank {
            parts.append(color)
        }
        if let trimColor = kneeWall.trimColor?.nilIfBlank {
            parts.append("Trim \(trimColor)")
        }
        if let finish = kneeWall.interiorFinish?.nilIfBlank {
            parts.append(finish)
        }
        return parts.isEmpty ? "No additional details" : parts.joined(separator: ", ")
    }

    private static func photoChecklistSummary(_ checklist: PhotoChecklist?) -> String {
        guard let checklist else { return "Not set" }
        var selected: [String] = []
        if checklist.frontOfHouse == true { selected.append("Front") }
        if checklist.rearElevation == true { selected.append("Rear") }
        if checklist.roofLine == true { selected.append("Roof") }
        if checklist.electricalPanel == true { selected.append("Panel") }
        if checklist.workArea == true { selected.append("Work Area") }
        return selected.isEmpty ? "No items selected" : selected.joined(separator: ", ")
    }
}

private struct PDFRow {
    let label: String
    let value: String
}

private struct PDFSection {
    let title: String
    let rows: [PDFRow]
    var image: UIImage? = nil
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
