import SwiftUI

struct ToolbarMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let boxSize: CGFloat
    let action: () -> Void
    
    init(title: String, icon: String, boxSize: CGFloat = 44, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.boxSize = boxSize
        self.action = action
    }
    
    var accessibilityLabel: String {
        return "\(title) 버튼"
    }
    
    var accessibilityHint: String {
        return "탭하여 \(title) 실행"
    }
}
