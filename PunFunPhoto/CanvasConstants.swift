import CoreGraphics
import SwiftUI

struct CanvasConstants {
    /// 인쇄 및 렌더링 기준 크기 (화면에서 직접 사용하지 않음)
    static let canvasSize = CGSize(width: 1800, height: 1200) // 4R (152x102mm)
    static let photoBoxSize = CGSize(width: 662, height: 1039) // 개별 박스
    static let boxSpacing: CGFloat = 35.5 // 3mm 간격 (1800pt = 152mm 기준으로 계산)
    static let leftRightMargin: CGFloat = 214.5
    static let topBottomMargin: CGFloat = 80.5
    /// 이 값들은 화면 크기에 맞춰 비율(scaleFactor)을 계산하는 기준일 뿐,
    /// 실제 .frame(width:) 등의 고정 값으로 절대 사용하지 않는다.
}
