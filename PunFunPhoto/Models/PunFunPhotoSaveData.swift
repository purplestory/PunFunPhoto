import Foundation
import CoreGraphics

// MARK: - pfp 프로젝트 저장용 포토 상태 데이터 (offset은 CGPoint 기준)
struct PunFunSavedPhotoData: Codable {
    let filePath: String
    let offset: CGPoint
    let scale: CGFloat
    let coverScale: CGFloat
}

// MARK: - pfp 프로젝트 전체 저장용 데이터
struct PunFunPhotoSaveData: Codable {
    let photo1: PunFunSavedPhotoData
    let photo2: PunFunSavedPhotoData
    let savedAt: Date
}
