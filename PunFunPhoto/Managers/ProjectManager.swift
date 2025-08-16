// ProjectManager.swift
import UIKit
import ZipArchive


// MARK: - 자동 파일명 생성 (pfoca_yyyyMMdd_HHmm.pfp)
func generateSaveFileName() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmm"
    let timestamp = formatter.string(from: Date())
    return "pfoca_\(timestamp).pfp"
}

// MARK: - 자동 저장 (타임스탬프 기반)
func saveProject(photo1: PhotoState, photo2: PhotoState) -> URL? {
    guard let p1 = photo1.saveState(to: "photo1"),
          let p2 = photo2.saveState(to: "photo2") else { return nil }

    // ✅ 변환
    let punfunPhoto1 = PunFunSavedPhotoData(
        filePath: p1.filePath,
        offset: CGPoint(x: p1.offset.width, y: p1.offset.height),
        scale: p1.scale,
        coverScale: p1.coverScale
    )
    let punfunPhoto2 = PunFunSavedPhotoData(
        filePath: p2.filePath,
        offset: CGPoint(x: p2.offset.width, y: p2.offset.height),
        scale: p2.scale,
        coverScale: p2.coverScale
    )

    let project = PunFunPhotoSaveData(photo1: punfunPhoto1, photo2: punfunPhoto2, savedAt: Date())
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    guard let data = try? encoder.encode(project) else { return nil }

    let fileName = generateSaveFileName()
    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(fileName)

    do {
        try data.write(to: fileURL)
        print("✅ 저장 완료: \(fileURL.lastPathComponent)")
        return fileURL
    } catch {
        print("❌ 저장 실패:", error)
        return nil
    }
}

// MARK: - 사용자 지정 이름으로 저장 (입력값 기반)
func saveProjectWithName(_ name: String, photo1: PhotoState, photo2: PhotoState) {
    guard let p1 = photo1.saveState(to: "photo1"),
          let p2 = photo2.saveState(to: "photo2") else { return }

    // ✅ 변환
    let punfunPhoto1 = PunFunSavedPhotoData(
        filePath: p1.filePath,
        offset: CGPoint(x: p1.offset.width, y: p1.offset.height),
        scale: p1.scale,
        coverScale: p1.coverScale
    )
    let punfunPhoto2 = PunFunSavedPhotoData(
        filePath: p2.filePath,
        offset: CGPoint(x: p2.offset.width, y: p2.offset.height),
        scale: p2.scale,
        coverScale: p2.coverScale
    )

    let project = PunFunPhotoSaveData(photo1: punfunPhoto1, photo2: punfunPhoto2, savedAt: Date())
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    guard let data = try? encoder.encode(project) else { return }

    let safeName = name.replacingOccurrences(of: "/", with: "_")
    let fileName = safeName.hasSuffix(".pfp") ? safeName : "\(safeName).pfp"

    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(fileName)

    do {
        try data.write(to: fileURL)
        print("✅ 사용자 지정 이름으로 저장 완료: \(fileName)")
    } catch {
        print("❌ 사용자 지정 저장 실패:", error)
    }
}

// MARK: - 프로젝트 불러오기
func loadProject(from url: URL, photo1: PhotoState, photo2: PhotoState) {
    let tempDir = FileManager.default.temporaryDirectory
    let unzipFolder = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)

    do {
        try FileManager.default.createDirectory(at: unzipFolder, withIntermediateDirectories: true)

        let success = SSZipArchive.unzipFile(atPath: url.path, toDestination: unzipFolder.path)
        guard success else {
            print("❌ 압축 해제 실패")
            return
        }

        let metaURL = unzipFolder.appendingPathComponent("meta.json")
        let metaData = try Data(contentsOf: metaURL)
        let decoded = try JSONDecoder().decode(PunFunPhotoSaveData.self, from: metaData)

        let photo1Path = unzipFolder.appendingPathComponent(decoded.photo1.filePath)
        let photo2Path = unzipFolder.appendingPathComponent(decoded.photo2.filePath)

        if let image1 = UIImage(contentsOfFile: photo1Path.path) {
            photo1.originalImage = image1
            photo1.offset = CGSize(width: decoded.photo1.offset.x, height: decoded.photo1.offset.y)
            photo1.scale = decoded.photo1.scale
            photo1.coverScale = decoded.photo1.coverScale
        }

        if let image2 = UIImage(contentsOfFile: photo2Path.path) {
            photo2.originalImage = image2
            photo2.offset = CGSize(width: decoded.photo2.offset.x, height: decoded.photo2.offset.y)
            photo2.scale = decoded.photo2.scale
            photo2.coverScale = decoded.photo2.coverScale
        }

        print("✅ 프로젝트 복원 완료")
    } catch {
        print("❌ 프로젝트 로딩 실패:", error)
    }
}

// MARK: - 저장된 프로젝트 목록 불러오기
func listSavedProjects() -> [URL] {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

    guard let contents = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) else {
        return []
    }

    return contents
        .filter { $0.pathExtension == "pfp" }
        .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
}
