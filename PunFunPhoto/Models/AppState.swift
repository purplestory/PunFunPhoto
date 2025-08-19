import Foundation

final class AppState: ObservableObject {
    @Published var currentProjectURL: URL? = nil {
        didSet {
            print("📌 AppState - currentProjectURL 변경됨:")
            print("  이전 값: \(oldValue?.lastPathComponent ?? "nil")")
            print("  새 값: \(currentProjectURL?.lastPathComponent ?? "nil")")
            // 스택 트레이스 출력
            print("호출 스택:")
            Thread.callStackSymbols.forEach { print("  \($0)") }
        }
    }
    
    // 메뉴 상태 (전역 관리)
    @Published var isMenuOpen: Bool = false
    
    // 토스트 메시지 상태 (전역 관리)
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastType: AlertMessage.AlertType = .success
    
    // 토스트 메시지 표시 함수
    func showToastMessage(_ message: String, type: AlertMessage.AlertType = .success) {
        toastMessage = message
        toastType = type
        showToast = true
    }
}
