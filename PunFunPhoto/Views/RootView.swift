import SwiftUI
import Foundation

extension Notification.Name {
    static let didReceivePFPFile = Notification.Name("didReceivePFPFile")
}

struct RootView: View {
    @State private var showSplash = true
    @StateObject private var appState = AppState() // ✅ 전역 상태 공유
    


    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
            } else {
                OrientationGuideView()
                    .environmentObject(appState)
            }
            
            // 통합된 토스트 메시지 (최상위 레벨)
            CenterToastView(message: appState.toastMessage, type: appState.toastType.toCenterToastType, isVisible: $appState.showToast)
                .offset(x: appState.isMenuOpen ? 80 : 0) // 메뉴가 열렸을 때 오른쪽으로 이동
                .onAppear {
                    print("[DEBUG] RootView - appState.isMenuOpen: \(appState.isMenuOpen)")
                }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceivePFPFile)) { notification in
            if let url = notification.object as? URL {
                print("📥 RootView에서 .pfp URL 수신:", url)
                appState.currentProjectURL = url
            }
        }
    }
}
