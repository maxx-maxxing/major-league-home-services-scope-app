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
    private static let sectionTitleFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
    private static let pageTitleFont = UIFont.boldSystemFont(ofSize: 16)
    private static let headerTitleFont = UIFont.boldSystemFont(ofSize: 18)
    private static let compactThumbnailLimit = 3

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
        let visibleSections = ScopeSection.visibleSectionSet(for: scope)
        if visibleSections.contains(.existingConditions) {
            pruneInactiveExistingConditionsValuesForExport(scope)
        }
        if visibleSections.contains(.structuralSystem) {
            pruneInactiveStructuralValuesForExport(scope)
        }
        if visibleSections.contains(.enclosure), visibleSections.contains(.windowsAndGlass) {
            pruneInactiveEnclosureValuesForExport(scope)
        }
        let render = try render(scope: scope)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(render.filename)
            .appendingPathExtension("pdf")

        try render.data.write(to: outputURL, options: .atomic)
        logger.info(
            "share-ready PDF written bytes=\(render.data.count, privacy: .public) missingFields=\(render.missingFields.count, privacy: .public)"
        )
        return PDFExportResult(fileURL: outputURL, missingFields: render.missingFields)
    }

    static func render(scope: JobScope) throws -> (data: Data, missingFields: [String], filename: String) {
        let missing = missingRequiredFields(for: scope)
        let filename = makeFilename(for: scope)
        let layout = PDFPageLayout(pageRect: pageRect)
        let composition = try exportComposition(for: scope)
        let preparedPages = composition.pages
        let renderedPages = try paginatePages(preparedPages, layout: layout)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let diagnostics = PDFRenderDiagnostics(
            missingFieldCount: missing.count,
            plannedPages: preparedPages,
            renderedPages: renderedPages
        )

        logger.info(
            "starting PDF render plannedPages=\(diagnostics.plannedPageCount, privacy: .public) renderedPages=\(diagnostics.renderedPageCount, privacy: .public) renderedSections=\(diagnostics.renderedSectionCount, privacy: .public) appendixPages=\(diagnostics.appendixPageCount, privacy: .public) missingFields=\(diagnostics.missingFieldCount, privacy: .public)"
        )

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
            logger.error("PDF render produced empty data")
            throw ExportError.renderFailed
        }

        let actualPageCount = PDFDocument(data: data)?.pageCount ?? renderedPages.count
        logger.info(
            "completed PDF render actualPages=\(actualPageCount, privacy: .public) renderedPages=\(renderedPages.count, privacy: .public) appendixPages=\(diagnostics.appendixPageCount, privacy: .public) bytes=\(data.count, privacy: .public)"
        )

        return (data: data, missingFields: missing, filename: filename)
    }

    private static func paginatePages(_ pages: [PDFPageContent], layout: PDFPageLayout) throws -> [PDFRenderedPage] {
        var rendered: [PDFRenderedPage] = []

        for page in pages {
            let paginated = try paginate(page, layout: layout)
            rendered.append(contentsOf: paginated)
        }

        return rendered
    }

    private static func paginate(_ page: PDFPageContent, layout: PDFPageLayout) throws -> [PDFRenderedPage] {
        var output: [PDFRenderedPage] = []
        var currentPage = PDFRenderedPage(title: page.title, kind: page.kind, sections: [])
        var remainingHeight = layout.bodyRect.height

        func beginNewPage() {
            if !currentPage.sections.isEmpty {
                output.append(currentPage)
                logger.info(
                    "PDF page break emittedSections=\(currentPage.sections.count, privacy: .public) nextRenderedPage=\(output.count + 1, privacy: .public)"
                )
            }
            currentPage = PDFRenderedPage(
                title: page.title,
                kind: page.kind,
                sections: []
            )
            remainingHeight = layout.bodyRect.height
        }

        for section in page.sections {
            var pendingRows = section.rows
            var pendingThumbnails = section.thumbnails
            var pendingImage = section.image
            var sectionContinuation = 0

            while !pendingRows.isEmpty || pendingThumbnails != nil || pendingImage != nil {
                let requiredTitleHeight = layout.sectionTitleHeight + layout.sectionTitleBottomSpacing
                let minimumBodyHeight = minimumContentHeight(
                    for: pendingRows.first,
                    thumbnails: pendingThumbnails,
                    hasImage: pendingImage != nil,
                    imageRole: section.imageRole,
                    layout: layout
                )

                if remainingHeight < requiredTitleHeight + minimumBodyHeight {
                    if currentPage.sections.isEmpty {
                        logger.error(
                            "PDF section did not fit a fresh page remainingHeight=\(remainingHeight, privacy: .public)"
                        )
                        throw ExportError.contentRenderFailed("The PDF could not render section '\(section.title)' on '\(page.title)' because the content does not fit on a fresh page.")
                    } else {
                        beginNewPage()
                    }
                }

                let renderedSectionTitle = sectionContinuation == 0 ? section.title : "\(section.title) (Cont.)"
                var renderedSection = PDFRenderedSection(title: renderedSectionTitle, rows: [], thumbnails: nil, image: nil)
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
                        logger.info("PDF row split across pages")
                        break
                    }
                }

                if let thumbnails = pendingThumbnails {
                    if let renderedThumbnails = fitThumbnails(thumbnails, availableHeight: remainingHeight, layout: layout) {
                        renderedSection.thumbnails = renderedThumbnails
                        remainingHeight -= renderedThumbnails.totalHeight
                        pendingThumbnails = nil
                        placedContent = true
                    } else if placedContent || !currentPage.sections.isEmpty {
                        logger.info(
                            "PDF thumbnail continuation emittedSections=\(currentPage.sections.count + 1, privacy: .public) nextRenderedPage=\(output.count + 1, privacy: .public)"
                        )
                    } else {
                        logger.error("PDF thumbnail placement failed reason=no-usable-space")
                        throw ExportError.contentRenderFailed("The PDF could not render the thumbnails in section '\(section.title)' on '\(page.title)'.")
                    }
                }

                if let image = pendingImage {
                    if let renderedImage = fitImage(image, role: section.imageRole, availableHeight: remainingHeight, layout: layout) {
                        renderedSection.image = renderedImage
                        remainingHeight -= renderedImage.totalHeight
                        pendingImage = nil
                        placedContent = true
                    } else if placedContent || !currentPage.sections.isEmpty {
                        logger.info(
                            "PDF image continuation emittedSections=\(currentPage.sections.count + 1, privacy: .public) nextRenderedPage=\(output.count + 1, privacy: .public)"
                        )
                    } else {
                        logger.error("PDF image placement failed reason=no-usable-space")
                        throw ExportError.contentRenderFailed("The PDF could not render the image in section '\(section.title)' on '\(page.title)'.")
                    }
                }

                if placedContent {
                    currentPage.sections.append(renderedSection)
                    remainingHeight -= layout.sectionBottomSpacing
                } else {
                    remainingHeight += requiredTitleHeight
                }

                if !pendingRows.isEmpty || pendingThumbnails != nil || pendingImage != nil {
                    if currentPage.sections.isEmpty {
                        logger.error("PDF section content placement failed")
                        throw ExportError.contentRenderFailed("The PDF could not render all content for section '\(section.title)' on '\(page.title)'.")
                    }

                    sectionContinuation += 1
                    beginNewPage()
                }
            }
        }

        if !currentPage.sections.isEmpty {
            output.append(currentPage)
        }

        return output
    }

    private static func minimumContentHeight(
        for row: PDFRow?,
        thumbnails: PDFThumbnailGrid?,
        hasImage: Bool,
        imageRole: PDFImageRole,
        layout: PDFPageLayout
    ) -> CGFloat {
        if row != nil {
            return layout.minimumRowHeight
        }

        if let thumbnails {
            return thumbnailGridLayout(for: thumbnails, layout: layout).totalHeight
        }

        if hasImage {
            return imageRole.minimumHeight + layout.imageTopSpacing + layout.imageBottomSpacing
        }

        return layout.minimumRowHeight
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

    private static func fitThumbnails(_ thumbnails: PDFThumbnailGrid, availableHeight: CGFloat, layout: PDFPageLayout) -> PDFRenderedThumbnailGrid? {
        guard !thumbnails.images.isEmpty else { return nil }
        let gridLayout = thumbnailGridLayout(for: thumbnails, layout: layout)
        guard availableHeight >= gridLayout.totalHeight else { return nil }
        return PDFRenderedThumbnailGrid(
            images: thumbnails.images,
            hiddenCount: thumbnails.hiddenCount,
            layout: gridLayout
        )
    }

    private static func thumbnailGridLayout(for thumbnails: PDFThumbnailGrid, layout: PDFPageLayout) -> PDFThumbnailGridLayout {
        let markerCount = thumbnails.hiddenCount > 0 ? 1 : 0
        let itemCount = max(1, thumbnails.images.count + markerCount)
        let availableColumns = max(
            1,
            Int((layout.bodyRect.width + layout.thumbnailGap) / (layout.thumbnailSize.width + layout.thumbnailGap))
        )
        let columns = min(4, itemCount, availableColumns)
        let rowCount = Int(ceil(Double(itemCount) / Double(columns)))
        let contentHeight = CGFloat(rowCount) * layout.thumbnailSize.height
            + CGFloat(max(0, rowCount - 1)) * layout.thumbnailGap

        return PDFThumbnailGridLayout(
            columns: columns,
            rowCount: rowCount,
            itemSize: layout.thumbnailSize,
            gap: layout.thumbnailGap,
            contentHeight: contentHeight,
            totalHeight: layout.thumbnailTopSpacing + contentHeight + layout.thumbnailBottomSpacing
        )
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
        drawAdaptiveText(header.title, font: headerTitleFont, in: CGRect(x: 40, y: 34, width: rect.width - 80, height: 22), context: context, color: primaryTextColor, minimumScaleFactor: 0.72)

        let contactLine = [
            header.phone.map { "Phone: \($0)" },
            header.email.map { "Email: \($0)" }
        ].compactMap { $0 }.joined(separator: " / ").nilIfBlank

        let subtitleLines = [
            header.customerName.map { "Customer: \($0)" },
            header.address,
            contactLine
        ].compactMap { $0 }

        for (index, line) in subtitleLines.enumerated() {
            drawAdaptiveText(line, font: .systemFont(ofSize: 11), in: CGRect(x: 40, y: 58 + CGFloat(index * 14), width: rect.width - 80, height: 16), context: context, color: secondaryTextColor, minimumScaleFactor: 0.76)
        }

        if let projectType = header.projectType {
            drawAdaptiveText("Project Type: \(projectType)", font: .systemFont(ofSize: 10), in: CGRect(x: 40, y: 104, width: 260, height: 14), context: context, color: secondaryTextColor, minimumScaleFactor: 0.8)
        }

        if let jobNumber = header.jobNumber {
            drawAdaptiveText("Job #: \(jobNumber)", font: .systemFont(ofSize: 10), in: CGRect(x: rect.width - 180, y: 104, width: 140, height: 14), context: context, alignment: .right, color: secondaryTextColor, minimumScaleFactor: 0.8)
        }

        context.setStrokeColor(separatorColor.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: 124))
        context.addLine(to: CGPoint(x: rect.width - 40, y: 124))
        context.strokePath()
    }

    private static func drawFooter(in context: CGContext, rect: CGRect, pageNumber: Int, totalPages: Int) {
        let dateText = "Generated: \(Date.now.formatted(date: .abbreviated, time: .shortened))"
        drawAdaptiveText(dateText, font: .systemFont(ofSize: 9), in: CGRect(x: 40, y: rect.height - 32, width: 260, height: 12), context: context, color: secondaryTextColor, minimumScaleFactor: 0.84)
        drawAdaptiveText("Page \(pageNumber) of \(totalPages)", font: .systemFont(ofSize: 9), in: CGRect(x: rect.width - 160, y: rect.height - 32, width: 120, height: 12), context: context, alignment: .right, color: secondaryTextColor, minimumScaleFactor: 0.84)
    }

    private static func drawPageContent(in context: CGContext, page: PDFRenderedPage, layout: PDFPageLayout) {
        drawAdaptiveText(page.title, font: pageTitleFont, in: layout.pageTitleRect, context: context, color: primaryTextColor, minimumScaleFactor: 0.76)

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

            if let thumbnails = section.thumbnails {
                drawThumbnailGrid(thumbnails, in: context, layout: layout, y: y)
                y += thumbnails.totalHeight
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

    private static func drawThumbnailGrid(_ thumbnails: PDFRenderedThumbnailGrid, in context: CGContext, layout: PDFPageLayout, y: CGFloat) {
        let itemSize = thumbnails.layout.itemSize
        let gap = thumbnails.layout.gap
        let columns = max(1, thumbnails.layout.columns)
        let startX = layout.bodyRect.minX + 8
        let startY = y + layout.thumbnailTopSpacing
        let thumbnailBorderColor = UIColor(white: 0.82, alpha: 1)
        let moreFillColor = UIColor(white: 0.94, alpha: 1)

        for (index, image) in thumbnails.images.enumerated() {
            let rect = thumbnailRect(
                index: index,
                columns: columns,
                itemSize: itemSize,
                gap: gap,
                startX: startX,
                startY: startY
            )
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: layout.thumbnailCornerRadius)

            context.saveGState()
            roundedRect.addClip()
            drawAspectFill(image, in: rect)
            context.restoreGState()

            thumbnailBorderColor.setStroke()
            roundedRect.lineWidth = 0.8
            roundedRect.stroke()
        }

        if thumbnails.hiddenCount > 0 {
            let markerIndex = thumbnails.images.count
            let rect = thumbnailRect(
                index: markerIndex,
                columns: columns,
                itemSize: itemSize,
                gap: gap,
                startX: startX,
                startY: startY
            )
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: layout.thumbnailCornerRadius)

            moreFillColor.setFill()
            roundedRect.fill()
            thumbnailBorderColor.setStroke()
            roundedRect.lineWidth = 0.8
            roundedRect.stroke()

            drawText(
                "+\(thumbnails.hiddenCount) more",
                font: .systemFont(ofSize: 9, weight: .medium),
                in: rect.insetBy(dx: 5, dy: 18),
                context: context,
                alignment: .center,
                color: secondaryTextColor
            )
        }
    }

    private static func thumbnailRect(
        index: Int,
        columns: Int,
        itemSize: CGSize,
        gap: CGFloat,
        startX: CGFloat,
        startY: CGFloat
    ) -> CGRect {
        let row = index / max(1, columns)
        let column = index % max(1, columns)

        return CGRect(
            x: startX + CGFloat(column) * (itemSize.width + gap),
            y: startY + CGFloat(row) * (itemSize.height + gap),
            width: itemSize.width,
            height: itemSize.height
        )
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
        thumbnails: PDFThumbnailGrid? = nil,
        image: UIImage? = nil,
        imageRole: PDFImageRole = .standard
    ) -> PDFSection? {
        let resolvedRows = rows.compactMap { $0 } + additionalRows
        guard !resolvedRows.isEmpty || thumbnails != nil || image != nil else { return nil }
        return PDFSection(title: title, rows: resolvedRows, thumbnails: thumbnails, image: image, imageRole: imageRole)
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
            phone: meaningfulPDFText(scope.projectInfo.phone),
            email: meaningfulPDFText(scope.projectInfo.email),
            projectType: scope.projectInfo.activeProjectTypes.isEmpty ? nil : meaningfulPDFText(scope.projectInfo.projectTypeDisplaySummary),
            jobNumber: meaningfulPDFText(scope.jobNumber)
        )
    }

    private static func pageOne(_ scope: JobScope) -> PDFPageContent? {
        let project = scope.projectInfo
        let shouldIncludeDimensions = !project.activeProjectTypes.isEmpty

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
                shouldIncludeDimensions ? section(title: "Dimensions", rows: dimensionRows(scope.dimensions)) : nil
            ]
        )
    }

    private static func pageTwo(_ scope: JobScope) -> PDFPageContent? {
        let visibleSections = ScopeSection.visibleSectionSet(for: scope)
        let existing = scope.existingConditions?.normalizedForExport()
        let attachment = scope.attachment
        var sections: [PDFSection?] = [
            visibleSections.contains(.existingConditions) ? section(title: "Existing Conditions", rows: [
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
                row("HOA Notes", existing?.hoaNotes)
            ]) : nil
        ]

        if visibleSections.contains(.existingConditions) {
            sections.append(contentsOf: checklistPhotoThumbnailSections(scopeID: scope.id).map { Optional($0) })
        }
        sections.append(
            visibleSections.contains(.attachmentConditions) ? section(title: "Attachment Conditions", rows: [
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
            ], additionalRows: measurementRows(attachment?.measurements)) : nil
        )

        return page(
            title: "Existing Conditions + Attachment Conditions",
            sections: sections
        )
    }

    private static func pageThree(_ scope: JobScope) -> PDFPageContent? {
        let visibleSections = ScopeSection.visibleSectionSet(for: scope)
        let structural = scope.structuralSystem?.normalizedForExport()
        let enclosure = scope.enclosure?.normalizedForExport()

        return page(
            title: "Structural + Screen Enclosure",
            sections: [
                visibleSections.contains(.structuralSystem) ? section(title: "Structural System", additionalRows: structuralRows(structural)) : nil,
                visibleSections.contains(.enclosure) ? section(title: "Screen Enclosure", rows: [
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
                ], additionalRows: measurementRows(enclosure?.screenMeasurements)) : nil
            ]
        )
    }

    private static func pageFour(_ scope: JobScope) -> PDFPageContent? {
        let visibleSections = ScopeSection.visibleSectionSet(for: scope)
        let enclosure = scope.enclosure?.normalizedForExport()
        let window = enclosure?.windowSystem
        let electrical = scope.electrical
        let drainage = scope.drainage

        return page(
            title: "Sunroom + Electrical + Drainage",
            sections: [
                visibleSections.contains(.windowsAndGlass) ? section(title: "Sunroom", rows: [
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
                ], additionalRows: measurementRows(enclosure?.sunroomMeasurements)) : nil,
                visibleSections.contains(.electrical) ? section(title: "Electrical", rows: [
                    numberRow("Outlets", electrical?.outletCount),
                    enumRow("Lighting", electrical?.lighting),
                    boolRow("Fan Install", electrical?.fanInstall),
                    row("Switch Locations", electrical?.switchLocations),
                    row("Dedicated Circuits", electrical?.dedicatedCircuits?.map(\.displayName).joined(separator: ", ")),
                    row("Notes", electrical?.notes)
                ], additionalRows: measurementRows(electrical?.measurements)) : nil,
                visibleSections.contains(.drainage) ? section(title: "Drainage", rows: [
                    boolRow("Gutters", drainage?.gutters),
                    row("Downspouts", drainage?.downspoutLocations),
                    boolRow("Drain Tie-In", drainage?.drainTieIn),
                    row("Drain Notes", drainage?.slopeNotes)
                ], additionalRows: measurementRows(drainage?.measurements)) : nil
            ]
        )
    }

    private static func pageFive(_ scope: JobScope) throws -> PDFPageContent? {
        let visibleSections = ScopeSection.visibleSectionSet(for: scope)
        let finishes = scope.finishes
        let permits = scope.permitsHOA
        let production = scope.production

        var signatureRows: [PDFRow?] = [
            dateRow("Signed Date", scope.customerApproval?.signedDate)
        ]
        var signatureImage: UIImage?

        if visibleSections.contains(.signatureAndExport), let path = scope.customerApproval?.signaturePNGPath {
            signatureImage = try loadImage(at: path, reasonContext: "signature image")
            signatureRows.append(PDFRow(label: "Signature", value: "Embedded"))
        }

        return page(
            title: "Finishes + Permits + Production",
            sections: [
                visibleSections.contains(.finishes) ? section(title: "Finishes", rows: [
                    row("Trim Type", finishes?.trimType),
                    row("Paint / Powder", finishes?.paintOrPowderColor),
                    boolRow("Siding Replacement", finishes?.sidingReplacementRequired),
                    row("Caulking / Sealing", finishes?.caulkingSealingNotes)
                ], additionalRows: measurementRows(finishes?.measurements)) : nil,
                visibleSections.contains(.permitsHOA) ? section(title: "Permits / HOA", rows: [
                    boolRow("Permit Required", permits?.permitRequired),
                    boolRow("HOA Required", permits?.hoaApprovalRequired),
                    boolRow("Engineering Required", permits?.engineeringRequired),
                    row("Jurisdiction", permits?.jurisdiction),
                    row("Status Notes", permits?.statusNotes)
                ]) : nil,
                visibleSections.contains(.productionNotes) ? section(title: "Production", rows: [
                    row("Crew Lead", production?.crewLead),
                    dateRow("Start Date", production?.startDate),
                    row("Duration", production?.durationEstimate),
                    enumRow("Material Status", production?.materialOrderStatus),
                    enumRow("Permit Status", production?.permitStatus),
                    row("Notes", scope.customerApproval?.optionsConfirmedText)
                ]) : nil,
                visibleSections.contains(.documents) ? documentsSection(scope.documents) : nil,
                visibleSections.contains(.documents) ? scopePhotoThumbnailSection(scope.photos) : nil,
                visibleSections.contains(.signatureAndExport) ? section(title: "Customer Signature", rows: signatureRows, image: signatureImage, imageRole: .signature) : nil
            ]
        )
    }

    private static func coreFlowPage(for scope: JobScope) throws -> PDFPageContent? {
        // Preserve the existing filtered section builders, but drop their old fixed page boundaries.
        let coreSectionGroups = [
            pageOne(scope),
            pageTwo(scope),
            pageThree(scope),
            pageFour(scope),
            try pageFive(scope)
        ].compactMap { $0 }

        let coreSections = coreSectionGroups.flatMap { $0.sections }
        guard !coreSections.isEmpty else { return nil }

        return PDFPageContent(
            title: "Scope Details",
            sections: coreSections,
            kind: .core
        )
    }

    private static func plannedPages(for scope: JobScope) throws -> [PDFPageContent] {
        let corePages = [
            try coreFlowPage(for: scope)
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

    private static func checklistPhotoThumbnailSections(scopeID: UUID) -> [PDFSection] {
        ChecklistPhotoAssetStore.categorizedPhotos(scopeID: scopeID).compactMap { category, photos in
            guard let thumbnails = thumbnailGrid(
                paths: photos.map(\.filePath),
                totalCount: photos.count
            ) else {
                return nil
            }

            return section(title: category.displayName, thumbnails: thumbnails)
        }
    }

    private static func scopePhotoThumbnailSection(_ photos: [PhotoAttachment]?) -> PDFSection? {
        guard let photos, !photos.isEmpty else { return nil }
        guard let thumbnails = thumbnailGrid(
            paths: photos.map(\.imagePath),
            totalCount: photos.count
        ) else {
            return nil
        }

        return section(title: "Scope Photos", thumbnails: thumbnails)
    }

    private static func thumbnailGrid(
        paths: [String],
        totalCount: Int
    ) -> PDFThumbnailGrid? {
        let visiblePaths = paths.prefix(compactThumbnailLimit)
        let images = visiblePaths.compactMap { path -> UIImage? in
            guard let image = UIImage(contentsOfFile: path), image.size.width > 0, image.size.height > 0 else {
                logger.notice("PDF thumbnail skipped reason=missing-or-invalid")
                return nil
            }

            return image
        }

        guard !images.isEmpty else { return nil }
        return PDFThumbnailGrid(
            images: images,
            hiddenCount: max(0, totalCount - compactThumbnailLimit)
        )
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
        var pages: [PDFPageContent] = []

        guard ScopeSection.signatureAndExport.isVisible(in: scope) else {
            return pages
        }

        if let diagram = scope.sketches?.first(where: { $0.title == "Site Diagram" }) {
            let image = try loadImage(at: diagram.previewPNGPath, reasonContext: "site diagram appendix")
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

    private static func loadImage(at path: String, reasonContext: String) throws -> UIImage {
        guard let image = UIImage(contentsOfFile: path) else {
            logger.error("PDF required image skipped reason=missing-or-unreadable")
            throw ExportError.contentRenderFailed("The PDF could not include the required \(reasonContext).")
        }

        guard image.size.width > 0, image.size.height > 0 else {
            logger.error("PDF required image skipped reason=invalid-size")
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
        minimumScaleFactor: CGFloat = 0.8
    ) {
        let fitted = fittedText(text, font: font, width: rect.width, height: rect.height, minimumScaleFactor: minimumScaleFactor)
        if fitted.scaled || fitted.truncated {
            logger.notice(
                "PDF text adjusted scaled=\(fitted.scaled, privacy: .public) truncated=\(fitted.truncated, privacy: .public)"
            )
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
    let sectionTitleHeight: CGFloat = 17
    let sectionTitleBottomSpacing: CGFloat = 3
    let sectionBottomSpacing: CGFloat = 10
    let rowBottomSpacing: CGFloat = 4
    let imageTopSpacing: CGFloat = 4
    let imageBottomSpacing: CGFloat = 10
    let minimumRowHeight: CGFloat = 14
    let thumbnailTopSpacing: CGFloat = 4
    let thumbnailBottomSpacing: CGFloat = 8
    let thumbnailGap: CGFloat = 8
    let thumbnailSize = CGSize(width: 72, height: 54)
    let thumbnailCornerRadius: CGFloat = 7

    init(pageRect: CGRect) {
        self.pageRect = pageRect
        self.pageTitleRect = CGRect(x: 40, y: 138, width: pageRect.width - 80, height: 20)
        self.bodyRect = CGRect(x: 40, y: 164, width: pageRect.width - 80, height: 564)
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
    let phone: String?
    let email: String?
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
    var thumbnails: PDFRenderedThumbnailGrid?
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

private struct PDFThumbnailGrid {
    let images: [UIImage]
    let hiddenCount: Int
}

private struct PDFRenderedThumbnailGrid {
    let images: [UIImage]
    let hiddenCount: Int
    let layout: PDFThumbnailGridLayout

    var totalHeight: CGFloat {
        layout.totalHeight
    }
}

private struct PDFThumbnailGridLayout {
    let columns: Int
    let rowCount: Int
    let itemSize: CGSize
    let gap: CGFloat
    let contentHeight: CGFloat
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
    let missingFieldCount: Int
    let plannedPageCount: Int
    let renderedPageCount: Int
    let renderedSectionCount: Int
    let appendixPageCount: Int

    init(
        missingFieldCount: Int,
        plannedPages: [PDFPageContent],
        renderedPages: [PDFRenderedPage]
    ) {
        self.missingFieldCount = missingFieldCount
        plannedPageCount = plannedPages.count
        renderedPageCount = renderedPages.count
        renderedSectionCount = renderedPages.reduce(0) { $0 + $1.sections.count }
        appendixPageCount = renderedPages.filter { $0.kind != .core }.count
    }
}

private struct PDFRow {
    let label: String
    let value: String
}

private struct PDFSection {
    let title: String
    let rows: [PDFRow]
    var thumbnails: PDFThumbnailGrid? = nil
    var image: UIImage? = nil
    var imageRole: PDFImageRole = .standard
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
