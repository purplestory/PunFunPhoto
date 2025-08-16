import Foundation

enum FontCategory: String, Codable {
    case system = "시스템"
    case gothic = "고딕"
    case myungjo = "명조"
    case handwriting = "손글씨"
    case display = "디스플레이"
    case pixel = "픽셀"
    
    var displayName: String { rawValue }
}

struct FontInfo: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let downloadUrl: String
    let previewUrl: String
    let fileSize: Int64
    let category: FontCategory
    var lastUsedDate: Date?
    
    static func == (lhs: FontInfo, rhs: FontInfo) -> Bool {
        lhs.id == rhs.id
    }
}

enum FontError: LocalizedError {
    case invalidUrl
    case downloadFailed
    case saveFailed
    case registrationFailed
    case deleteFailed
    case networkError
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "잘못된 폰트 URL입니다"
        case .downloadFailed:
            return "폰트 다운로드에 실패했습니다"
        case .saveFailed:
            return "폰트 파일 저장에 실패했습니다"
        case .registrationFailed:
            return "폰트 등록에 실패했습니다"
        case .deleteFailed:
            return "폰트 삭제에 실패했습니다"
        case .networkError:
            return "네트워크 연결을 확인해주세요"
        case .cacheError:
            return "캐시 처리 중 오류가 발생했습니다"
        }
    }
}

enum FontLoadingState {
    case notLoaded
    case loading(Double)
    case loaded
    case error(Error)
} 