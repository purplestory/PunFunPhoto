import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))  // 꼭짓점 (위)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // 오른쪽 아래
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // 왼쪽 아래
        path.closeSubpath()
        return path
    }
}
