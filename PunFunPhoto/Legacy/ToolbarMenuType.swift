import SwiftUI

enum ToolbarMenuType: String, CaseIterable {
    case project = "프로젝트"
    case edit = "편집"
    case view = "보기"
    case export = "내보내기"
    
    var icon: String {
        switch self {
        case .project: return "folder"
        case .edit: return "pencil"
        case .view: return "eye"
        case .export: return "square.and.arrow.up"
        }
    }
    
    var offsetX: CGFloat {
        switch self {
        case .project: return -10
        case .edit: return -10
        case .view: return -10
        case .export: return -10
        }
    }
}
