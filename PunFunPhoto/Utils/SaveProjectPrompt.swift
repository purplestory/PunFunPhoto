import SwiftUI

struct SaveProjectPrompt: View {
    @Binding var isPresented: Bool
    @ObservedObject var photo1: PhotoState
    @ObservedObject var photo2: PhotoState
    @EnvironmentObject var appState: AppState

    @State private var projectName: String = generateSaveFileName().replacingOccurrences(of: ".pfp", with: "")
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("파일 이름")) {
                    TextField("예: pfoca_20250427_0001", text: $projectName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section {
                    Button("저장", action: saveProject)
                }
            }
            .navigationTitle("새 이름으로 저장")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveProject() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            alertMessage = "⚠️ 파일 이름을 입력해 주세요."
            showAlert = true
            return
        }

        let safeBaseName = trimmedName.replacingOccurrences(of: ".pfp", with: "")

        if let newURL = saveProjectAsArchive(photo1: photo1, photo2: photo2, fileName: safeBaseName) {
            appState.currentProjectURL = newURL
            print("✅ 새 이름으로 저장 완료: \(newURL.lastPathComponent)")
        } else {
            alertMessage = "❌ 파일 저장 실패"
            showAlert = true
            return
        }
        
        isPresented = false
    }
}
