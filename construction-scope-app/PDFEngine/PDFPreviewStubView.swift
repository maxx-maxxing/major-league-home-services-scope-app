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
        let composition = try exportComposition(for: scope)
        let preparedPages = composition.pages
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
                drawHeader(in: cg, rect: layout.pageRect, header: composition.header)
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

    private static func drawHeader(in context: CGContext, rect: CGRect, header: PDFHeaderContent) {
        drawAdaptiveText(header.title, font: headerTitleFont, in: CGRect(x: 40, y: 34, width: rect.width - 80, height: 22), context: context, color: primaryTextColor, minimumScaleFactor: 0.72, logContext: "header-title")

        let subtitleLines = [
            header.customerName.map { "Customer: \($0)" },
            header.address
        ].compactMap { $0 }

        for (index, line) in subtitleLines.enumerated() {
            drawAdaptiveText(line, font: .systemFont(ofSize: 11), in: CGRect(x: 40, y: 58 + CGFloat(index * 14), width: rect.width - 80, height: 16), context: context, color: secondaryTextColor, minimumScaleFactor: 0.76, logContext: "header-subtitle-\(index)")
        }

        if let projectType = header.projectType {
            drawAdaptiveText("Project Type: \(projectType)", font: .systemFont(ofSize: 10), in: CGRect(x: 40, y: 88, width: 260, height: 14), context: context, color: secondaryTextColor, minimumScaleFactor: 0.8, logContext: "header-project-type")
        }

        if let jobNumber = header.jobNumber {
            drawAdaptiveText("Job #: \(jobNumber)", font: .systemFont(ofSize: 10), in: CGRect(x: rect.width - 180, y: 88, width: 140, height: 14), context: context, alignment: .right, color: secondaryTextColor, minimumScaleFactor: 0.8, logContext: "header-job-number")
        }

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

    private static func page(
        title: String,
        sections: [PDFSection?],
        kind: PDFPageKind = .core
    ) -> PDFPageContent? {
        let sections = sections.compactMap { $0 }
        guard !sections.isEmpty else { return nil }
        return PDFPageContent(title: title, sections: sections, kind: kind)
    }

    private static func section(
        title: String,
        rows: [PDFRow?] = [],
        additionalRows: [PDFRow] = [],
        image: UIImage? = nil,
        imageRole: PDFImageRole = .standard
    ) -> PDFSection? {
        let resolvedRows = rows.compactMap { $0 } + additionalRows
        guard !resolvedRows.isEmpty || image != nil else { return nil }
        return PDFSection(title: title, rows: resolvedRows, image: image, imageRole: imageRole)
    }

    private static func row(_ label: String, _ value: String?) -> PDFRow? {
        guard let value = meaningfulPDFText(value) else { return nil }
        return PDFRow(label: label, value: value)
    }

    private static func enumRow<Value: SchemaEnumDisplayable>(_ label: String, _ value: Value?) -> PDFRow? {
        row(label, value?.displayName)
    }

    private static func boolRow(_ label: String, _ value: Bool?) -> PDFRow? {
        guard let value else { return nil }
        return PDFRow(label: label, value: value ? "Yes" : "No")
    }

    private static func numberRow(_ label: String, _ value: Double?, suffix: String = "") -> PDFRow? {
        guard value != nil else { return nil }
        return row(label, formatNumber(value, suffix: suffix))
    }

    private static func dateRow(_ label: String, _ value: Date?) -> PDFRow? {
        guard let value else { return nil }
        return PDFRow(label: label, value: value.formatted(date: .abbreviated, time: .omitted))
    }

    private static func meaningfulPDFText(_ value: String?) -> String? {
        guard let value = value?.nilIfBlank else { return nil }
        let defaultValues: Set<String> = [
            "Not set",
            "None",
            "Not applicable",
            "No additional details",
            "No checklist photos attached"
        ]
        return defaultValues.contains(value) ? nil : value
    }

    private static func exportComposition(for scope: JobScope) throws -> PDFExportComposition {
        PDFExportComposition(
            header: headerContent(for: scope),
            pages: try plannedPages(for: scope)
        )
    }

    private static func headerContent(for scope: JobScope) -> PDFHeaderContent {
        PDFHeaderContent(
            title: scope.resolvedDocumentTitle,
            customerName: meaningfulPDFText(scope.resolvedExportCustomerName),
            address: meaningfulPDFText(scope.projectInfo.formattedAddressLine),
            projectType: scope.projectInfo.activeProjectTypes.isEmpty ? nil : meaningfulPDFText(scope.projectInfo.projectTypeDisplaySummary),
            jobNumber: meaningfulPDFText(scope.jobNumber)
        )
    }

    private static func pageOne(_ scope: JobScope) -> PDFPageContent? {
        let project = scope.projectInfo

        return page(
            title: "Job Header + Project Info",
            sections: [
                section(title: "Project Information", rows: [
                    row("Scope Title", scope.resolvedScopeTitle),
                    row("Customer", scope.resolvedExportCustomerName),
                    row("Job Number", scope.jobNumber),
                    row("Address", project.formattedAddressLine),
                    row("City / State / ZIP", combinedValue(project.city, project.state, project.zip)),
                    row("Phone", project.phone),
                    row("Email", project.email),
                    row("Salesperson", project.salesperson),
                    row("Estimator", project.estimator),
                    dateRow("Site Visit", project.siteVisitDate),
                    row("Project Type", project.activeProjectTypes.isEmpty ? nil : project.projectTypeDisplaySummary),
                    row("Notes", project.notes)
                ]),
                section(title: "Dimensions", rows: dimensionRows(scope.dimensions))
            ]
        )
    }

    private static func pageTwo(_ scope: JobScope) -> PDFPageContent? {
        let existing = scope.existingConditions?.normalizedForExport()
        let attachment = scope.attachment

        return page(
            title: "Existing Conditions + Attachment Conditions",
            sections: [
                section(title: "Existing Conditions", rows: [
                    enumRow("House Stories", existing?.houseStories),
                    row("Exterior Finish", existing?.exteriorFinish?.displaySummary),
                    row("Posts/Columns Material", existing?.exteriorFinish?.postsColumnsMaterialDisplaySummary),
                    boolRow("Post Trim", existing?.exteriorFinish?.postTrim),
                    row("Trim Thickness", existing?.exteriorFinish?.trimThickness),
                    row("Exterior House Wall Material", existing?.exteriorFinish?.exteriorHouseWallMaterialDisplaySummary),
                    row("Exterior House Wall -> Other", existing?.exteriorFinish?.exteriorHouseWallOther),
                    row("Existing Structure", existing?.existingStructureDisplaySummary),
                    row("Existing Structure Notes", existing?.existingStructureNotes),
                    row("Obstacles", existing?.obstaclesNotes),
                    row("Utilities", existing?.utilitiesNotes),
                    row("HOA Notes", existing?.hoaNotes),
                    row("Photo Checklist", photoChecklistSummary(scopeID: scope.id))
                ]),
                section(title: "Attachment Conditions", rows: [
                    row("House Material", resolvedHouseWallMaterial(attachment)),
                    enumRow("Mounting Type", attachment?.houseMountingType),
                    enumRow("Mount Condition", attachment?.mountCondition),
                    row("Post Material", resolvedPostMaterial(attachment)),
                    row("Post Size / Spacing", combinedValue(attachment?.postSize, attachment?.postSpacing)),
                    boolRow("Trim Present", attachment?.trimPresent),
                    row("Trim Material", resolvedTrimMaterial(attachment)),
                    row("Trim Thickness", resolvedTrimThickness(attachment)),
                    row("Fastener Plan", attachment?.fastenerPlan?.map(\.displayName).joined(separator: ", ")),
                    row("Notes", attachment?.notes)
                ], additionalRows: measurementRows(attachment?.measurements))
            ]
        )
    }

    private static func pageThree(_ scope: JobScope) -> PDFPageContent? {
        let structural = scope.structuralSystem?.normalizedForExport()
        let enclosure = scope.enclosure?.normalizedForExport()

        return page(
            title: "Structural + Screen Enclosure",
            sections: [
                section(title: "Structural System", additionalRows: structuralRows(structural)),
                section(title: "Screen Enclosure", rows: [
                    row("Screen Enclosure Type", enclosure?.enclosureTypeDisplaySummary),
                    enumRow("Screen Type", enclosure?.screenWallType),
                    enumRow("Tint", enclosure?.screenTint),
                    enumRow("Frame Size", enclosure?.screenFrameSize),
                    row("Frame Color", resolvedScreenFrameColor(enclosure?.screenFrameColor, custom: enclosure?.screenFrameColorCustom)),
                    row("Screen Enclosure Notes", enclosure?.screenEnclosureNotes),
                    enumRow("Knee Wall", enclosure?.kneeWall?.option),
                    row("Knee Wall Details", kneeWallSummary(enclosure?.kneeWall)),
                    enumRow("Door Type", enclosure?.doors?.doorType),
                    enumRow("Door Style", enclosure?.doors?.style),
                    enumRow("Operable Side", enclosure?.doors?.operableSide),
                    enumRow("Hinge Side", enclosure?.doors?.hingeSide),
                    row("Door Dimensions", combinedValue(enclosure?.doors?.width, enclosure?.doors?.height)),
                    row("Sliding Door Color", enclosure?.doors?.color),
                    row("Sliding Door Dimensions", enclosure?.doors?.dimensions),
                    row("Door Notes", enclosure?.doors?.notes)
                ], additionalRows: measurementRows(enclosure?.screenMeasurements))
            ]
        )
    }

    private static func pageFour(_ scope: JobScope) -> PDFPageContent? {
        let enclosure = scope.enclosure?.normalizedForExport()
        let window = enclosure?.windowSystem
        let electrical = scope.electrical
        let drainage = scope.drainage

        return page(
            title: "Sunroom + Electrical + Drainage",
            sections: [
                section(title: "Sunroom", rows: [
                    enumRow("Window Type", window?.windowType),
                    enumRow("Frame System", window?.frameSystem),
                    enumRow("Glass Type", window?.glassType),
                    enumRow("Safety", window?.glassSafety),
                    enumRow("Grid", window?.gridOption),
                    enumRow("Operation", window?.operation),
                    row("Frame Color", resolvedStandardColor(window?.color, custom: window?.colorCustom)),
                    row("Height / Bays", combinedValue(formatOptionalPDFNumber(window?.windowHeight, suffix: "ft"), formatOptionalPDFNumber(window?.numBays, suffix: "bays"))),
                    enumRow("Configuration", window?.configuration),
                    row("Notes", window?.notes)
                ], additionalRows: measurementRows(enclosure?.sunroomMeasurements)),
                section(title: "Electrical", rows: [
                    numberRow("Outlets", electrical?.outletCount),
                    enumRow("Lighting", electrical?.lighting),
                    boolRow("Fan Install", electrical?.fanInstall),
                    row("Switch Locations", electrical?.switchLocations),
                    row("Dedicated Circuits", electrical?.dedicatedCircuits?.map(\.displayName).joined(separator: ", ")),
                    row("Notes", electrical?.notes)
                ], additionalRows: measurementRows(electrical?.measurements)),
                section(title: "Drainage", rows: [
                    boolRow("Gutters", drainage?.gutters),
                    row("Downspouts", drainage?.downspoutLocations),
                    boolRow("Drain Tie-In", drainage?.drainTieIn),
                    row("Drain Notes", drainage?.slopeNotes)
                ], additionalRows: measurementRows(drainage?.measurements))
            ]
        )
    }

    private static func pageFive(_ scope: JobScope) throws -> PDFPageContent? {
        let finishes = scope.finishes
        let permits = scope.permitsHOA
        let production = scope.production

        var signatureRows: [PDFRow?] = [
            dateRow("Signed Date", scope.customerApproval?.signedDate)
        ]
        var signatureImage: UIImage?

        if let path = scope.customerApproval?.signaturePNGPath {
            signatureImage = try loadImage(at: path, scopeID: scope.id.uuidString, reasonContext: "signature image")
            signatureRows.append(PDFRow(label: "Signature", value: "Embedded"))
        }

        return page(
            title: "Finishes + Permits + Production",
            sections: [
                section(title: "Finishes", rows: [
                    row("Trim Type", finishes?.trimType),
                    row("Paint / Powder", finishes?.paintOrPowderColor),
                    boolRow("Siding Replacement", finishes?.sidingReplacementRequired),
                    row("Caulking / Sealing", finishes?.caulkingSealingNotes)
                ], additionalRows: measurementRows(finishes?.measurements)),
                section(title: "Permits / HOA", rows: [
                    boolRow("Permit Required", permits?.permitRequired),
                    boolRow("HOA Required", permits?.hoaApprovalRequired),
                    boolRow("Engineering Required", permits?.engineeringRequired),
                    row("Jurisdiction", permits?.jurisdiction),
                    row("Status Notes", permits?.statusNotes)
                ]),
                section(title: "Production", rows: [
                    row("Crew Lead", production?.crewLead),
                    dateRow("Start Date", production?.startDate),
                    row("Duration", production?.durationEstimate),
                    enumRow("Material Status", production?.materialOrderStatus),
                    enumRow("Permit Status", production?.permitStatus),
                    row("Notes", scope.customerApproval?.optionsConfirmedText)
                ]),
                documentsSection(scope.documents),
                section(title: "Customer Signature", rows: signatureRows, image: signatureImage, imageRole: .signature)
            ]
        )
    }

    private static func plannedPages(for scope: JobScope) throws -> [PDFPageContent] {
        let corePages = [
            pageOne(scope),
            pageTwo(scope),
            pageThree(scope),
            pageFour(scope),
            try pageFive(scope)
        ].compactMap { $0 }

        let pages = corePages + (try appendixPages(scope))
        if !pages.isEmpty {
            return pages
        }

        return [
            PDFPageContent(
                title: "Scope Summary",
                sections: [
                    PDFSection(title: "Project Information", rows: [
                        PDFRow(label: "Status", value: "No relevant scope details have been entered yet.")
                    ])
                ],
                kind: .core
            )
        ]
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

    private static func dimensionRows(_ dimensions: Dimensions?) -> [PDFRow?] {
        [
            numberRow("Width", dimensions?.width, suffix: "ft"),
            numberRow("Projection", dimensions?.projection, suffix: "ft"),
            numberRow("Fascia Height", dimensions?.fasciaHeight, suffix: "ft"),
            numberRow("Beam Height", dimensions?.beamHeight, suffix: "ft"),
            enumRow("Roof Style", dimensions?.roofStyle),
            enumRow("Attachment Type", dimensions?.attachmentType),
            row("Elevation Notes", dimensions?.elevationNotes)
        ]
    }

    private static func documentsSection(_ documents: DocumentsSection?) -> PDFSection? {
        let additionalRows = (documents?.additionalAttachments ?? []).compactMap { attachment -> PDFRow? in
            let displayName = attachment.name?.nilIfBlank ?? attachment.attachment?.originalFilename.nilIfBlank
            return row("Additional Attachment", displayName)
        }

        return section(title: "Documents / Attachments", rows: [
            row("Irrigation", documents?.irrigation?.originalFilename),
            row("Property Survey", documents?.propertySurvey?.originalFilename)
        ], additionalRows: additionalRows)
    }

    private static func structuralRows(_ structural: StructuralSystem?) -> [PDFRow] {
        guard let structural else { return [] }

        var rows: [PDFRow] = [
            row("Structural System", structural.resolvedSelectionDisplayName),
            row("Pergola Type", structural.pergolaType?.displayName)
        ].compactMap { $0 }

        switch structural.systemType {
        case .some(.insulatedAluminumPatioCover):
            rows.append(contentsOf: [
                row("Width", structural.insulatedAluminumPatioCover?.width),
                row("Projection", structural.insulatedAluminumPatioCover?.projection),
                row("Number of Posts", structural.insulatedAluminumPatioCover?.numberOfPosts),
                enumRow("Roof Type", structural.insulatedAluminumPatioCover?.roofType)
            ].compactMap { $0 })
        case .some(.pergola):
            switch structural.pergolaType {
            case .some(.motorizedLouveredPergola):
                rows.append(contentsOf: pergolaDimensionRows(structural.motorizedLouveredPergola))
            case .some(.manuallyRetractableLouveredPergola):
                rows.append(contentsOf: pergolaDimensionRows(structural.manuallyRetractableLouveredPergola))
            case .some(.cedarPergola):
                rows.append(contentsOf: [
                    row("Post Size", structural.cedarPergola?.resolvedPostSize),
                    row("Beam Size", structural.cedarPergola?.resolvedBeamSize),
                    row("Rafter Size", structural.cedarPergola?.resolvedRafterSize),
                    enumRow("Lattice", structural.cedarPergola?.lattice),
                    enumRow("Hardware", structural.cedarPergola?.hardware),
                    enumRow("Finish", structural.cedarPergola?.finish),
                    row("Product Code", structural.cedarPergola?.productCode)
                ].compactMap { $0 })
            case .some(.alumawoodPergola):
                rows.append(contentsOf: [
                    enumRow("Mount Type", structural.alumawoodPergola?.mountType),
                    row("Layout", structural.alumawoodPergola?.layoutSummary),
                    enumRow("Attachment Type", structural.alumawoodPergola?.attachmentType),
                    enumRow("Color", structural.alumawoodPergola?.color),
                    boolRow("Privacy Wall", structural.alumawoodPergola?.privacyWall)
                ].compactMap { $0 })
            case .none:
                break
            }
        case .some(.other), .some(StructuralSystemType.none), nil:
            break
        }

        if structural.systemType == nil, let legacySummary = structural.legacyFlatSummary {
            if let row = row("Legacy Structural Summary", legacySummary) {
                rows.append(row)
            }
        }

        if let pergolaNotes = structural.resolvedPergolaNotes {
            if let row = row("Pergola Notes", pergolaNotes) {
                rows.append(row)
            }
        }

        if let notesRow = row("Notes", structural.notes) {
            rows.append(notesRow)
        }
        rows.append(contentsOf: measurementRows(structural.measurements))
        return rows
    }

    private static func measurementRows(_ block: MeasurementsBlock?) -> [PDFRow] {
        block?.activeItems.compactMap { item in
            let type = item.resolvedType ?? "Measurement"
            let value = item.value?.nilIfBlank
            let notes = item.notes?.nilIfBlank
            guard value != nil || notes != nil else { return nil }
            let output: String
            switch (value, notes) {
            case let (value?, notes?):
                output = "\(value)\nNotes: \(notes)"
            case let (value?, nil):
                output = value
            case let (nil, notes?):
                output = "Notes: \(notes)"
            case (nil, nil):
                return nil
            }
            return PDFRow(label: "Measurement - \(type)", value: output)
        } ?? []
    }

    private static func pergolaDimensionRows(_ details: PergolaDimensionDetails?) -> [PDFRow] {
        [
            row("Width", details?.width),
            row("Length", details?.length),
            row("Height", details?.height)
        ].compactMap { $0 }
    }

    private static func appendixPages(_ scope: JobScope) throws -> [PDFPageContent] {
        var pages = try checklistPhotoAppendixPages(scope)

        if let photos = scope.photos, !photos.isEmpty {
            for (index, photo) in photos.enumerated() {
                let image = try loadImage(at: photo.imagePath, scopeID: scope.id.uuidString, reasonContext: "photo appendix \(index + 1)")
                let rows = [
                    PDFRow(label: "Captured", value: photo.createdAt.formatted(date: .abbreviated, time: .shortened)),
                    row("Caption", photo.caption)
                ].compactMap { $0 }

                pages.append(
                    PDFPageContent(
                        title: "Appendix: Photo \(index + 1)",
                        sections: [
                            PDFSection(
                                title: photo.caption?.nilIfBlank ?? "Scope Photo \(index + 1)",
                                rows: rows,
                                image: image,
                                imageRole: .appendix
                            )
                        ],
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
        let projectType = scope.projectInfo.projectTypeDisplaySummary.replacingOccurrences(of: " ", with: "")
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

private struct PDFExportComposition {
    let header: PDFHeaderContent
    let pages: [PDFPageContent]
}

private struct PDFHeaderContent {
    let title: String
    let customerName: String?
    let address: String?
    let projectType: String?
    let jobNumber: String?
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
