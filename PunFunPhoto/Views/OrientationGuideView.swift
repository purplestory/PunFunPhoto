import SwiftUI
import ZipArchive

struct OrientationGuideView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // 아이폰용 RGB 그라데이션 배경
            if UIDevice.current.userInterfaceIdiom == .phone {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.6, blue: 1.0),
                        Color(red: 0.8, green: 0.4, blue: 1.0),
                        Color(red: 1.0, green: 0.6, blue: 0.8),
                        Color(red: 126/255, green: 98/255, blue: 214/255) // R126 G98 B214
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            ContentView()
                .environmentObject(appState)
        }
        .background(
            UIDevice.current.userInterfaceIdiom == .phone ? 
                Color.clear : 
                Color.white
        )
        .onChange(of: appState.currentProjectURL) { _, newURL in
            if let url = newURL {
                Task {
                    await loadProject(from: url)
                }
            }
        }
    }

    @MainActor
    private func loadProject(from url: URL) async {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let unzipFolder = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            print("📂 복원 시작: \(url.lastPathComponent)")
            try fileManager.createDirectory(at: unzipFolder, withIntermediateDirectories: true)

            let success = SSZipArchive.unzipFile(atPath: url.path, toDestination: unzipFolder.path)
            guard success else {
                print("❌ 압축 해제 실패: \(url.lastPathComponent)")
                return
            }

            let metaURL = unzipFolder.appendingPathComponent("meta.json")
            print("📄 meta.json 위치:", metaURL.path)

            let metaData = try Data(contentsOf: metaURL)
            let project = try JSONDecoder().decode(PunFunPhotoSaveData.self, from: metaData)

            let path1 = unzipFolder.appendingPathComponent(project.photo1.filePath)
            let path2 = unzipFolder.appendingPathComponent(project.photo2.filePath)

            print("🖼️ 복원 대상 이미지 파일:")
            print(" - photo1:", path1.lastPathComponent)
            print(" - photo2:", path2.lastPathComponent)

            if UIImage(contentsOfFile: path1.path) != nil {
                print("✅ photo1 복원 완료")
            } else {
                print("⚠️ photo1 이미지 로드 실패")
            }

            if UIImage(contentsOfFile: path2.path) != nil {
                print("✅ photo2 복원 완료")
            } else {
                print("⚠️ photo2 이미지 로드 실패")
            }

            print("🎉 전체 프로젝트 복원 완료: \(url.lastPathComponent)")
        } catch {
            print("❌ 프로젝트 복원 실패:", error.localizedDescription)
        }
    }
}
