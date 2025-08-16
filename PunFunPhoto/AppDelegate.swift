import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("🌟 앱이 Foreground에 진입함")
    }

    func application(_ application: UIApplication,
                     open inputURL: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("📦 [TEST] AppDelegate open(_:url:) 호출됨") // 이게 안 찍히면 iOS가 호출 자체를 안 한 것임

        print("📦 외부에서 열려는 파일 URL:", inputURL)

        // ✅ 확장자 검사 (.pfp만 허용)
        guard inputURL.pathExtension.lowercased() == "pfp" else {
            print("❌ 지원하지 않는 파일 확장자입니다.")
            return false
        }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(inputURL.lastPathComponent)

        // ✅ 보안 스코프 접근
        let didStartScopedAccess = inputURL.startAccessingSecurityScopedResource()
        if didStartScopedAccess {
            print("🔐 보안 스코프 접근 시작됨")
        } else {
            print("⚠️ 보안 스코프 접근 실패 (iCloud 파일이 아닐 수도 있음)")
        }

        // ✅ 복사 작업
        do {
            // 중복 방지를 위해 기존 파일 제거
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
                print("🗑 기존 동일 이름 파일 삭제됨")
            }

            try fileManager.copyItem(at: inputURL, to: destinationURL)
            print("✅ 파일 복사 완료 → \(destinationURL.lastPathComponent)")

        } catch {
            print("❌ 파일 복사 실패:", error)
            if didStartScopedAccess {
                inputURL.stopAccessingSecurityScopedResource()
                print("🛑 보안 스코프 접근 해제됨 (복사 실패 후)")
            }
            return false
        }

        // ✅ 보안 스코프 해제는 복사 이후
        if didStartScopedAccess {
            inputURL.stopAccessingSecurityScopedResource()
            print("🛑 보안 스코프 접근 해제됨 (복사 이후)")
        }

        // ✅ 앱 내로 URL 전달
        DispatchQueue.main.async {
            print("📦 Notification 전달: \(destinationURL)")
            NotificationCenter.default.post(
                name: .didReceivePFPFile,
                object: destinationURL
            )
        }

        return true
    }
}
