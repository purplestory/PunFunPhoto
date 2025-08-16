// AutoSaveManager.swift
import SwiftUI

// 2. 자동 저장 함수
func autoSaveCurrentProject(
    photo1: PhotoState,
    photo2: PhotoState,
    topLoader1: TopLoaderState,
    topLoader2: TopLoaderState
) {
    guard let p1 = photo1.saveState(to: "auto1"),
          let p2 = photo2.saveState(to: "auto2") else { return }

    // SavedPhotoData → PunFunSavedPhotoData 변환
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

    // 프로젝트 데이터 생성
    let project = PunFunPhotoSaveData(
        photo1: punfunPhoto1,
        photo2: punfunPhoto2,
        savedAt: Date()
    )
    
    // 탑로더 상태를 별도의 파일로 저장
    let topLoaderData = [
        "topLoader1": topLoader1.toSavedTopLoader(),
        "topLoader2": topLoader2.toSavedTopLoader()
    ]
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    guard let projectData = try? encoder.encode(project),
          let topLoaderData = try? encoder.encode(topLoaderData) else { return }

    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let projectURL = documentsURL.appendingPathComponent("autosave.pfp")
    let topLoaderURL = documentsURL.appendingPathComponent("autosave_toploaders.json")

    try? projectData.write(to: projectURL)
    try? topLoaderData.write(to: topLoaderURL)
    print("💾 자동 저장 완료 (포토카드 및 탑로더 상태)")
}

// 3. 앱 시작 시 자동 복원 함수
func tryLoadAutoSavedProject(
    photo1: PhotoState,
    photo2: PhotoState,
    topLoader1: TopLoaderState,
    topLoader2: TopLoaderState
) {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let projectURL = documentsURL.appendingPathComponent("autosave.pfp")
    let topLoaderURL = documentsURL.appendingPathComponent("autosave_toploaders.json")

    // 프로젝트 파일이 존재하면 로드
    if FileManager.default.fileExists(atPath: projectURL.path) {
        loadProjectFromArchive(
            from: projectURL,
            photo1: photo1,
            photo2: photo2
        )
        
        // 탑로더 상태 복원
        if FileManager.default.fileExists(atPath: topLoaderURL.path),
           let topLoaderData = try? Data(contentsOf: topLoaderURL),
           let topLoaderStates = try? JSONDecoder().decode([String: SavedTopLoader].self, from: topLoaderData) {
            
            if let state1 = topLoaderStates["topLoader1"] {
                topLoader1.loadFrom(state1)
            }
            if let state2 = topLoaderStates["topLoader2"] {
                topLoader2.loadFrom(state2)
            }
        }
        
        print("✅ 자동 저장된 프로젝트 불러오기 완료 (포토카드 및 탑로더 상태)")
    }
}
