import SwiftUI

// MARK: - 포토박스 상태 저장용 클래스
final class PhotoState: ObservableObject {
    @Published var originalImage: UIImage? = nil
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var coverScale: CGFloat = 1.0

    // 이미지 설정 + 기본값 초기화
    func setImage(_ image: UIImage, boxSize: CGSize) {
        originalImage = image
        scale = 1.0
        offset = .zero
        coverScale = calculateCoverScale(for: image.size, boxSize: boxSize)

        print("--- DEBUG: PhotoState.setImage ---")
        print("original image size: \(image.size)")
        print("coverScale (cover-fit): \(coverScale)")
        print("scale set to 1.0, offset set to .zero")
        print("-------------------------------")
    }

    // 편집값 초기화
    func reset() {
        scale = 1.0
        offset = .zero
    }

    // 줌 비율 제한
    func clampScale(to value: CGFloat, min: CGFloat, max: CGFloat) {
        scale = Swift.min(Swift.max(value, min), max)
    }

    // cover-fit 기준 스케일 계산
    private func calculateCoverScale(for imageSize: CGSize, boxSize: CGSize) -> CGFloat {
        let widthRatio = boxSize.width / imageSize.width
        let heightRatio = boxSize.height / imageSize.height
        return max(widthRatio, heightRatio)
    }

//    // ✅ [새로 추가] 상태 복원 ← PhotoBoxSaveData (공유 복원용)
//    func restore(from data: PunFunSavedPhotoData) {
//        self.originalImage = data.image
//        self.scale = data.scale
//        self.offset = data.offset
//        self.coverScale = data.coverScale
//    }
}

// MARK: - 저장 및 불러오기
extension PhotoState {
    // 상태 저장 → SavedPhotoData + 이미지 파일
    func saveState(to name: String) -> SavedPhotoData? {
        guard let image = originalImage else { return nil }
        guard let url = saveImageToDocuments(image, name: name) else { return nil }

        return SavedPhotoData(
            filePath: url.lastPathComponent,
            offset: self.offset,
            scale: self.scale,
            coverScale: self.coverScale
        )
    }

    // 상태 복원 ← SavedPhotoData
    func loadState(from data: PunFunSavedPhotoData) {
        if let image = UIImage(contentsOfFile: data.filePath) {
            self.originalImage = image
            self.offset = CGSize(width: data.offset.x, height: data.offset.y)
            self.scale = data.scale
            self.coverScale = data.coverScale
        } else {
            print("⚠️ 저장된 이미지 파일을 불러올 수 없습니다.")
        }
    }
}

// MARK: - 이미지 파일 저장 헬퍼
func saveImageToDocuments(_ image: UIImage, name: String) -> URL? {
    guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }

    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsURL.appendingPathComponent("\(name).jpg")

    do {
        try data.write(to: fileURL)
        return fileURL
    } catch {
        print("❌ 이미지 저장 실패:", error)
        return nil
    }
}
