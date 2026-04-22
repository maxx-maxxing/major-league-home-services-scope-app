import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CoreTransferable

#if canImport(UIKit)
import UIKit
#endif

struct ScopePhotosSheet: View {
    let scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var importError: String?
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let checklistSummary = ChecklistPhotoAssetStore.summary(scopeID: scope.id) {
                        CardGroup(title: "Existing Conditions Checklist") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(checklistSummary)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let photos = scope.photos, !photos.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(photos) { photo in
                                CardGroup(title: blankToNil(photo.caption ?? "") ?? "Photo") {
                                    VStack(alignment: .leading, spacing: 12) {
                                        PhotoPreviewImage(path: photo.imagePath)
                                            .frame(maxWidth: .infinity)

                                        LabeledTextField("Caption", text: captionBinding(for: photo.id))

                                        Text("Added \(photo.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)

                                        Button("Delete Photo", role: .destructive) {
                                            deletePhoto(photo)
                                        }
                                        .frame(minHeight: 44)
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .scale(scale: 0.94).combined(with: .opacity)
                                ))
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No Photos Yet",
                            systemImage: "photo.on.rectangle",
                            description: Text("Add scope photos from the photo library. They will be stored locally and included in the PDF appendix.")
                        )
                    }
                }
                .padding(16)
            }
            .background(LiquidGlassBackdrop())
            .animation(.snappy(duration: 0.28, extraBounce: 0), value: scope.photos?.map(\.id) ?? [])
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        if isImporting {
                            ProgressView()
                        } else {
                            Label("Add Photos", systemImage: "plus")
                        }
                    }
                    .disabled(isImporting)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                importSelectedPhotos(newItems)
            }
            .alert("Photo Import Failed", isPresented: importErrorPresented) {
                Button("OK", role: .cancel) {
                    importError = nil
                }
            } message: {
                Text(importError ?? "Unable to import the selected photos.")
            }
        }
    }

    private var importErrorPresented: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isPresented in
                if !isPresented {
                    importError = nil
                }
            }
        )
    }

    private func captionBinding(for photoID: UUID) -> Binding<String> {
        Binding(
            get: { scope.photos?.first(where: { $0.id == photoID })?.caption ?? "" },
            set: { newValue in
                updatePhotos { photos in
                    guard let index = photos.firstIndex(where: { $0.id == photoID }) else { return }
                    photos[index].caption = newValue.nilIfWhitespaceOnly
                }
            }
        )
    }

    private func importSelectedPhotos(_ items: [PhotosPickerItem]) {
        isImporting = true

        Task {
            do {
                for item in items {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    let savedPhoto = try PhotoAssetStore.savePhoto(data: data, scopeID: scope.id)

                    await MainActor.run {
                        withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
                            updatePhotos { photos in
                                photos.append(savedPhoto)
                            }
                        }
                    }
                }

                await MainActor.run {
                    selectedItems = []
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    selectedItems = []
                    isImporting = false
                    importError = error.localizedDescription
                }
            }
        }
    }

    private func deletePhoto(_ photo: PhotoAttachment) {
        PhotoAssetStore.removePhoto(at: photo.imagePath)
        withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
            updatePhotos { photos in
                photos.removeAll { $0.id == photo.id }
            }
        }
    }

    private func updatePhotos(_ update: (inout [PhotoAttachment]) -> Void) {
        var photos = scope.photos ?? []
        update(&photos)
        scope.photos = photos.isEmpty ? nil : photos
        autosave.scheduleSave(for: scope)
    }
}

struct PhotoPreviewImage: View {
    let path: String

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .liquidGlassSurface(cornerRadius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.clear)
            .frame(height: 180)
            .liquidGlassSurface(cornerRadius: 20)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

enum PhotoAssetStore {
    enum StoreError: LocalizedError {
        case unsupportedImageData

        var errorDescription: String? {
            switch self {
            case .unsupportedImageData:
                return "The selected item could not be converted into a supported image."
            }
        }
    }

    static func savePhoto(data: Data, scopeID: UUID) throws -> PhotoAttachment {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            throw StoreError.unsupportedImageData
        }

        let photoID = UUID()
        let imageURL = try photoURL(scopeID: scopeID, photoID: photoID)
        guard let jpegData = image.jpegData(compressionQuality: 0.88) else {
            throw StoreError.unsupportedImageData
        }

        try jpegData.write(to: imageURL, options: .atomic)
        return PhotoAttachment(id: photoID, caption: nil, imagePath: imageURL.path)
        #else
        throw StoreError.unsupportedImageData
        #endif
    }

    static func removePhoto(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static func photoURL(scopeID: UUID, photoID: UUID) throws -> URL {
        let directory = try scopeDirectory(scopeID: scopeID)
        return directory.appendingPathComponent("\(photoID.uuidString).jpg", conformingTo: .jpeg)
    }

    private static func scopeDirectory(scopeID: UUID) throws -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let scopeDirectory = baseDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
            .appendingPathComponent("Photos", isDirectory: true)

        try FileManager.default.createDirectory(at: scopeDirectory, withIntermediateDirectories: true)
        return scopeDirectory
    }
}

private func blankToNil(_ value: String) -> String? {
    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
}

enum DocumentAssetStore {
    enum StoreError: LocalizedError {
        case unsupportedImageData
        case unableToAccessFile

        var errorDescription: String? {
            switch self {
            case .unsupportedImageData:
                return "The selected image could not be converted into a supported file."
            case .unableToAccessFile:
                return "The selected file could not be accessed."
            }
        }
    }

    static func importFile(from sourceURL: URL, scopeID: UUID) throws -> DocumentAttachmentFile {
        let didAccessSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw StoreError.unableToAccessFile
        }

        let attachmentID = UUID()
        let destinationURL = try fileURL(
            scopeID: scopeID,
            attachmentID: attachmentID,
            preferredFilename: sourceURL.lastPathComponent
        )

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        return DocumentAttachmentFile(
            id: attachmentID,
            originalFilename: sourceURL.lastPathComponent,
            filePath: destinationURL.path,
            contentTypeIdentifier: resolvedContentTypeIdentifier(for: sourceURL),
            source: .files
        )
    }

    static func savePhotoLibraryImage(data: Data, scopeID: UUID) throws -> DocumentAttachmentFile {
        try saveImageData(
            data,
            scopeID: scopeID,
            source: .photoLibrary,
            fallbackFilename: "Photo.jpg"
        )
    }

    #if canImport(UIKit)
    static func saveCameraImage(_ image: UIImage, scopeID: UUID) throws -> DocumentAttachmentFile {
        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw StoreError.unsupportedImageData
        }

        return try saveImageData(
            jpegData,
            scopeID: scopeID,
            source: .camera,
            fallbackFilename: "Camera.jpg"
        )
    }
    #endif

    static func removeAttachment(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static func saveImageData(
        _ data: Data,
        scopeID: UUID,
        source: DocumentAttachmentSource,
        fallbackFilename: String
    ) throws -> DocumentAttachmentFile {
        #if canImport(UIKit)
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw StoreError.unsupportedImageData
        }

        let attachmentID = UUID()
        let destinationURL = try fileURL(
            scopeID: scopeID,
            attachmentID: attachmentID,
            preferredFilename: fallbackFilename
        )

        try jpegData.write(to: destinationURL, options: .atomic)

        return DocumentAttachmentFile(
            id: attachmentID,
            originalFilename: fallbackFilename,
            filePath: destinationURL.path,
            contentTypeIdentifier: UTType.jpeg.identifier,
            source: source
        )
        #else
        throw StoreError.unsupportedImageData
        #endif
    }

    private static func resolvedContentTypeIdentifier(for sourceURL: URL) -> String? {
        if let resourceValues = try? sourceURL.resourceValues(forKeys: [.contentTypeKey]),
           let contentType = resourceValues.contentType {
            return contentType.identifier
        }

        guard !sourceURL.pathExtension.isEmpty else { return nil }
        return UTType(filenameExtension: sourceURL.pathExtension)?.identifier
    }

    private static func fileURL(scopeID: UUID, attachmentID: UUID, preferredFilename: String) throws -> URL {
        let directory = try documentsDirectory(scopeID: scopeID)
        let sanitizedFilename = sanitizedFilenameComponent(preferredFilename)
        let filename = "\(attachmentID.uuidString)-\(sanitizedFilename)"
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    private static func documentsDirectory(scopeID: UUID) throws -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = baseDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func sanitizedFilenameComponent(_ filename: String) -> String {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "Attachment" : trimmed
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_. "))
        let sanitizedScalars = fallback.unicodeScalars.map { allowed.contains($0) ? $0 : "-" }
        return String(String.UnicodeScalarView(sanitizedScalars)).replacingOccurrences(of: "  ", with: " ")
    }
}

enum ChecklistPhotoAssetStore {
    private static let metadataSeparator = "__"

    enum StoreError: LocalizedError {
        case unsupportedImageData
        case unsupportedFileType
        case unableToAccessFile

        var errorDescription: String? {
            switch self {
            case .unsupportedImageData:
                return "The selected image could not be converted into a supported checklist photo."
            case .unsupportedFileType:
                return "Only image files can be attached to the Existing Conditions photo checklist."
            case .unableToAccessFile:
                return "The selected file could not be accessed."
            }
        }
    }

    static func importFile(
        from sourceURL: URL,
        scopeID: UUID,
        category: PhotoChecklistCategory?
    ) throws -> DocumentAttachmentFile {
        let didAccessSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw StoreError.unableToAccessFile
        }

        let resolvedType = resolvedContentTypeIdentifier(for: sourceURL).flatMap { UTType($0) }
        guard resolvedType?.conforms(to: .image) == true else {
            throw StoreError.unsupportedFileType
        }

        let attachmentID = UUID()
        let destinationURL = try fileURL(
            scopeID: scopeID,
            category: category,
            source: .files,
            attachmentID: attachmentID,
            preferredFilename: sourceURL.lastPathComponent
        )

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        return DocumentAttachmentFile(
            id: attachmentID,
            originalFilename: sourceURL.lastPathComponent,
            filePath: destinationURL.path,
            contentTypeIdentifier: resolvedType?.identifier,
            source: .files
        )
    }

    static func savePhotoLibraryImage(
        data: Data,
        scopeID: UUID,
        category: PhotoChecklistCategory?
    ) throws -> DocumentAttachmentFile {
        try saveImageData(
            data,
            scopeID: scopeID,
            category: category,
            source: .photoLibrary,
            fallbackFilename: "ChecklistPhoto.jpg"
        )
    }

    static func importPhotoLibraryItem(
        _ item: PhotosPickerItem,
        scopeID: UUID,
        category: PhotoChecklistCategory?
    ) async throws -> DocumentAttachmentFile {
        if let transferredFile = try? await item.loadTransferable(type: ImportedChecklistPickerImage.self) {
            return try importTransferredImageFile(
                from: transferredFile.file,
                scopeID: scopeID,
                category: category,
                source: .photoLibrary
            )
        }

        if let data = try await item.loadTransferable(type: Data.self) {
            return try saveImageData(
                data,
                scopeID: scopeID,
                category: category,
                source: .photoLibrary,
                fallbackFilename: fallbackPhotoLibraryFilename(for: item)
            )
        }

        throw StoreError.unsupportedImageData
    }

    #if canImport(UIKit)
    static func saveCameraImage(
        _ image: UIImage,
        scopeID: UUID,
        category: PhotoChecklistCategory?
    ) throws -> DocumentAttachmentFile {
        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw StoreError.unsupportedImageData
        }

        return try saveImageData(
            jpegData,
            scopeID: scopeID,
            category: category,
            source: .camera,
            fallbackFilename: "ChecklistCamera.jpg"
        )
    }
    #endif

    static func removePhoto(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func photos(scopeID: UUID, category: PhotoChecklistCategory) -> [DocumentAttachmentFile] {
        guard let directory = try? checklistDirectory(scopeID: scopeID, category: category),
              let fileURLs = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentTypeKey, .creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return fileURLs.compactMap { attachment(from: $0) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    static func categorizedPhotos(scopeID: UUID) -> [(category: PhotoChecklistCategory, photos: [DocumentAttachmentFile])] {
        PhotoChecklistCategory.allCases.compactMap { category in
            let photos = photos(scopeID: scopeID, category: category)
            return photos.isEmpty ? nil : (category, photos)
        }
    }

    static func summary(scopeID: UUID) -> String? {
        let parts = categorizedPhotos(scopeID: scopeID).map { "\($0.category.displayName) (\($0.photos.count))" }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private static func saveImageData(
        _ data: Data,
        scopeID: UUID,
        category: PhotoChecklistCategory?,
        source: DocumentAttachmentSource,
        fallbackFilename: String
    ) throws -> DocumentAttachmentFile {
        #if canImport(UIKit)
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw StoreError.unsupportedImageData
        }

        let attachmentID = UUID()
        let destinationURL = try fileURL(
            scopeID: scopeID,
            category: category,
            source: source,
            attachmentID: attachmentID,
            preferredFilename: fallbackFilename
        )

        try jpegData.write(to: destinationURL, options: .atomic)

        return DocumentAttachmentFile(
            id: attachmentID,
            originalFilename: fallbackFilename,
            filePath: destinationURL.path,
            contentTypeIdentifier: UTType.jpeg.identifier,
            source: source
        )
        #else
        throw StoreError.unsupportedImageData
        #endif
    }

    private static func importTransferredImageFile(
        from sourceURL: URL,
        scopeID: UUID,
        category: PhotoChecklistCategory?,
        source: DocumentAttachmentSource
    ) throws -> DocumentAttachmentFile {
        let resolvedType = resolvedContentTypeIdentifier(for: sourceURL).flatMap { UTType($0) }
        guard resolvedType?.conforms(to: .image) == true else {
            throw StoreError.unsupportedFileType
        }

        let attachmentID = UUID()
        let destinationURL = try fileURL(
            scopeID: scopeID,
            category: category,
            source: source,
            attachmentID: attachmentID,
            preferredFilename: sourceURL.lastPathComponent
        )

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        return DocumentAttachmentFile(
            id: attachmentID,
            originalFilename: sourceURL.lastPathComponent,
            filePath: destinationURL.path,
            contentTypeIdentifier: resolvedType?.identifier,
            source: source
        )
    }

    private static func fileURL(
        scopeID: UUID,
        category: PhotoChecklistCategory?,
        source: DocumentAttachmentSource,
        attachmentID: UUID,
        preferredFilename: String
    ) throws -> URL {
        let directory = try checklistDirectory(scopeID: scopeID, category: category)
        let sanitizedFilename = sanitizedFilenameComponent(preferredFilename)
        let sourceComponent = sanitizedFilenameComponent(source.rawValue)
        let filename = "\(attachmentID.uuidString)\(metadataSeparator)\(sourceComponent)\(metadataSeparator)\(sanitizedFilename)"
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    private static func checklistDirectory(scopeID: UUID, category: PhotoChecklistCategory?) throws -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var directory = baseDirectory
            .appendingPathComponent("ScopeAssets", isDirectory: true)
            .appendingPathComponent(scopeID.uuidString, isDirectory: true)
            .appendingPathComponent("ExistingConditionsChecklist", isDirectory: true)

        if let category {
            directory.appendPathComponent(category.rawValue, isDirectory: true)
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func resolvedContentTypeIdentifier(for sourceURL: URL) -> String? {
        if let resourceValues = try? sourceURL.resourceValues(forKeys: [.contentTypeKey]),
           let contentType = resourceValues.contentType {
            return contentType.identifier
        }

        guard !sourceURL.pathExtension.isEmpty else { return nil }
        return UTType(filenameExtension: sourceURL.pathExtension)?.identifier
    }

    private static func sanitizedFilenameComponent(_ filename: String) -> String {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "ChecklistPhoto" : trimmed
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_. "))
        let sanitizedScalars = fallback.unicodeScalars.map { allowed.contains($0) ? $0 : "-" }
        return String(String.UnicodeScalarView(sanitizedScalars)).replacingOccurrences(of: "  ", with: " ")
    }

    private static func attachment(from fileURL: URL) -> DocumentAttachmentFile? {
        let parsedName = parsedFilenameMetadata(fileURL.lastPathComponent)
        let resourceValues = try? fileURL.resourceValues(forKeys: [.contentTypeKey, .creationDateKey, .contentModificationDateKey])
        let contentTypeIdentifier = resourceValues?.contentType?.identifier ?? resolvedContentTypeIdentifier(for: fileURL)
        let createdAt = resourceValues?.creationDate ?? resourceValues?.contentModificationDate ?? .now

        return DocumentAttachmentFile(
            id: parsedName.id,
            originalFilename: parsedName.originalFilename,
            filePath: fileURL.path,
            contentTypeIdentifier: contentTypeIdentifier,
            source: parsedName.source,
            createdAt: createdAt
        )
    }

    private static func parsedFilenameMetadata(_ filename: String) -> (id: UUID, source: DocumentAttachmentSource, originalFilename: String) {
        let basename = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: filename).pathExtension
        let components = basename.components(separatedBy: metadataSeparator)

        if components.count >= 3,
           let id = UUID(uuidString: components[0]),
           let source = DocumentAttachmentSource(rawValue: components[1]) {
            let originalBase = components.dropFirst(2).joined(separator: metadataSeparator)
            let originalFilename = ext.isEmpty ? originalBase : "\(originalBase).\(ext)"
            return (id, source, originalFilename)
        }

        if filename.count > 37,
           let id = UUID(uuidString: String(filename.prefix(36))) {
            let originalFilename = String(filename.dropFirst(37))
            return (id, .files, originalFilename.isEmpty ? filename : originalFilename)
        }

        return (UUID(), .files, filename)
    }

    private static func fallbackPhotoLibraryFilename(for item: PhotosPickerItem) -> String {
        let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })
        let ext = type?.preferredFilenameExtension ?? "jpg"
        return "ChecklistPhoto.\(ext)"
    }
}

private struct ImportedChecklistPickerImage: Transferable {
    let file: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            Self(file: received.file)
        }
    }
}

#if canImport(UIKit)
struct DocumentCameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: DocumentCameraPicker

        init(parent: DocumentCameraPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            } else {
                parent.onCancel()
            }
        }
    }
}
#endif
