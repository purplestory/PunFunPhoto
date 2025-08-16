import SwiftUI

struct CanvasGridOverlay: View {
    let canvasSize: CGSize      // 실제 캔버스 크기 (예: 1800 x 1200pt)
    let scaleFactor: CGFloat    // 현재 화면상에 적용된 스케일 비율
    let debugMode: Bool         // 디버깅 모드에서만 표시 여부
    
    var body: some View {
        GeometryReader { geo in
            // 디버그용 그리드 제거
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}
