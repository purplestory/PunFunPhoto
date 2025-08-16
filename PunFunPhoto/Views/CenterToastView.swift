import SwiftUI

struct CenterToastView: View {
    let message: String
    let type: AlertType
    @Binding var isVisible: Bool

    enum AlertType {
        case success, error, warning
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(.infinity)
                .shadow(radius: 10)
                Spacer()
            }
            .transition(.opacity)
            .animation(.easeInOut, value: isVisible)
            .zIndex(9999)
        }
    }
    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    private var iconColor: Color {
        switch type {
        case .success: return .green
        case .error: return .red
        case .warning: return .yellow
        }
    }
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6).opacity(0.95) : Color(.black).opacity(0.85)
    }
    private var textColor: Color {
        colorScheme == .dark ? .black : .white
    }
} 