import SwiftUI
import PencilKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct PencilDrawingCanvas: View {
    @Binding var drawing: PKDrawing

    var body: some View {
        PencilCanvasRepresentable(drawing: $drawing)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
    }
}

private struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.backgroundColor = .clear

        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            self._drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}

enum DrawingAssetStore {
    enum StoreError: Error {
        case unsupportedPlatform
    }

    static func drawing(for path: String?) -> PKDrawing {
        guard let path,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let drawing = try? PKDrawing(data: data) else {
            return PKDrawing()
        }
        return drawing
    }

    static func urls(scopeID: UUID, baseName: String) throws -> (drawing: URL, preview: URL) {
        let directory = try scopeDirectory(scopeID: scopeID)
        return (
            drawing: directory.appendingPathComponent("\(baseName).drawing", conformingTo: .data),
            preview: directory.appendingPathComponent("\(baseName).png", conformingTo: .png)
        )
    }

    static func save(_ drawing: PKDrawing, to urls: (drawing: URL, preview: URL)) throws {
        try drawing.dataRepresentation().write(to: urls.drawing, options: .atomic)

        guard let pngData = previewPNGData(for: drawing) else {
            throw StoreError.unsupportedPlatform
        }

        try pngData.write(to: urls.preview, options: .atomic)
    }

    static func remove(urls: (drawing: URL, preview: URL)) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: urls.drawing.path) {
            try? fileManager.removeItem(at: urls.drawing)
        }
        if fileManager.fileExists(atPath: urls.preview.path) {
            try? fileManager.removeItem(at: urls.preview)
        }
    }

    private static func scopeDirectory(scopeID: UUID) throws -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let scopeDirectory = baseDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: scopeDirectory, withIntermediateDirectories: true)
        return scopeDirectory
    }

    private static func previewPNGData(for drawing: PKDrawing) -> Data? {
        let drawingBounds = drawing.bounds
        let renderRect: CGRect

        if drawingBounds.isNull || drawingBounds.isEmpty {
            renderRect = CGRect(x: 0, y: 0, width: 1200, height: 420)
        } else {
            renderRect = drawingBounds.insetBy(dx: -24, dy: -24)
        }

        #if canImport(UIKit)
        let image = drawing.image(from: renderRect, scale: 2)
        return image.pngData()
        #elseif canImport(AppKit)
        let image = drawing.image(from: renderRect, scale: 2)
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}
