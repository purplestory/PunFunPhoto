import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )

        // 아이패드에서의 팝오버 방향 설정 (중요)
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                popover.sourceView = keyWindow.rootViewController?.view
            }
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX,
                                        y: UIScreen.main.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        print("[DEBUG] ✅ ShareSheet 생성 완료: \(activityItems)")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 공유 시트는 초기화 이후 별도 업데이트가 필요 없음
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        func present(activityVC: UIActivityViewController, in viewController: UIViewController) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                keyWindow.rootViewController?.present(activityVC, animated: true, completion: nil)
            }
        }
    }
}
