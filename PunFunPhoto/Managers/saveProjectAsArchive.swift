import Foundation
import UIKit
import ZipArchive

func saveProjectAsArchive(photo1: PhotoState, photo2: PhotoState, fileName: String? = nil) -> URL? {
    guard let image1 = photo1.originalImage,
          let image2 = photo2.originalImage else {
        print("❌ 이미지가 없어 저장 불가")
        return nil
    }

    let baseName = fileName?.replacingOccurrences(of: ".pfp", with: "") ?? generateSaveFileName()
    let safeFileName = baseName + ".pfp"

    let tempDir = FileManager.default.temporaryDirectory
    let archiveFolder = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)

    do {
        try FileManager.default.createDirectory(at: archiveFolder, withIntermediateDirectories: true)

        let photo1URL = archiveFolder.appendingPathComponent("photo1.jpg")
        let photo2URL = archiveFolder.appendingPathComponent("photo2.jpg")
        try image1.jpegData(compressionQuality: 1.0)?.write(to: photo1URL)
        try image2.jpegData(compressionQuality: 1.0)?.write(to: photo2URL)

        let meta = PunFunPhotoSaveData(
            photo1: PunFunSavedPhotoData(
                filePath: "photo1.jpg",
                offset: CGPoint(x: photo1.offset.width, y: photo1.offset.height),
                scale: photo1.scale,
                coverScale: photo1.coverScale
            ),
            photo2: PunFunSavedPhotoData(
                filePath: "photo2.jpg",
                offset: CGPoint(x: photo2.offset.width, y: photo2.offset.height),
                scale: photo2.scale,
                coverScale: photo2.coverScale
            ),
            savedAt: Date()
        )

        let metaURL = archiveFolder.appendingPathComponent("meta.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        try encoder.encode(meta).write(to: metaURL)

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finalZipURL = documentsURL.appendingPathComponent(safeFileName)

        let success = SSZipArchive.createZipFile(
            atPath: finalZipURL.path,
            withContentsOfDirectory: archiveFolder.path
        )

        if success {
            print("✅ .pfp 저장 성공 → \(finalZipURL.lastPathComponent)")
            return finalZipURL
        } else {
            print("❌ .pfp 압축 실패")
            return nil
        }

    } catch {
        print("❌ 저장 중 오류:", error.localizedDescription)
        return nil
    }
}
