import Foundation
import UIKit
import ZipArchive


/// `.pfp` 프로젝트 압축 파일을 로드하여 PhotoState에 복원합니다.
/// - Parameters:
///   - url: 압축 파일 경로 (.pfp)
///   - photo1: 복원 대상 PhotoState 1
///   - photo2: 복원 대상 PhotoState 2
func loadProjectFromArchive(from url: URL, photo1: PhotoState, photo2: PhotoState) {
    let tempDir = FileManager.default.temporaryDirectory
    let unzipFolder = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)

    do {
        try FileManager.default.createDirectory(at: unzipFolder, withIntermediateDirectories: true)

        // 1. 압축 해제
        let unzipSuccess = SSZipArchive.unzipFile(atPath: url.path, toDestination: unzipFolder.path)
        guard unzipSuccess else {
            print("❌ 압축 해제 실패")
            return
        }

        // 2. meta.json 로드 및 디코딩
        let metaURL = unzipFolder.appendingPathComponent("meta.json")
        let metaData = try Data(contentsOf: metaURL)
        let decoded = try JSONDecoder().decode(PunFunPhotoSaveData.self, from: metaData)

        // 3. 각 이미지 로드 및 상태 복원
        let photo1Path = unzipFolder.appendingPathComponent(decoded.photo1.filePath)
        let photo2Path = unzipFolder.appendingPathComponent(decoded.photo2.filePath)

        if let image1 = UIImage(contentsOfFile: photo1Path.path) {
            photo1.originalImage = image1
            photo1.offset = CGSize(width: decoded.photo1.offset.x, height: decoded.photo1.offset.y) // ✅ 변환 완료
            photo1.scale = decoded.photo1.scale
            photo1.coverScale = decoded.photo1.coverScale
        } else {
            print("⚠️ photo1 이미지 로딩 실패: \(photo1Path.path)")
        }

        if let image2 = UIImage(contentsOfFile: photo2Path.path) {
            photo2.originalImage = image2
            photo2.offset = CGSize(width: decoded.photo2.offset.x, height: decoded.photo2.offset.y) // ✅ 변환 완료
            photo2.scale = decoded.photo2.scale
            photo2.coverScale = decoded.photo2.coverScale
        } else {
            print("⚠️ photo2 이미지 로딩 실패: \(photo2Path.path)")
        }

        print("✅ 프로젝트 로드 완료: \(url.lastPathComponent)")

    } catch {
        print("❌ 프로젝트 로딩 중 오류:", error)
    }
}
