import SwiftUI
import UIKit

struct ShareButton: View {
    let fileURL: URL
    let label: Label<Text, Image>

    @State private var tempShareURL: URL? = nil
    @State private var showExporter = false

    var body: some View {
        VStack {
            Button {
                print("[DEBUG] 공유 버튼 눌림: \(fileURL.lastPathComponent)")
                if let copied = copyFileToTemp(fileURL) {
                    print("[DEBUG] 임시 복사 성공 → \(copied.path)")
                    tempShareURL = copied
                    DispatchQueue.main.async {
                        showExporter = true
                    }
                } else {
                    print("❌ 공유 실패: 임시 복사 실패")
                }
            } label: {
                label
            }
        }
        .sheet(isPresented: $showExporter) {
            if let url = tempShareURL {
                DocumentExporter(fileURL: url)
            } else {
                Text("❌ 내보낼 파일이 없습니다.")
            }
        }
    }

    private func copyFileToTemp(_ original: URL) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + original.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: original, to: tempURL)
            return tempURL
        } catch {
            print("❌ 임시 복사 실패:", error)
            return nil
        }
    }
}
