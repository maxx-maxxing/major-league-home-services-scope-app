import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

struct ScopePhotosSheet: View {
    @Bindable var scope: JobScope
    @ObservedObject var autosave: DebouncedAutosave

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var importError: String?
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let checklist = scope.existingConditions?.photoChecklist {
                        GlassChromePanel(cornerRadius: 24) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Requested Photos")
                                    .font(.headline)
                                Text(photoChecklistSummary(checklist))
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

                                        TextField("Caption", text: captionBinding(for: photo.id))
                                            .liquidGlassInput()

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
                    photos[index].caption = blankToNil(newValue)
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

private struct PhotoPreviewImage: View {
    let path: String

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .liquidGlassSurface(cornerRadius: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.clear)
            .frame(height: 180)
            .liquidGlassSurface(cornerRadius: 18)
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

private func photoChecklistSummary(_ checklist: PhotoChecklist) -> String {
    var selected: [String] = []
    if checklist.frontOfHouse == true { selected.append("Front of House") }
    if checklist.rearElevation == true { selected.append("Rear Elevation") }
    if checklist.roofLine == true { selected.append("Roof Line") }
    if checklist.electricalPanel == true { selected.append("Electrical Panel") }
    if checklist.workArea == true { selected.append("Work Area") }
    return selected.isEmpty ? "No requested photos marked." : selected.joined(separator: ", ")
}

private func blankToNil(_ value: String) -> String? {
    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
}
