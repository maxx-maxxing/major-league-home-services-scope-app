import SwiftUI

struct PDFPreviewStubView: View {
    let scope: JobScope

    var body: some View {
        CardGroup(title: "PDF Preview") {
            Label("Preview and export are scheduled for Milestone 4.", systemImage: "doc.text.magnifyingglass")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("Current scope: \(scope.displayName)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
