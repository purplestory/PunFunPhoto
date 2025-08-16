import SwiftUI

struct PhotoBoxScanHighlight: View {
    var size: CGSize
    var cornerRadius: CGFloat = 10
    
    @State private var trimEnd: CGFloat = 0.0
    @State private var animate = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .trim(from: 0, to: trimEnd)
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            .shadow(color: Color.blue.opacity(0.5), radius: 8)
            .frame(width: size.width, height: size.height)
            .onAppear {
                trimEnd = 0.0
                withAnimation(Animation.easeOut(duration: 1.0)) {
                    trimEnd = 1.0
                }
            }
    }
}
