import Foundation

/// 포토카드 관련 오류
enum PhotoCardError: Error, LocalizedError {
    case noPhotosSelected
    case unzipFailed
    case imageLoadFailed
    case exportFailed
    case saveFailed
    case importFailed
    case metadataLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .noPhotosSelected:
            return "사진을 먼저 선택해 주세요!"
        case .unzipFailed:
            return "프로젝트 파일을 열 수 없습니다."
        case .imageLoadFailed:
            return "이미지 파일을 불러올 수 없습니다."
        case .exportFailed:
            return "내보내기에 실패했습니다."
        case .saveFailed:
            return "저장에 실패했습니다."
        case .importFailed:
            return "파일을 불러오는데 실패했습니다."
        case .metadataLoadFailed:
            return "프로젝트 정보를 불러올 수 없습니다."
        }
    }
}
