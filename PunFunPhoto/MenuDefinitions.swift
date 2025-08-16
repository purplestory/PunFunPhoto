import SwiftUI
import UniformTypeIdentifiers

/// 메뉴 아이템
//struct MenuItem: Identifiable {
//    let id = UUID()
//    let title: String
//    let icon: String
//    let action: () -> Void
//    
//    var accessibilityLabel: String { title }
//    var accessibilityDescription: String { "선택하여 \(title) 실행" }
//}

/// 메뉴 타입
enum MenuType: Int, CaseIterable {
    case project = 0
    case photocard = 1
    case toploader = 2
    case view = 3
    case export = 4
    
    var title: String {
        switch self {
        case .project: return "프로젝트"
        case .photocard: return "포토카드"
        case .toploader: return "탑로더"
        case .view: return "보기"
        case .export: return "내보내기"
        }
    }
    
    var icon: String {
        switch self {
        case .project: return "doc.richtext"
        case .photocard: return "photo"
        case .toploader: return "square.on.square"
        case .view: return "eye"
        case .export: return "square.and.arrow.up"
        }
    }
    
    var offsetX: CGFloat {
        switch self {
        case .project: return 0
        case .photocard: return 100
        case .toploader: return 200
        case .view: return 300
        case .export: return 400
        }
    }
}

/// 메뉴 위치 정보
struct MenuPosition: Equatable {
    let type: MenuType
    let frame: CGRect
    let textFrame: CGRect
} 
