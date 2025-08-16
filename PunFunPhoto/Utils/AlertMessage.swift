import Foundation

struct AlertMessage: Identifiable {
    var id: String { message }
    let message: String
    let type: AlertType
    
    enum AlertType {
        case success
        case error
        case warning
        
        var iconName: String {
            switch self {
            case .success: return "checkmark.circle"
            case .error: return "exclamationmark.circle"
            case .warning: return "exclamationmark.triangle"
            }
        }
    }
    
    static func success(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .success)
    }
    
    static func error(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .error)
    }
    
    static func warning(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .warning)
    }
}
