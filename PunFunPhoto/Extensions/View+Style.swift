import SwiftUI

public extension View {
    func punFunFloatingMenuStyle() -> some View {
        self
            .background(Color(.systemBackground).opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            // .shadow(color: Color.black.opacity(0.1), radius: 6)
    }
} 