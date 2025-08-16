import SwiftUI

struct SaveToFilesButton: View {
    let fileURL: URL
    @State private var showExporter = false

    var body: some View {
        Button {
            showExporter = true
        } label: {
            Label("내 파일에 저장", systemImage: "folder.badge.plus")
        }
        .sheet(isPresented: $showExporter) {
            DocumentExporter(fileURL: fileURL)
        }
    }
}
