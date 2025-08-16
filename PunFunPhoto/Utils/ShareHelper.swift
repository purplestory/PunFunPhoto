import UIKit

enum ShareHelper {
    static func presentShareSheet(for fileURL: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        // iPad 대응: popover 설정
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootVC = window.rootViewController {

            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )

            // 이미 어떤 VC가 떠 있다면 먼저 닫고 공유 시트 띄우기
            if let presented = rootVC.presentedViewController {
                print("[DEBUG] 기존 VC 닫기 후 공유 시도")
                presented.dismiss(animated: false) {
                    rootVC.present(activityVC, animated: true)
                    print("[DEBUG] ✅ 공유 시트 표시됨: \(fileURL.lastPathComponent)")
                }
            } else {
                rootVC.present(activityVC, animated: true)
                print("[DEBUG] ✅ 공유 시트 표시됨: \(fileURL.lastPathComponent)")
            }

        } else {
            print("❌ 공유 실패: RootViewController 없음 또는 Scene 비활성")
        }
    }
}
