import SwiftUI

struct FloatingMenuStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func floatingMenuStyle() -> some View {
        self.modifier(FloatingMenuStyle())
    }
}
