import SwiftUI
import PDFKit
import UIKit
import OSLog
import AVFoundation

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
                        .padding(8)
                        .liquidGlassSurface(cornerRadius: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
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
    private static let logger = Logger(subsystem: "ConstructionScopeApp", category: "PDFExport")
    private static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    private static let pageBackgroundColor = UIColor.white
    private static let primaryTextColor = UIColor.black
    private static let secondaryTextColor = UIColor.darkGray
    private static let separatorColor = UIColor(white: 0.82, alpha: 1)
    private static let bodyFont = UIFont.systemFont(ofSize: 10)
    private static let sectionTitleFont = UIFont.boldSystemFont(ofSize: 12)
    private static let pageTitleFont = UIFont.boldSystemFont(ofSize: 16)
    private static let headerTitleFont = UIFont.boldSystemFont(ofSize: 18)

    enum ExportError: LocalizedError {
        case renderFailed
        case contentRenderFailed(String)

        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "The PDF could not be generated."
            case .contentRenderFailed(let details):
                return details
            }
        }
    }

    static func generate(scope: JobScope) throws -> PDFExportResult {
        pruneInactiveExistingConditionsValuesForExport(scope)
        pruneInactiveStructuralValuesForExport(scope)
        pruneInactiveEnclosureValuesForExport(scope)
        let render = try render(scope: scope)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(render.filename)
            .appendingPathExtension("pdf")

        try render.data.write(to: outputURL, options: .atomic)
        logger.info("share-ready PDF written scope=\(scope.id.uuidString, privacy: .public) file=\(outputURL.lastPathComponent, privacy: .public) bytes=\(render.data.count) missingFields=\(render.missingFields.count)")
        return PDFExportResult(fileURL: outputURL, missingFields: render.missingFields)
    }

    static func render(scope: JobScope) throws -> (data: Data, missingFields: [String], filename: String) {
        let missing = missingRequiredFields(for: scope)
        let filename = makeFilename(for: scope)
        let layout = PDFPageLayout(pageRect: pageRect)
        let preparedPages = try plannedPages(for: scope)
        let renderedPages = try paginatePages(preparedPages, layout: layout, scopeID: scope.id.uuidString)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let diagnostics = PDFRenderDiagnostics(
            scopeID: scope.id.uuidString,
            filename: filename,
            missingFields: missing,
            plannedPages: preparedPages,
            renderedPages: renderedPages
        )

        logger.info("starting PDF render \(diagnostics.summary, privacy: .public)")

        let data = renderer.pdfData { context in
            for (index, page) in renderedPages.enumerated() {
                context.beginPage()
                let cg = context.cgContext
                fillPageBackground(in: cg, rect: layout.pageRect)
                drawHeader(in: cg, rect: layout.pageRect, scope: scope)
                drawPageContent(in: cg, page: page, layout: layout)
                drawFooter(in: cg, rect: layout.pageRect, pageNumber: index + 1, totalPages: renderedPages.count)
            }
        }

        guard !data.isEmpty else {
            logger.error("PDF render produced empty data scope=\(scope.id.uuidString, privacy: .public)")
            throw ExportError.renderFailed
        }

        let actualPageCount = PDFDocument(data: data)?.pageCount ?? renderedPages.count
        logger.info("completed PDF render scope=\(scope.id.uuidString, privacy: .public) actualPages=\(actualPageCount) renderedPages=\(renderedPages.count) appendixPages=\(renderedPages.filter { $0.kind != .core }.count) bytes=\(data.count)")

        return (data: data, missingFields: missing, filename: filename)
    }

    private static func paginatePages(_ pages: [PDFPageContent], layout: PDFPageLayout, scopeID: String) throws -> [PDFRenderedPage] {
        var rendered: [PDFRenderedPage] = []

        for page in pages {
            let paginated = try paginate(page, layout: layout, scopeID: scopeID)
            rendered.append(contentsOf: paginated)
        }

        return rendered
    }

    private static func paginate(_ page: PDFPageContent, layout: PDFPageLayout, scopeID: String) throws -> [PDFRenderedPage] {
        var output: [PDFRenderedPage] = []
        var currentPage = PDFRenderedPage(title: page.title, kind: page.kind, sections: [])
        var remainingHeight = layout.bodyRect.height
        var continuationIndex = 0

        func beginNewPage(reason: String, sectionTitle: String) {
            if !currentPage.sections.isEmpty {
                output.append(currentPage)
                logger.info("page break scope=\(scopeID, privacy: .public) pageTitle=\(page.title, privacy: .public) section=\(sectionTitle, privacy: .public) reason=\(reason, privacy: .public) emittedSections=\(currentPage.sections.count) nextRenderedPage=\(output.count + 1)")
            }
            continuationIndex += 1
            currentPage = PDFRenderedPage(
                title: continuationTitle(for: page.title, continuationIndex: continuationIndex),
                kind: page.kind,
                sections: []
            )
            remainingHeight = layout.bodyRect.height
        }

        for section in page.sections {
            var pendingRows = section.rows
            var pendingImage = section.image
            var sectionContinuation = 0

            while !pendingRows.isEmpty || pendingImage != nil {
                let requiredTitleHeight = layout.sectionTitleHeight + layout.sectionTitleBottomSpacing
                let minimumBodyHeight = minimumContentHeight(for: pendingRows.first, hasImage: pendingImage != nil, imageRole: section.imageRole, layout: layout)

                if remainingHeight < requiredTitleHeight + minimumBodyHeight {
                    if currentPage.sections.isEmpty {
                        logger.error("insufficient fresh-page space scope=\(scopeID, privacy: .public) pageTitle=\(page.title, privacy: .public) section=\(section.title, privacy: .public) remainingHeight=\(remainingHeight)")
                        throw ExportError.contentRenderFailed("The PDF could not render section '\(section.title)' on '\(page.title)' because the content does not fit on a fresh page.")
                    } else {
                        beginNewPage(reason: "section-start-overflow", sectionTitle: section.title)
                    }
                }

                let renderedSectionTitle = sectionContinuation == 0 ? section.title : "\(section.title) (Cont.)"
                var renderedSection = PDFRenderedSection(title: renderedSectionTitle, rows: [], image: nil)
                remainingHeight -= requiredTitleHeight
                var placedContent = false

                while !pendingRows.isEmpty {
                    let row = pendingRows.removeFirst()
                    let placement = fitRow(row, availableHeight: remainingHeight, layout: layout)

                    guard let placement else {
                        pendingRows.insert(row, at: 0)
                        break
                    }

                    renderedSection.rows.append(placement.row)
                    remainingHeight -= placement.row.height
                    placedContent = true

                    if let remainder = placement.remainder {
                        pendingRows.insert(remainder, at: 0)
                        logger.info("row split scope=\(scopeID, privacy: .public) pageTitle=\(page.title, privacy: .public) section=\(section.title, privacy: .public) label=\(row.label, privacy: .public)")
                        break
                    }
                }

                if let image = pendingImage {
                    if let renderedImage = fitImage(image, role: section.imageRole, availableHeight: remainingHeight, layout: layout) {
                        renderedSection.image = renderedImage
                        remainingHeight -= renderedImage.totalHeight
                        pendingImage = nil
                        placedContent = true
                    } else if placedContent || !currentPage.sections.isEmpty {
                        logger.info("page break scope=\(scopeID, privacy: .public) pageTitle=\(page.title, privacy: .public) section=\(section.title, privacy: .public) reason=image-overflow emittedSections=\(currentPage.sections.count + 1) nextRenderedPage=\(output.count + 1)")
                    } else {
                        logger.error("skipped image placement scope=\(scopeID, privacy: .public) pageTitle=\(page.title, privacy: .public) section=\(section.title, privacy: .public) reason=no-usable-space")
                        throw ExportError.contentRenderFailed("The PDF could not render the image in section '\(section.title)' on '\(page.title)'.")
                    }
                }

                if placedContent {
                    currentPage.sections.append(renderedSection)
                    remainingHeight -= layout.sectionBottomSpacing
                } else {
                    remainingHeight += requiredTitleHeight
                }

                if !pendingRows.isEmpty || pendingImage != nil {
                    if currentPage.sections.isEmpty {
                        logger.error("failed to place section content scope=\(scopeID, privacy: .public) pageTitle=\(page.title, privacy: .public) section=\(section.title, privacy: .public)")
                        throw ExportError.contentRenderFailed("The PDF could not render all content for section '\(section.title)' on '\(page.title)'.")
                    }

                    sectionContinuation += 1
                    beginNewPage(reason: pendingImage != nil ? "continued-image" : "continued-rows", sectionTitle: section.title)
                }
            }
        }

        if !currentPage.sections.isEmpty {
            output.append(currentPage)
        }

        return output
    }

    private static func minimumContentHeight(for row: PDFRow?, hasImage: Bool, imageRole: PDFImageRole, layout: PDFPageLayout) -> CGFloat {
        if row != nil {
            return layout.minimumRowHeight
        }

        if hasImage {
            return imageRole.minimumHeight + layout.imageTopSpacing + layout.imageBottomSpacing
        }

        return layout.minimumRowHeight
    }

    private static func continuationTitle(for title: String, continuationIndex: Int) -> String {
        continuationIndex == 0 ? title : "\(title) (Cont. \(continuationIndex))"
    }

    private static func fitRow(_ row: PDFRow, availableHeight: CGFloat, layout: PDFPageLayout) -> PDFRowPlacement? {
        guard availableHeight >= layout.minimumRowHeight else { return nil }

        let fullHeight = rowHeight(for: row.value, layout: layout)
        if fullHeight <= availableHeight {
            return PDFRowPlacement(
                row: PDFRenderedRow(label: row.label, value: row.value, height: fullHeight),
                remainder: nil
            )
        }

        let chunk = fittingTextChunk(row.value, width: layout.valueColumnWidth, maxHeight: availableHeight, font: bodyFont)
        guard let chunk, !chunk.prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let chunkHeight = rowHeight(for: chunk.prefix, layout: layout)
        let remainder = chunk.remainder?.nilIfBlank.map {
            PDFRow(label: "\(row.label) (cont.)", value: $0)
        }

        return PDFRowPlacement(
            row: PDFRenderedRow(label: row.label, value: chunk.prefix, height: chunkHeight),
            remainder: remainder
        )
    }

    private static func fittingTextChunk(_ text: String, width: CGFloat, maxHeight: CGFloat, font: UIFont) -> TextChunk? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if heightForText(trimmed, font: font, width: width) <= maxHeight {
            return TextChunk(prefix: trimmed, remainder: nil)
        }

        let nsText = trimmed as NSString
        var low = 1
        var high = nsText.length
        var best = 0

        while low <= high {
            let mid = (low + high) / 2
            let candidate = nsText.substring(to: mid)
            let candidateHeight = heightForText(candidate, font: font, width: width)

            if candidateHeight <= maxHeight {
                best = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        guard best > 0 else { return nil }

        let splitIndex = preferredBreakIndex(in: nsText, upperBound: best)
        let prefix = nsText.substring(to: splitIndex).trimmingCharacters(in: .whitespacesAndNewlines)
        let remainder = nsText.substring(from: splitIndex).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !prefix.isEmpty else { return nil }
        return TextChunk(prefix: prefix, remainder: remainder.isEmpty ? nil : remainder)
    }

    private static func preferredBreakIndex(in text: NSString, upperBound: Int) -> Int {
        guard upperBound < text.length else { return text.length }
        let searchLength = min(upperBound, 32)
        let searchRange = NSRange(location: upperBound - searchLength, length: searchLength)
        let whitespaceRange = text.rangeOfCharacter(
            from: .whitespacesAndNewlines,
            options: .backwards,
            range: searchRange
        )

        if whitespaceRange.location != NSNotFound, whitespaceRange.location > 0 {
            return whitespaceRange.location
        }

        return upperBound
    }

    private static func fitImage(_ image: UIImage, role: PDFImageRole, availableHeight: CGFloat, layout: PDFPageLayout) -> PDFRenderedImage? {
        guard image.size.width > 0, image.size.height > 0 else {
            return nil
        }

        let verticalBudget = availableHeight - layout.imageTopSpacing - layout.imageBottomSpacing
        guard verticalBudget >= role.minimumHeight else {
            return nil
        }

        let boundingRect = CGRect(
            x: 0,
            y: 0,
            width: min(role.maximumWidth(for: layout), layout.bodyRect.width),
            height: min(role.maximumHeight, verticalBudget)
        )

        let fittedRect = AVMakeRect(aspectRatio: image.size, insideRect: boundingRect)
        guard fittedRect.width >= role.minimumWidth, fittedRect.height >= role.minimumHeight else {
            return nil
        }

        return PDFRenderedImage(
            image: image,
            role: role,
            size: fittedRect.size,
            totalHeight: layout.imageTopSpacing + fittedRect.height + layout.imageBottomSpacing
        )
    }

    private static func fillPageBackground(in context: CGContext, rect: CGRect) {
        context.saveGState()
        context.setFillColor(pageBackgroundColor.cgColor)
        context.fill(rect)
        context.restoreGState()
    }

    private static func drawHeader(in context: CGContext, rect: CGRect, scope: JobScope) {
        let title = scope.resolvedDocumentTitle
        let customerName = scope.resolvedExportCustomerName ?? "Not set"
        let address = scope.projectInfo.formattedAddressLine ?? "No address"
        let type = scope.projectInfo.projectType.displayName
        let jobNumber = scope.jobNumber ?? "N/A"

        drawAdaptiveText(title, font: headerTitleFont, in: CGRect(x: 40, y: 34, width: rect.width - 80, height: 22), context: context, color: primaryTextColor, minimumScaleFactor: 0.72, logContext: "header-title")
        drawAdaptiveText("Customer: \(customerName)", font: .systemFont(ofSize: 11), in: CGRect(x: 40, y: 58, width: rect.width - 80, height: 16), context: context, color: secondaryTextColor, minimumScaleFactor: 0.76, logContext: "header-customer")
        drawAdaptiveText(address, font: .systemFont(ofSize: 11), in: CGRect(x: 40, y: 72, width: rect.width - 80, height: 16), context: context, color: secondaryTextColor, minimumScaleFactor: 0.76, logContext: "header-address")
        drawAdaptiveText("Project Type: \(type)", font: .systemFont(ofSize: 10), in: CGRect(x: 40, y: 88, width: 260, height: 14), context: context, color: secondaryTextColor, minimumScaleFactor: 0.8, logContext: "header-project-type")
        drawAdaptiveText("Job #: \(jobNumber)", font: .systemFont(ofSize: 10), in: CGRect(x: rect.width - 180, y: 88, width: 140, height: 14), context: context, alignment: .right, color: secondaryTextColor, minimumScaleFactor: 0.8, logContext: "header-job-number")

        context.setStrokeColor(separatorColor.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: 108))
        context.addLine(to: CGPoint(x: rect.width - 40, y: 108))
        context.strokePath()
    }

    private static func drawFooter(in context: CGContext, rect: CGRect, pageNumber: Int, totalPages: Int) {
        let dateText = "Generated: \(Date.now.formatted(date: .abbreviated, time: .shortened))"
        drawAdaptiveText(dateText, font: .systemFont(ofSize: 9), in: CGRect(x: 40, y: rect.height - 32, width: 260, height: 12), context: context, color: secondaryTextColor, minimumScaleFactor: 0.84, logContext: "footer-generated-date")
        drawAdaptiveText("Page \(pageNumber) of \(totalPages)", font: .systemFont(ofSize: 9), in: CGRect(x: rect.width - 160, y: rect.height - 32, width: 120, height: 12), context: context, alignment: .right, color: secondaryTextColor, minimumScaleFactor: 0.84, logContext: "footer-page-count")
    }

    private static func drawPageContent(in context: CGContext, page: PDFRenderedPage, layout: PDFPageLayout) {
        drawAdaptiveText(page.title, font: pageTitleFont, in: layout.pageTitleRect, context: context, color: primaryTextColor, minimumScaleFactor: 0.76, logContext: "page-title")

        var y = layout.bodyRect.minY
        for section in page.sections {
            drawText(section.title, font: sectionTitleFont, in: CGRect(x: layout.bodyRect.minX, y: y, width: layout.bodyRect.width, height: layout.sectionTitleHeight), context: context, color: primaryTextColor)
            y += layout.sectionTitleHeight + layout.sectionTitleBottomSpacing

            for row in section.rows {
                let labelRect = CGRect(x: layout.labelColumnX, y: y, width: layout.labelColumnWidth, height: row.height)
                let valueRect = CGRect(x: layout.valueColumnX, y: y, width: layout.valueColumnWidth, height: row.height)
                drawText(row.label, font: bodyFont, in: labelRect, context: context, color: primaryTextColor)
                drawText(row.value, font: bodyFont, in: valueRect, context: context, color: primaryTextColor)
                y += row.height
            }

            if let image = section.image {
                y += layout.imageTopSpacing
                let imageRect = image.role.drawRect(for: image.size, layout: layout, y: y)
                image.image.draw(in: imageRect)
                y += image.size.height + layout.imageBottomSpacing
            }

            y += layout.sectionBottomSpacing
        }
    }

    private static func rowHeight(for value: String, layout: PDFPageLayout) -> CGFloat {
        max(layout.minimumRowHeight, heightForText(value, font: bodyFont, width: layout.valueColumnWidth) + layout.rowBottomSpacing)
    }

    private static func pageOne(_ scope: JobScope) -> PDFPageContent {
        let project = scope.projectInfo
        let dims = scope.dimensions

        return PDFPageContent(
            title: "Page 1: Job Header + Project Info + Key Dimensions",
            sections: [
                PDFSection(title: "Project Information", rows: [
                    .init(label: "Scope Title", value: scope.resolvedScopeTitle ?? "Not set"),
                    .init(label: "Customer", value: scope.resolvedExportCustomerName ?? "Not set"),
                    .init(label: "Address", value: project.address.nilIfBlank ?? "Not set"),
                    .init(label: "Unit Number", value: project.unitNumber?.nilIfBlank ?? "Not set"),
                    .init(label: "City / State / ZIP", value: combinedValue(project.city, project.state, project.zip)),
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
            ],
            kind: .core
        )
    }

    private static func pageTwo(_ scope: JobScope) -> PDFPageContent {
        let existing = scope.existingConditions?.normalizedForExport()
        let attachment = scope.attachment

        return PDFPageContent(
            title: "Page 2: Existing Conditions + Attachment Conditions",
            sections: [
                PDFSection(title: "Existing Conditions", rows: [
                    .init(label: "House Stories", value: existing?.houseStories?.displayName ?? "Not set"),
                    .init(label: "Exterior Finish", value: existing?.exteriorFinish?.displaySummary ?? "Not set"),
                    .init(label: "Posts/Columns Material", value: existing?.exteriorFinish?.postsColumnsMaterialDisplaySummary ?? "Not set"),
                    .init(label: "Post Trim", value: boolString(existing?.exteriorFinish?.postTrim)),
                    .init(label: "Trim Thickness", value: existing?.exteriorFinish?.trimThickness?.nilIfBlank ?? "Not set"),
                    .init(label: "Exterior House Wall Material", value: existing?.exteriorFinish?.exteriorHouseWallMaterialDisplaySummary ?? "Not set"),
                    .init(label: "Exterior House Wall -> Other", value: existing?.exteriorFinish?.exteriorHouseWallOther?.nilIfBlank ?? "Not set"),
                    .init(label: "Existing Structure", value: existing?.existingStructureDisplaySummary ?? "Not set"),
                    .init(label: "Obstacles", value: existing?.obstaclesNotes?.nilIfBlank ?? "None"),
                    .init(label: "Utilities", value: existing?.utilitiesNotes?.nilIfBlank ?? "None"),
                    .init(label: "HOA Notes", value: existing?.hoaNotes?.nilIfBlank ?? "None"),
                    .init(label: "Photo Checklist", value: photoChecklistSummary(scopeID: scope.id))
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
            ],
            kind: .core
        )
    }

    private static func pageThree(_ scope: JobScope) -> PDFPageContent {
        let structural = scope.structuralSystem?.normalizedForExport()
        let enclosure = scope.enclosure?.normalizedForExport()

        return PDFPageContent(
            title: "Page 3: Structural + Roof System + Enclosure",
            sections: [
                PDFSection(title: "Structural System", rows: structuralRows(structural)),
                PDFSection(title: "Enclosure", rows: [
                    .init(label: "Type", value: enclosure?.enclosureTypeDisplaySummary ?? "Not set"),
                    .init(label: "Screen Type", value: enclosure?.screenWallType?.displayName ?? "Not set"),
                    .init(label: "Tint", value: enclosure?.screenTint?.displayName ?? "Not set"),
                    .init(label: "Frame Size", value: enclosure?.screenFrameSize?.displayName ?? "Not set"),
                    .init(label: "Frame Color", value: resolvedScreenFrameColor(enclosure?.screenFrameColor, custom: enclosure?.screenFrameColorCustom)),
                    .init(label: "Knee Wall", value: enclosure?.kneeWall?.option?.displayName ?? "Not set"),
                    .init(label: "Knee Wall Details", value: kneeWallSummary(enclosure?.kneeWall)),
                    .init(label: "Door Type", value: enclosure?.doors?.doorType?.displayName ?? "Not set"),
                    .init(label: "Door Style", value: enclosure?.doors?.style?.displayName ?? "Not set"),
                    .init(label: "Operable Side", value: enclosure?.doors?.operableSide?.displayName ?? "Not set"),
                    .init(label: "Hinge Side", value: enclosure?.doors?.hingeSide?.displayName ?? "Not set"),
                    .init(label: "Door Dimensions", value: combinedValue(enclosure?.doors?.width?.nilIfBlank, enclosure?.doors?.height?.nilIfBlank)),
                    .init(label: "Sliding Door Color", value: enclosure?.doors?.color?.nilIfBlank ?? "Not set"),
                    .init(label: "Sliding Door Dimensions", value: enclosure?.doors?.dimensions?.nilIfBlank ?? "Not set"),
                    .init(label: "Door Notes", value: enclosure?.doors?.notes?.nilIfBlank ?? "None")
                ])
            ],
            kind: .core
        )
    }

    private static func pageFour(_ scope: JobScope) -> PDFPageContent {
        let window = scope.enclosure?.normalizedForExport()?.windowSystem
        let electrical = scope.electrical
        let drainage = scope.drainage

        return PDFPageContent(
            title: "Page 4: Windows/Glass + Knee Wall + Electrical + Drainage",
            sections: [
                PDFSection(title: "Windows & Glass", rows: [
                    .init(label: "Window Type", value: window?.windowType?.displayName ?? "Not set"),
                    .init(label: "Frame System", value: window?.frameSystem?.displayName ?? "Not set"),
                    .init(label: "Glass Type", value: window?.glassType?.displayName ?? "Not set"),
                    .init(label: "Safety", value: window?.glassSafety?.displayName ?? "Not set"),
                    .init(label: "Grid", value: window?.gridOption?.displayName ?? "Not set"),
                    .init(label: "Operation", value: window?.operation?.displayName ?? "Not set"),
                    .init(label: "Frame Color", value: resolvedStandardColor(window?.color, custom: window?.colorCustom)),
                    .init(label: "Height / Bays", value: combinedValue(formatOptionalPDFNumber(window?.windowHeight, suffix: "ft"), formatOptionalPDFNumber(window?.numBays, suffix: "bays"))),
                    .init(label: "Configuration", value: window?.configuration?.displayName ?? "Not set"),
                    .init(label: "Notes", value: window?.notes?.nilIfBlank ?? "None")
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
            ],
            kind: .core
        )
    }

    private static func pageFive(_ scope: JobScope) throws -> PDFPageContent {
        let finishes = scope.finishes
        let permits = scope.permitsHOA
        let production = scope.production

        var signatureRows: [PDFRow] = [
            .init(label: "Signed Date", value: scope.customerApproval?.signedDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
        ]

        if let path = scope.customerApproval?.signaturePNGPath {
            let image = try loadImage(at: path, scopeID: scope.id.uuidString, reasonContext: "signature image")
            signatureRows.append(.init(label: "Signature", value: "Embedded"))

            return PDFPageContent(
                title: "Page 5: Permits/HOA + Production Notes + Customer Signature",
                sections: [
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
                    PDFSection(title: "Customer Signature", rows: signatureRows, image: image, imageRole: .signature)
                ],
                kind: .core
            )
        }

        signatureRows.append(.init(label: "Signature", value: "Not captured"))
        return PDFPageContent(
            title: "Page 5: Permits/HOA + Production Notes + Customer Signature",
            sections: [
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
            ],
            kind: .core
        )
    }

    private static func plannedPages(for scope: JobScope) throws -> [PDFPageContent] {
        [
            pageOne(scope),
            pageTwo(scope),
            pageThree(scope),
            pageFour(scope),
            try pageFive(scope)
        ] + (try appendixPages(scope))
    }

    private static func pruneInactiveEnclosureValuesForExport(_ scope: JobScope) {
        scope.enclosure = scope.enclosure?.normalizedForExport()
    }

    private static func pruneInactiveStructuralValuesForExport(_ scope: JobScope) {
        scope.structuralSystem = scope.structuralSystem?.normalizedForExport()
    }

    private static func pruneInactiveExistingConditionsValuesForExport(_ scope: JobScope) {
        scope.existingConditions = scope.existingConditions?.normalizedForExport()
    }

    private static func structuralRows(_ structural: StructuralSystem?) -> [PDFRow] {
        guard let structural else {
            return [
                .init(label: "Structural System", value: "Not set"),
                .init(label: "Notes", value: "None")
            ]
        }

        var rows: [PDFRow] = [
            .init(label: "Structural System", value: structural.resolvedSelectionDisplayName ?? "Not set")
        ]

        if let pergolaType = structural.pergolaType?.displayName {
            rows.append(.init(label: "Pergola Type", value: pergolaType))
        }

        switch structural.systemType {
        case .some(.insulatedAluminumPatioCover):
            rows.append(.init(label: "Width", value: structural.insulatedAluminumPatioCover?.width?.nilIfBlank ?? "Not set"))
            rows.append(.init(label: "Projection", value: structural.insulatedAluminumPatioCover?.projection?.nilIfBlank ?? "Not set"))
            rows.append(.init(label: "Number of Posts", value: structural.insulatedAluminumPatioCover?.numberOfPosts?.nilIfBlank ?? "Not set"))
            rows.append(.init(label: "Roof Type", value: structural.insulatedAluminumPatioCover?.roofType?.displayName ?? "Not set"))
        case .some(.pergola):
            switch structural.pergolaType {
            case .some(.motorizedLouveredPergola):
                rows.append(contentsOf: pergolaDimensionRows(structural.motorizedLouveredPergola))
            case .some(.manuallyRetractableLouveredPergola):
                rows.append(contentsOf: pergolaDimensionRows(structural.manuallyRetractableLouveredPergola))
            case .some(.cedarPergola):
                rows.append(.init(label: "Post Size", value: structural.cedarPergola?.resolvedPostSize ?? "Not set"))
                rows.append(.init(label: "Beam Size", value: structural.cedarPergola?.resolvedBeamSize ?? "Not set"))
                rows.append(.init(label: "Rafter Size", value: structural.cedarPergola?.resolvedRafterSize ?? "Not set"))
                rows.append(.init(label: "Lattice", value: structural.cedarPergola?.lattice?.displayName ?? "Not set"))
                rows.append(.init(label: "Hardware", value: structural.cedarPergola?.hardware?.displayName ?? "Not set"))
                rows.append(.init(label: "Finish", value: structural.cedarPergola?.finish?.displayName ?? "Not set"))
                rows.append(.init(label: "Product Code", value: structural.cedarPergola?.productCode?.nilIfBlank ?? "Not set"))
            case .some(.alumawoodPergola):
                rows.append(.init(label: "Mount Type", value: structural.alumawoodPergola?.mountType?.displayName ?? "Not set"))
                rows.append(.init(label: "Layout", value: structural.alumawoodPergola?.layoutSummary ?? "Not set"))
                rows.append(.init(label: "Attachment Type", value: structural.alumawoodPergola?.attachmentType?.displayName ?? "Not set"))
                rows.append(.init(label: "Color", value: structural.alumawoodPergola?.color?.displayName ?? "Not set"))
                rows.append(.init(label: "Privacy Wall", value: boolString(structural.alumawoodPergola?.privacyWall)))
            case .none:
                break
            }
        case .some(.other), .some(StructuralSystemType.none), nil:
            break
        }

        if structural.systemType == nil, let legacySummary = structural.legacyFlatSummary {
            rows.append(.init(label: "Legacy Structural Summary", value: legacySummary))
        }

        if let pergolaNotes = structural.resolvedPergolaNotes {
            rows.append(.init(label: "Pergola Notes", value: pergolaNotes))
        }

        rows.append(.init(label: "Notes", value: structural.notes?.nilIfBlank ?? "None"))
        return rows
    }

    private static func pergolaDimensionRows(_ details: PergolaDimensionDetails?) -> [PDFRow] {
        [
            .init(label: "Width", value: details?.width?.nilIfBlank ?? "Not set"),
            .init(label: "Length", value: details?.length?.nilIfBlank ?? "Not set"),
            .init(label: "Height", value: details?.height?.nilIfBlank ?? "Not set")
        ]
    }

    private static func appendixPages(_ scope: JobScope) throws -> [PDFPageContent] {
        var pages = try checklistPhotoAppendixPages(scope)

        if let photos = scope.photos, !photos.isEmpty {
            for (index, photo) in photos.enumerated() {
                let image = try loadImage(at: photo.imagePath, scopeID: scope.id.uuidString, reasonContext: "photo appendix \(index + 1)")

                pages.append(
                    PDFPageContent(
                        title: "Appendix: Photo \(index + 1)",
                        sections: [PDFSection(title: photo.caption?.nilIfBlank ?? "Scope Photo \(index + 1)", rows: [
                            .init(label: "Captured", value: photo.createdAt.formatted(date: .abbreviated, time: .shortened)),
                            .init(label: "Caption", value: photo.caption?.nilIfBlank ?? "None")
                        ], image: image, imageRole: .appendix)],
                        kind: .photoAppendix
                    )
                )
            }
        }

        if let diagram = scope.sketches?.first(where: { $0.title == "Site Diagram" }) {
            let image = try loadImage(at: diagram.previewPNGPath, scopeID: scope.id.uuidString, reasonContext: "site diagram appendix")
            pages.append(
                PDFPageContent(
                    title: "Appendix: Site Diagram",
                    sections: [PDFSection(title: "Site Diagram", rows: [
                        .init(label: "Captured", value: diagram.createdAt.formatted(date: .abbreviated, time: .shortened))
                    ], image: image, imageRole: .appendix)],
                    kind: .siteDiagramAppendix
                )
            )
        }

        return pages
    }

    private static func checklistPhotoAppendixPages(_ scope: JobScope) throws -> [PDFPageContent] {
        let categorizedPhotos = ChecklistPhotoAssetStore.categorizedPhotos(scopeID: scope.id)
        guard !categorizedPhotos.isEmpty else {
            return []
        }

        let sections = try categorizedPhotos.flatMap { category, photos in
            try checklistPhotoSections(
                category: category,
                photos: photos,
                scopeID: scope.id.uuidString
            )
        }

        guard !sections.isEmpty else { return [] }

        return sections.chunked(into: 2).enumerated().map { index, pageSections in
            PDFPageContent(
                title: index == 0
                    ? "Appendix: Existing Conditions Photos"
                    : "Appendix: Existing Conditions Photos \(index + 1)",
                sections: pageSections,
                kind: .photoAppendix
            )
        }
    }

    private static func checklistPhotoSections(
        category: PhotoChecklistCategory,
        photos: [DocumentAttachmentFile],
        scopeID: String
    ) throws -> [PDFSection] {
        let chunks = photos.chunked(into: 4)

        return try chunks.enumerated().map { chunkIndex, chunk in
            let images = try chunk.enumerated().map { imageIndex, photo in
                try loadImage(
                    at: photo.filePath,
                    scopeID: scopeID,
                    reasonContext: "existing conditions \(category.displayName) photo \(chunkIndex * 4 + imageIndex + 1)"
                )
            }

            let visibleRange = (chunkIndex * 4 + 1)...(chunkIndex * 4 + chunk.count)
            let title = chunks.count == 1
                ? category.displayName
                : "\(category.displayName) (\(visibleRange.lowerBound)-\(visibleRange.upperBound) of \(photos.count))"

            return PDFSection(
                title: title,
                rows: [
                    .init(label: "Total Photos", value: "\(photos.count)"),
                    .init(label: "Shown", value: "\(chunk.count) on this page")
                ],
                image: buildChecklistCompositeImage(images),
                imageRole: .appendix
            )
        }
    }

    private static func buildChecklistCompositeImage(_ images: [UIImage]) -> UIImage {
        let columnCount = min(2, max(1, images.count))
        let rowCount = Int(ceil(Double(images.count) / Double(columnCount)))
        let canvasSize = CGSize(width: 900, height: rowCount == 1 ? 320 : 520)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let backgroundColor = UIColor(white: 0.97, alpha: 1)
        let borderColor = UIColor(white: 0.86, alpha: 1)
        let gap: CGFloat = 18
        let padding: CGFloat = 24
        let contentWidth = canvasSize.width - (padding * 2)
        let contentHeight = canvasSize.height - (padding * 2)
        let cellWidth = (contentWidth - CGFloat(columnCount - 1) * gap) / CGFloat(columnCount)
        let cellHeight = (contentHeight - CGFloat(max(0, rowCount - 1)) * gap) / CGFloat(max(rowCount, 1))

        return renderer.image { context in
            let cg = context.cgContext
            backgroundColor.setFill()
            cg.fill(CGRect(origin: .zero, size: canvasSize))

            for (index, image) in images.enumerated() {
                let row = index / columnCount
                let column = index % columnCount
                let rect = CGRect(
                    x: padding + CGFloat(column) * (cellWidth + gap),
                    y: padding + CGFloat(row) * (cellHeight + gap),
                    width: cellWidth,
                    height: cellHeight
                )

                let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 18)
                cg.saveGState()
                roundedRect.addClip()
                drawAspectFill(image, in: rect)
                cg.restoreGState()

                borderColor.setStroke()
                roundedRect.lineWidth = 1
                roundedRect.stroke()
            }
        }
    }

    private static func loadImage(at path: String, scopeID: String, reasonContext: String) throws -> UIImage {
        guard let image = UIImage(contentsOfFile: path) else {
            logger.error("skipped image scope=\(scopeID, privacy: .public) context=\(reasonContext, privacy: .public) reason=missing-or-unreadable path=\(path, privacy: .private)")
            throw ExportError.contentRenderFailed("The PDF could not include the required \(reasonContext).")
        }

        guard image.size.width > 0, image.size.height > 0 else {
            logger.error("skipped image scope=\(scopeID, privacy: .public) context=\(reasonContext, privacy: .public) reason=invalid-size path=\(path, privacy: .private)")
            throw ExportError.contentRenderFailed("The PDF could not include the required \(reasonContext) because the image is invalid.")
        }

        return image
    }

    private static func missingRequiredFields(for scope: JobScope) -> [String] {
        var missing: [String] = []
        if scope.resolvedExportCustomerName == nil { missing.append("Project Info: Customer Name") }
        if scope.projectInfo.address.nilIfBlank == nil { missing.append("Project Info: Address") }
        return missing
    }

    private static func makeFilename(for scope: JobScope) -> String {
        let identity = scope.resolvedExportIdentityToken.replacingOccurrences(of: " ", with: "")
        let address = (scope.projectInfo.address.nilIfBlank ?? "Address")
            .replacingOccurrences(of: " ", with: "")
        let projectType = scope.projectInfo.projectType.displayName.replacingOccurrences(of: " ", with: "")
        return "\(sanitize(identity))-\(sanitize(address))-\(sanitize(projectType))-Scope"
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "", options: .regularExpression)
    }

    private static func drawText(
        _ text: String,
        font: UIFont,
        in rect: CGRect,
        context: CGContext,
        alignment: NSTextAlignment = .left,
        color: UIColor = primaryTextColor
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]

        NSAttributedString(string: text, attributes: attributes).draw(with: rect, options: [.usesLineFragmentOrigin], context: nil)
    }

    private static func drawAdaptiveText(
        _ text: String,
        font: UIFont,
        in rect: CGRect,
        context: CGContext,
        alignment: NSTextAlignment = .left,
        color: UIColor = primaryTextColor,
        minimumScaleFactor: CGFloat = 0.8,
        logContext: String
    ) {
        let fitted = fittedText(text, font: font, width: rect.width, height: rect.height, minimumScaleFactor: minimumScaleFactor)
        if fitted.scaled || fitted.truncated {
            logger.notice("adjusted PDF text context=\(logContext, privacy: .public) scaled=\(fitted.scaled) truncated=\(fitted.truncated)")
        }

        drawText(fitted.text, font: fitted.font, in: rect, context: context, alignment: alignment, color: color)
    }

    private static func fittedText(
        _ text: String,
        font: UIFont,
        width: CGFloat,
        height: CGFloat,
        minimumScaleFactor: CGFloat
    ) -> PDFTextFit {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return PDFTextFit(text: text, font: font, scaled: false, truncated: false)
        }

        if heightForText(trimmed, font: font, width: width) <= height {
            return PDFTextFit(text: trimmed, font: font, scaled: false, truncated: false)
        }

        let minimumPointSize = max(6, font.pointSize * minimumScaleFactor)
        var candidatePointSize = font.pointSize

        while candidatePointSize > minimumPointSize {
            candidatePointSize = max(minimumPointSize, candidatePointSize - 0.5)
            let candidateFont = font.withSize(candidatePointSize)
            if heightForText(trimmed, font: candidateFont, width: width) <= height {
                return PDFTextFit(text: trimmed, font: candidateFont, scaled: candidatePointSize < font.pointSize, truncated: false)
            }
        }

        let minimumFont = font.withSize(minimumPointSize)
        if let chunk = fittingTextChunk(trimmed, width: width, maxHeight: height, font: minimumFont) {
            let truncated = truncatedText(chunk.prefix, width: width, maxHeight: height, font: minimumFont)
            return PDFTextFit(text: truncated, font: minimumFont, scaled: minimumPointSize < font.pointSize, truncated: true)
        }

        return PDFTextFit(text: "…", font: minimumFont, scaled: minimumPointSize < font.pointSize, truncated: true)
    }

    private static func truncatedText(_ text: String, width: CGFloat, maxHeight: CGFloat, font: UIFont) -> String {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return "…" }

        while !candidate.isEmpty {
            let display = "\(candidate)…"
            if heightForText(display, font: font, width: width) <= maxHeight {
                return display
            }

            candidate.removeLast()
            candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return "…"
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

    private static func combinedValue(_ values: String?...) -> String {
        let values = values.compactMap { $0?.nilIfBlank }
        return values.isEmpty ? "Not set" : values.joined(separator: " / ")
    }

    private static func resolvedStandardColor(_ color: StandardColorOption?, custom: String?) -> String {
        guard let color else { return "Not set" }
        if color == .custom || color == .other {
            return custom?.nilIfBlank ?? color.displayName
        }
        return color.displayName
    }

    private static func resolvedScreenFrameColor(_ color: EnclosureScreenFrameColorOption?, custom: String?) -> String {
        guard let color else { return "Not set" }
        if color == .legacyOther {
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
        if thickness == .custom || thickness == .other {
            return formatNumber(attachment?.trimThicknessCustom, suffix: "in")
        }
        return thickness.displayName
    }

    private static func kneeWallSummary(_ kneeWall: KneeWall?) -> String {
        guard let kneeWall else { return "Not set" }
        var parts: [String] = []
        if let height = kneeWall.panelHeight {
            parts.append("Panel Height \(height.displayName)")
        }
        if let color = kneeWall.panelColor?.nilIfBlank {
            parts.append("Panel Color \(color)")
        }
        if let linearFootage = kneeWall.linearFootage?.nilIfBlank {
            parts.append("Linear Footage \(linearFootage)")
        }
        if let height = kneeWall.height?.nilIfBlank {
            parts.append("Height \(height)")
        }
        if let interior = kneeWall.interiorFinishColor {
            parts.append("Interior \(interior.displayName)")
        }
        if let exterior = kneeWall.exteriorFinishColor {
            parts.append("Exterior \(exterior.displayName)")
        }
        if let framing = kneeWall.framing {
            parts.append("Framing \(framing.displayName)")
        }
        return parts.isEmpty ? "No additional details" : parts.joined(separator: ", ")
    }

    private static func photoChecklistSummary(scopeID: UUID) -> String {
        ChecklistPhotoAssetStore.summary(scopeID: scopeID) ?? "No checklist photos attached"
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        guard image.size.width > 0, image.size.height > 0 else { return }

        let widthScale = rect.width / image.size.width
        let heightScale = rect.height / image.size.height
        let scale = max(widthScale, heightScale)
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(
            x: rect.midX - (scaledSize.width / 2),
            y: rect.midY - (scaledSize.height / 2),
            width: scaledSize.width,
            height: scaledSize.height
        )

        image.draw(in: drawRect)
    }
}

private struct PDFPageLayout {
    let pageRect: CGRect
    let pageTitleRect: CGRect
    let bodyRect: CGRect
    let labelColumnX: CGFloat
    let labelColumnWidth: CGFloat
    let valueColumnX: CGFloat
    let valueColumnWidth: CGFloat
    let sectionTitleHeight: CGFloat = 16
    let sectionTitleBottomSpacing: CGFloat = 2
    let sectionBottomSpacing: CGFloat = 10
    let rowBottomSpacing: CGFloat = 4
    let imageTopSpacing: CGFloat = 4
    let imageBottomSpacing: CGFloat = 10
    let minimumRowHeight: CGFloat = 14

    init(pageRect: CGRect) {
        self.pageRect = pageRect
        self.pageTitleRect = CGRect(x: 40, y: 122, width: pageRect.width - 80, height: 20)
        self.bodyRect = CGRect(x: 40, y: 148, width: pageRect.width - 80, height: 580)
        self.labelColumnX = 48
        self.labelColumnWidth = 150
        self.valueColumnX = 200
        self.valueColumnWidth = pageRect.width - 240
    }
}

private struct PDFPageContent {
    let title: String
    let sections: [PDFSection]
    let kind: PDFPageKind
}

private struct PDFRenderedPage {
    let title: String
    let kind: PDFPageKind
    var sections: [PDFRenderedSection]
}

private struct PDFRenderedSection {
    let title: String
    var rows: [PDFRenderedRow]
    var image: PDFRenderedImage?
}

private struct PDFRenderedRow {
    let label: String
    let value: String
    let height: CGFloat
}

private struct PDFRenderedImage {
    let image: UIImage
    let role: PDFImageRole
    let size: CGSize
    let totalHeight: CGFloat
}

private struct PDFRowPlacement {
    let row: PDFRenderedRow
    let remainder: PDFRow?
}

private struct TextChunk {
    let prefix: String
    let remainder: String?
}

private struct PDFTextFit {
    let text: String
    let font: UIFont
    let scaled: Bool
    let truncated: Bool
}

private enum PDFPageKind {
    case core
    case photoAppendix
    case siteDiagramAppendix
}

private enum PDFImageRole {
    case standard
    case signature
    case appendix

    var minimumWidth: CGFloat {
        switch self {
        case .standard: return 120
        case .signature: return 120
        case .appendix: return 160
        }
    }

    var minimumHeight: CGFloat {
        switch self {
        case .standard: return 80
        case .signature: return 70
        case .appendix: return 120
        }
    }

    var maximumHeight: CGFloat {
        switch self {
        case .standard: return 180
        case .signature: return 120
        case .appendix: return 240
        }
    }

    func maximumWidth(for layout: PDFPageLayout) -> CGFloat {
        switch self {
        case .standard:
            return min(320, layout.bodyRect.width - 12)
        case .signature:
            return 260
        case .appendix:
            return layout.bodyRect.width - 24
        }
    }

    func drawRect(for size: CGSize, layout: PDFPageLayout, y: CGFloat) -> CGRect {
        let originX: CGFloat
        switch self {
        case .signature:
            originX = layout.valueColumnX
        case .standard, .appendix:
            originX = layout.bodyRect.minX + (layout.bodyRect.width - size.width) / 2
        }

        return CGRect(origin: CGPoint(x: originX, y: y), size: size)
    }
}

private struct PDFRenderDiagnostics {
    let scopeID: String
    let filename: String
    let missingFields: [String]
    let plannedPages: [PDFPageContent]
    let renderedPages: [PDFRenderedPage]

    var summary: String {
        let plannedTitles = plannedPages.map(\.title).joined(separator: " | ")
        let renderedTitles = renderedPages.map(\.title).joined(separator: " | ")
        let renderedSectionCounts = renderedPages.map { String($0.sections.count) }.joined(separator: ",")
        let appendixCount = renderedPages.filter { $0.kind != .core }.count

        return "scope=\(scopeID) file=\(filename).pdf plannedPages=\(plannedPages.count) renderedPages=\(renderedPages.count) sectionCounts=[\(renderedSectionCounts)] appendixPages=\(appendixCount) plannedTitles=[\(plannedTitles)] renderedTitles=[\(renderedTitles)] missingFields=\(missingFields.count)"
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
    var imageRole: PDFImageRole = .standard
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return isEmpty ? [] : [self] }

        var result: [[Element]] = []
        var index = startIndex

        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<end]))
            index = end
        }

        return result
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
