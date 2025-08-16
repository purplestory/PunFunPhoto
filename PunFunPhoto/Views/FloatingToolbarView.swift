import SwiftUI
import UniformTypeIdentifiers
import ZipArchive

/// 메뉴 아이템
struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var accessibilityLabel: String { title }
    var accessibilityDescription: String { "선택하여 \(title) 실행" }
}

// 메뉴 위치 정보를 위한 PreferenceKey
struct MenuPositionKey: PreferenceKey {
    static var defaultValue: [MenuPosition] = []
    static func reduce(value: inout [MenuPosition], nextValue: () -> [MenuPosition]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - FloatingToolbarView
/// 포토카드 편집을 위한 플로팅 툴바 뷰
struct FloatingToolbarView: View {
    // MARK: - Constants
    private let baseCanvasSize = CGSize(width: 1800, height: 1200)
    private let baseBoxSize = CGSize(width: 685, height: 1063)
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var appState: AppState
    @Binding var showSafeFrame: Bool
    @ObservedObject var photo1: PhotoState
    @ObservedObject var photo2: PhotoState
    @ObservedObject var topLoader1: TopLoaderState
    @ObservedObject var topLoader2: TopLoaderState
    @Binding var showPhotoPicker: Bool
    @Binding var photoPickerMode: PhotoPickerMode
    @Binding var showAlreadySelectedAlert: Bool
    @Binding var selectedMenu: MenuType?
    @Binding var showContextMenu: Bool
    @Binding var showTopLoader1ContextMenu: Bool?
    @Binding var showTopLoader2ContextMenu: Bool?
    var onMenuChange: (() -> Void)? = nil
    
    private var isLandscape: Bool {
        horizontalSizeClass == .regular
    }
    
    // MARK: - View States
    @State private var showProjectList = false
    @State private var showSavePrompt = false
    @State private var alertMessage: AlertMessage? = nil
    @State private var exportURL: URL? = nil
    @State private var showExportSheet = false
    @State private var exportData: Data? = nil
    @State private var showFileImporter = false
    @State private var showStickerLibrary = false
    @State private var showTextEditor = false
    @State private var menuPositions: [MenuPosition] = []
    @State private var toolbarFrame: CGRect = .zero
    @State private var showTopLoaderLibrary = false
    @State private var selectedPhotoForTopLoader: PhotoState? = nil
    @State private var menuWidth: CGFloat = 0
    @State private var submenuHeight: CGFloat = 0
    @State private var showToast = false
    @State private var toastMessage: String = ""
    @State private var toastType: AlertMessage.AlertType = .success
    
    private var toolbarHeight: CGFloat {
        44 + getSafeAreaInsets().top
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.clear
                    .overlay {
                        VStack(spacing: 0) {
                            // 상단 툴바
                            HStack(spacing: 20) {
                                ForEach(MenuType.allCases, id: \ .self) { menuType in
                                    toolbarButton(type: menuType)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ViewPreferenceKeys.ToolbarFrameKey.self, value: geo.frame(in: .global))
                                }
                            )
                            .background(Color(.systemBackground).opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                            .font(.system(size: 16, weight: .medium))
                            .frame(height: 44)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                        .padding(.top, getSafeAreaInsets().top)
                        // 서브메뉴는 overlay로 분리
                        .overlay(
                            Group {
                                if let selected = selectedMenu {
                                    GeometryReader { geo in
                                        let toolbarRect = toolbarFrame
                                        ZStack(alignment: .topLeading) {
                                            // 전체 화면 배경
                                            Color.black.opacity(0.001)
                                                .contentShape(Rectangle())
                                                .onTapGesture { 
                                                    withAnimation { 
                                                        selectedMenu = nil 
                                                    } 
                                                }
                                                .zIndex(99)
                                            
                                            // 서브메뉴: 상단 기준 offset 정렬
                                            menuOverlay(for: selected)
                                                .frame(width: 200)
                                                .background(
                                                    GeometryReader { geo in
                                                        Color.clear
                                                            .onAppear {
                                                                submenuHeight = geo.size.height
                                                            }
                                                    }
                                                )
                                                .offset(
                                                    x: toolbarFrame.minX + calculateSubmenuOffset(for: selected) + 35,
                                                    y: toolbarFrame.maxY - geo.frame(in: .global).minY + 70
                                                )
                                                .zIndex(100)
                                        }
                                    }
                                    .ignoresSafeArea()
                                    .zIndex(99)
                                }
                            }
                        )
                    }
                CenterToastView(message: toastMessage, type: toastType.toCenterToastType, isVisible: $showToast)
                    // .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .coordinateSpace(name: "CanvasSpace")
        .onPreferenceChange(MenuPositionKey.self) { (positions: [MenuPosition]) in
            menuPositions = positions
        }
        .onPreferenceChange(ViewPreferenceKeys.ToolbarFrameKey.self) { (frame: CGRect) in
            toolbarFrame = frame
        }
        .sheet(isPresented: $showProjectList) {
            SavedProjectListView(isPresented: $showProjectList, photo1: photo1, photo2: photo2)
        }
        .sheet(isPresented: $showSavePrompt) {
            SaveProjectPrompt(
                isPresented: $showSavePrompt,
                photo1: photo1,
                photo2: photo2
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                DocumentExporter(fileURL: url)
            } else {
                Text("내보낼 파일이 없습니다.")
                    .foregroundColor(.red)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.punfunProject],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await loadProjectManually(from: url)
                    }
                }
            case .failure(let error):
                showAlert("파일을 열 수 없습니다: \(error.localizedDescription)", type: .error)
            }
        }
        .sheet(isPresented: $showStickerLibrary) {
            StickerLibraryView { image in
                topLoader1.addSticker(image)
                topLoader2.addSticker(image)
            }
        }
        .sheet(isPresented: $showTextEditor) {
            TextStickerEditorView(isPresented: $showTextEditor) { data in
                topLoader1.addText(
                    data.text,
                    fontSize: data.fontSize,
                    textColor: data.textColor,
                    style: data.style,
                    strokeColor: data.strokeColor,
                    fontInfo: data.fontInfo,
                    highlightColor: data.highlightColor,
                    boxSize: baseBoxSize
                )
                topLoader2.addText(
                    data.text,
                    fontSize: data.fontSize,
                    textColor: data.textColor,
                    style: data.style,
                    strokeColor: data.strokeColor,
                    fontInfo: data.fontInfo,
                    highlightColor: data.highlightColor,
                    boxSize: baseBoxSize
                )
            }
        }
        .sheet(isPresented: $showTopLoaderLibrary) {
            TopLoaderLibraryView(isPresented: $showTopLoaderLibrary) { savedTopLoader in
                if let photo = selectedPhotoForTopLoader {
                    if photo === photo1 {
                        topLoader1.loadFrom(savedTopLoader)
                        topLoader1.attach()
                    } else if photo === photo2 {
                        topLoader2.loadFrom(savedTopLoader)
                        topLoader2.attach()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func toolbarButton(type: MenuType) -> some View {
        Button(action: {
            // 포토카드/탑로더 팝업 메뉴가 열린 상태에서 상단 메뉴를 터치하면 팝업 메뉴들 닫기
            showContextMenu = false
            showTopLoader1ContextMenu = nil
            showTopLoader2ContextMenu = nil
            
            // 다른 메뉴를 터치하면 기존 메뉴가 닫히면서 새 메뉴가 바로 열리도록
            if selectedMenu == type {
                selectedMenu = nil
            } else {
                selectedMenu = type
            }
            
            onMenuChange?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                Text(type.title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: MenuPositionKey.self, value: [MenuPosition(type: type, frame: geo.frame(in: .global), textFrame: geo.frame(in: .global))])
                }
            )
        }
        .accessibilityLabel(type.title)
        .accessibilityHint(selectedMenu == type ? "선택된 메뉴입니다. 다시 탭하여 닫을 수 있습니다." : "선택하여 \(type.title) 메뉴를 열 수 있습니다.")
    }
    
    private func menuOverlay(for menuType: MenuType) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(menuItems(for: menuType)) { item in
                Button(action: {
                    withAnimation {
                        item.action()
                        selectedMenu = nil
                        onMenuChange?()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(height: 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
                .disabled(!item.isEnabled)
            }
        }
        // .foregroundColor(selectedMenu == menuType ? .blue : .primary)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
    
    private func calculateSubmenuOffset(for menuType: MenuType) -> CGFloat {
        guard let menuPosition = menuPositions.first(where: { $0.type == menuType }) else {
            return 0
        }
        
        // 메뉴 텍스트의 첫 글자 x값 (global 좌표)
        let menuTextX = menuPosition.textFrame.minX
        let submenuPadding: CGFloat = 12
        let iconWidth: CGFloat = 24
        let iconSpacing: CGFloat = 8
        
        // global 좌표계에서 툴바의 위치를 고려하여 오프셋 계산
        let toolbarOriginX = toolbarFrame.minX
        
        // 서브메뉴 텍스트가 메뉴 텍스트와 정확히 정렬되도록 조정
        // submenuPadding + iconWidth + iconSpacing을 빼서 서브메뉴 텍스트의 시작점을 메뉴 텍스트와 맞춤
        let offset = menuTextX - toolbarOriginX - (submenuPadding + iconWidth + iconSpacing)
        
        print("[DEBUG] 📍 Submenu text alignment for \(menuType):")
        print("  - Menu text X (global): \(menuTextX)")
        print("  - Toolbar origin X (global): \(toolbarOriginX)")
        print("  - Icon width: \(iconWidth)")
        print("  - Icon spacing: \(iconSpacing)")
        print("  - Submenu padding: \(submenuPadding)")
        print("  - Calculated offset: \(offset)")
        
        return offset
    }
    
    // MARK: - Submenu Views
    private var projectMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(menuItems(for: .project)) { item in
                Button(action: {
                    withAnimation {
                        item.action()
                        openSubMenu(.project)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(height: 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
            }
        }
    }
    
    private var photocardMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(menuItems(for: .photocard)) { item in
                Button(action: {
                    withAnimation {
                        item.action()
                        openSubMenu(.photocard)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
            }
        }
    }
    
    private var toploaderMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(menuItems(for: .toploader)) { item in
                Button(action: {
                    withAnimation {
                        item.action()
                        openSubMenu(.toploader)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(height: 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
            }
        }
    }
    
    private var viewMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(menuItems(for: .view)) { item in
                Button(action: {
                    withAnimation {
                        item.action()
                        openSubMenu(.view)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(height: 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
            }
        }
    }
    
    private var exportMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(menuItems(for: .export)) { item in
                Button(action: {
                    withAnimation {
                        item.action()
                        openSubMenu(.export)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(height: 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
            }
        }
    }
    
    // MARK: - Menu Items
    private func menuItems(for menu: MenuType) -> [MenuItem] {
        switch menu {
        case .project:
            return [
                MenuItem(title: "새 프로젝트", icon: "doc.on.doc", action: clearPhotos),
                MenuItem(title: "프로젝트 열기", icon: "folder", action: { showProjectList = true }),
                MenuItem(title: "파일에서 직접 열기", icon: "folder.badge.plus", action: { showFileImporter = true }),
                MenuItem(title: "저장", icon: "square.and.arrow.down", action: saveProject),
                MenuItem(title: "새 이름으로 저장", icon: "square.and.pencil", action: saveAsProject)
            ]
        case .photocard:
            return [
                MenuItem(title: "사진 불러오기", icon: "photo.on.rectangle", action: handlePhotoImport),
                MenuItem(title: "편집 초기화", icon: "arrow.counterclockwise", action: resetEdits),
                MenuItem(title: "사진 복제", icon: "plus.square.on.square", action: { duplicatePhoto(from: photo1, to: photo2) }),
                MenuItem(title: "좌우 사진 바꾸기", icon: "arrow.left.arrow.right", action: swapPhotos)
            ]
        case .toploader:
            return [
                MenuItem(title: "왼쪽 탑로더 관리", icon: "square.grid.2x2", action: { showTopLoaderMenu(for: photo1) }),
                MenuItem(title: "오른쪽 탑로더 관리", icon: "square.grid.2x2", action: { showTopLoaderMenu(for: photo2) }),
                MenuItem(title: "탑로더 복제", icon: "square.on.square", action: { duplicateTopLoader(from: photo1, to: photo2) }),
                MenuItem(title: "탑로더 모두 제거", icon: "xmark.circle", action: {
                    topLoader1.detach()
                    topLoader2.detach()
                })
            ]
        case .view:
            let anyAttached = topLoader1.isAttached || topLoader2.isAttached
            let anyVisible = (topLoader1.isAttached && topLoader1.showTopLoader) || (topLoader2.isAttached && topLoader2.showTopLoader)
            let menuTitle: String
            let menuIcon: String
            let isEnabled: Bool = anyAttached
            if !anyAttached {
                menuTitle = "탑로더 없음"
                menuIcon = "eye.slash"
            } else if anyVisible {
                menuTitle = "탑로더 가리기"
                menuIcon = "eye.slash"
            } else {
                menuTitle = "탑로더 보기"
                menuIcon = "eye"
            }
            return [
                MenuItem(title: showSafeFrame ? "커팅선 가리기" : "커팅선 보기",
                        icon: "rectangle.dashed",
                        action: { showSafeFrame.toggle() }),
                MenuItem(title: menuTitle, icon: menuIcon, action: {
                    if anyAttached {
                        let newShow = !anyVisible
                        if topLoader1.isAttached { topLoader1.showTopLoader = newShow }
                        if topLoader2.isAttached { topLoader2.showTopLoader = newShow }
                        alertMessage = AlertMessage(message: newShow ? "탑로더가 보입니다." : "탑로더가 가려졌습니다.", type: .success)
                    }
                }, isEnabled: isEnabled)
            ]
        case .export:
            return [
                MenuItem(title: "바로 인쇄하기", icon: "printer", action: printPhotos),
                MenuItem(title: "사진으로 내보내기", icon: "photo", action: exportAsImage),
                MenuItem(title: "파일로 내보내기", icon: "tray.and.arrow.down", action: exportProjectFile)
            ]
        }
    }
    
    // MARK: - Actions
    private func showAlert(_ message: String, type: AlertMessage.AlertType = .success) {
        showCenterToast(message: message, type: type)
    }
    
    private func clearPhotos() {
        photo1.originalImage = nil
        photo2.originalImage = nil
        appState.currentProjectURL = nil
        print("[DEBUG] 새 프로젝트 초기화 완료")
    }
    
    private func resetEdits() {
        photo1.scale = 1.0
        photo1.offset = .zero
        photo2.scale = 1.0
        photo2.offset = .zero
        print("[DEBUG] 편집 상태 초기화 완료")
    }
    
    private func saveProject() {
        if let url = appState.currentProjectURL,
           FileManager.default.fileExists(atPath: url.path) {
            overwriteProject(at: url)
        } else {
            saveAsProject()
        }
    }
    
    private func saveAsProject() {
        do {
            try validatePhotos()
            showSavePrompt = true
        } catch PhotoCardError.noPhotosSelected {
            showAlert("사진을 먼저 선택해 주세요!", type: .warning)
        } catch {
            showAlert("저장 준비 중 오류가 발생했습니다.", type: .error)
        }
    }
    
    private func validatePhotos() throws {
        guard photo1.originalImage != nil || photo2.originalImage != nil else {
            throw PhotoCardError.noPhotosSelected
        }
    }
    
    private func overwriteProject(at url: URL) {
        print("💾 프로젝트 저장 시작: \(url.lastPathComponent)")
        let baseName = url.deletingPathExtension().lastPathComponent
        if let newURL = saveProjectAsArchive(photo1: photo1, photo2: photo2, fileName: baseName) {
            print("📍 프로젝트 URL 업데이트: \(newURL.path)")
            appState.currentProjectURL = newURL
            showAlert("기존 프로젝트에 저장되었습니다.")
        } else {
            showAlert("저장에 실패했습니다.", type: .error)
        }
    }
    
    private func exportAsImage() {
        do {
            try validatePhotos()
            let image = ExportManager.renderCombinedImage(photo1: photo1, photo2: photo2)
            ExportManager.saveToPhotos(image)
            showAlert("사진으로 저장되었습니다.")
        } catch {
            showAlert("포토카드가 없습니다.", type: .error)
        }
    }
    
    private func printPhotos() {
        do {
            try validatePhotos()
            let image = ExportManager.renderCombinedImage(photo1: photo1, photo2: photo2)
            PhotoExportHelper.printImage(image)
        } catch {
            showAlert("포토카드가 없습니다.", type: .error)
        }
    }
    
    private func exportProjectFile() {
        do {
            try validatePhotos()
            let fileName = generateSaveFileName()
            if let tempURL = saveProjectAsArchive(photo1: photo1, photo2: photo2, fileName: fileName) {
                exportURL = tempURL
                showExportSheet = true
            } else {
                throw PhotoCardError.exportFailed
            }
        } catch {
            showAlert("포토카드가 없습니다.", type: .error)
        }
    }
    
    private func duplicatePhoto(from: PhotoState, to: PhotoState) {
        guard let image = from.originalImage else { return }
        to.originalImage = UIImage(data: image.pngData() ?? Data())
        to.scale = from.scale
        to.offset = from.offset
        to.coverScale = from.coverScale
    }
    
    private func swapPhotos() {
        let tempPhoto = PhotoState()
        duplicatePhoto(from: photo1, to: tempPhoto)
        duplicatePhoto(from: photo2, to: photo1)
        duplicatePhoto(from: tempPhoto, to: photo2)
    }
    
    private func duplicateTopLoader(from: PhotoState, to: PhotoState) {
        let fromLoader = getTopLoaderState(for: from)
        let toLoader = getTopLoaderState(for: to)
        toLoader.copyFrom(fromLoader)
        toLoader.attach()
    }
    
    private func showTopLoaderMenu(for photo: PhotoState) {
        selectedPhotoForTopLoader = photo
        showTopLoaderLibrary = true
    }
    
    // MARK: - Project Loading
    @MainActor
    private func loadProjectManually(from url: URL) async {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let unzipFolder = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: unzipFolder, withIntermediateDirectories: true)
            
            // 보안 접근 시작
            let didStartScopedAccess = url.startAccessingSecurityScopedResource()
            print("📂 프로젝트 파일 접근 시작: \(url.lastPathComponent)")
            
            defer {
                if didStartScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                    print("🔓 보안 접근 해제됨")
                }
            }
            
            guard SSZipArchive.unzipFile(atPath: url.path, toDestination: unzipFolder.path) else {
                throw PhotoCardError.unzipFailed
            }
            
            let metaURL = unzipFolder.appendingPathComponent("meta.json")
            let metaData = try Data(contentsOf: metaURL)
            let project = try JSONDecoder().decode(PunFunPhotoSaveData.self, from: metaData)
            
            let path1 = unzipFolder.appendingPathComponent(project.photo1.filePath)
            let path2 = unzipFolder.appendingPathComponent(project.photo2.filePath)
            
            guard let image1 = UIImage(contentsOfFile: path1.path),
                  let image2 = UIImage(contentsOfFile: path2.path) else {
                throw PhotoCardError.noPhotosSelected
            }
            
            // 상태 업데이트
            photo1.setImage(image1, boxSize: CGSize(width: 44, height: 44))
            photo1.offset = CGSize(width: project.photo1.offset.x, height: project.photo1.offset.y)
            photo1.scale = project.photo1.scale
            photo1.coverScale = project.photo1.coverScale
            
            photo2.setImage(image2, boxSize: CGSize(width: 44, height: 44))
            photo2.offset = CGSize(width: project.photo2.offset.x, height: project.photo2.offset.y)
            photo2.scale = project.photo2.scale
            photo2.coverScale = project.photo2.coverScale
            
            // URL을 Documents 디렉토리로 복사
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
            
            // 기존 파일이 있다면 제거
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // 파일 복사
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // URL 업데이트
            print("📍 프로젝트 URL 업데이트: \(destinationURL.path)")
            appState.currentProjectURL = destinationURL
            
            showAlert("프로젝트를 열었습니다.")
            
        } catch PhotoCardError.unzipFailed {
            showAlert("프로젝트 파일을 열 수 없습니다.", type: .error)
        } catch PhotoCardError.noPhotosSelected {
            showAlert("이미지 파일을 불러올 수 없습니다.", type: .error)
        } catch {
            print("❌ 프로젝트 로드 오류: \(error.localizedDescription)")
            showAlert("프로젝트를 여는 중 오류가 발생했습니다: \(error.localizedDescription)", type: .error)
        }
        
        // 임시 폴더 정리
        try? fileManager.removeItem(at: unzipFolder)
    }
    
    // MARK: - Computed Properties
    private var currentProjectName: String {
        if let url = appState.currentProjectURL {
            return url.deletingPathExtension().lastPathComponent
        }
        return "새 프로젝트"
    }
    
    // MARK: - Helper Methods
    private func getSafeAreaInsets() -> EdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return EdgeInsets()
        }
        let insets = keyWindow.safeAreaInsets
        return EdgeInsets(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
    
    private func getTopLoaderState(for photo: PhotoState) -> TopLoaderState {
        if photo === photo1 {
            return topLoader1
        } else {
            return topLoader2
        }
    }
    
    private func handlePhotoImport() {
        let emptyCount = [photo1.originalImage, photo2.originalImage].filter { $0 == nil }.count
        if emptyCount == 0 {
            // [4] 토스트로 안내
            showCenterToast(message: "모든 포토박스가 이미 채워져 있습니다.", type: .warning)
        } else {
            photoPickerMode = (emptyCount == 2) ? .전체 : .비어있는
            showPhotoPicker = true
        }
    }
    
    // [5] 토스트 표시 함수
    private func showCenterToast(message: String, type: AlertMessage.AlertType = .success) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    // 서브메뉴를 여는 액션이 발생할 때마다
    private func openSubMenu(_ menuType: MenuType) {
        selectedMenu = menuType
        onMenuChange?()
    }
}

// MARK: - Preview
struct FloatingToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingToolbarView(
            showSafeFrame: .constant(true),
            photo1: PhotoState(),
            photo2: PhotoState(),
            topLoader1: TopLoaderState(),
            topLoader2: TopLoaderState(),
            showPhotoPicker: .constant(false),
            photoPickerMode: .constant(.전체),
            showAlreadySelectedAlert: .constant(false),
            selectedMenu: .constant(nil),
            showContextMenu: .constant(false),
            showTopLoader1ContextMenu: .constant(nil),
            showTopLoader2ContextMenu: .constant(nil)
        )
        .environmentObject(AppState())
    }
}

// [1] 타입 변환 extension 추가
extension AlertMessage.AlertType {
    var toCenterToastType: CenterToastView.AlertType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        }
    }
}
