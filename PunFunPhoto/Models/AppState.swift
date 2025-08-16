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
}
