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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
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
    var onClosePopupMenus: (() -> Void)? = nil

    
    init(
        showSafeFrame: Binding<Bool>,
        photo1: PhotoState,
        photo2: PhotoState,
        topLoader1: TopLoaderState,
        topLoader2: TopLoaderState,
        showPhotoPicker: Binding<Bool>,
        photoPickerMode: Binding<PhotoPickerMode>,
        showAlreadySelectedAlert: Binding<Bool>,
        selectedMenu: Binding<MenuType?>,
        showContextMenu: Binding<Bool>,
        showTopLoader1ContextMenu: Binding<Bool?>,
        showTopLoader2ContextMenu: Binding<Bool?>,
        onMenuChange: (() -> Void)? = nil,
        onClosePopupMenus: (() -> Void)? = nil

    ) {
        self._showSafeFrame = showSafeFrame
        self.photo1 = photo1
        self.photo2 = photo2
        self.topLoader1 = topLoader1
        self.topLoader2 = topLoader2
        self._showPhotoPicker = showPhotoPicker
        self._photoPickerMode = photoPickerMode
        self._showAlreadySelectedAlert = showAlreadySelectedAlert
        self._selectedMenu = selectedMenu
        self._showContextMenu = showContextMenu
        self._showTopLoader1ContextMenu = showTopLoader1ContextMenu
        self._showTopLoader2ContextMenu = showTopLoader2ContextMenu
        self.onMenuChange = onMenuChange
        self.onClosePopupMenus = onClosePopupMenus
        print("[DEBUG] FloatingToolbarView init - onClosePopupMenus 콜백 저장됨: \(onClosePopupMenus != nil)")
    }
    
    /// 가이드에 따른 완벽한 반응형 디자인 감지
    private var isLandscape: Bool {
        horizontalSizeClass == .regular
    }
    
    /// 가이드에 따른 디바이스 타입 감지
    private var isMobile: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    private var isTablet: Bool {
        horizontalSizeClass == .regular || (horizontalSizeClass == .compact && verticalSizeClass == .compact)
    }
    
    /// 가이드에 따른 동적 레이아웃 계산
    /// 디바이스 타입에 따라 자동 최적화
    private var dynamicSpacing: CGFloat {
        if isMobile {
            return 24 // 아이폰: 적당한 간격
        } else {
            return 80 // 아이패드: 넉넉한 간격
        }
    }
    
    private var dynamicPadding: CGFloat {
        if isMobile {
            return 10 // 아이폰: 컴팩트한 패딩
        } else {
            return 20 // 아이패드: 넉넉한 패딩
        }
    }
    
    private var dynamicFontSize: CGFloat {
        if isMobile {
            return 15 // 아이폰: 작은 폰트
        } else {
            return 16 // 아이패드: 큰 폰트
        }
    }
    
    /// 드롭다운 메뉴와 툴바 사이 간격 (디바이스별 최적화)
    private var dropdownSpacing: CGFloat {
        if isMobile {
            return 46 // 아이폰: 적당한 간격
        } else {
            return 69 // 아이패드: 넉넉한 간격
        }
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
    
    /// 가이드에 따른 완벽한 툴바 컨텐츠 구현
    /// 완벽한 반응형 디자인과 접근성을 제공
    private var toolbarContent: some View {
        VStack(spacing: 0) {
            // 가이드에 따른 완벽한 상단 툴바
            HStack(spacing: dynamicSpacing) {
                ForEach(MenuType.allCases, id: \.self) { menuType in
                    toolbarButton(menuType: menuType)
                }
            }
            .padding(.horizontal, dynamicPadding)
            .padding(.vertical, 8)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ViewPreferenceKeys.ToolbarFrameKey.self, value: geo.frame(in: .global))
                }
            )
            .background(
                Color(.systemBackground)
                    .opacity(0.95)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 50, style: .continuous)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
            )
            .font(.system(size: dynamicFontSize, weight: .medium))
            .frame(height: 44)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, getSafeAreaInsets().top)
        .overlay(submenuOverlay)
    }
    
    /// 가이드에 따른 완벽한 드롭다운 메뉴 오버레이
    /// 완벽한 정렬과 반응형 디자인을 구현
    private var submenuOverlay: some View {
        Group {
            if let selected = selectedMenu {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: dropdownSpacing) // 툴바 높이만큼 여백 + 25픽셀 추가
                    
                    // 정확한 메뉴 위치에 드롭다운 배치
                    HStack {
                        Spacer()
                            .frame(width: getExactMenuOffset(for: selected))
                        
                        menuOverlay(for: selected)
                            .fixedSize(horizontal: true, vertical: false)
                            .zIndex(100)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: selected)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.clear
                    .overlay {
                        toolbarContent
                    }
                CenterToastView(message: toastMessage, type: toastType.toCenterToastType, isVisible: $showToast)
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
    /// 가이드에 따른 완벽한 툴바 버튼 구현
    /// - Parameter menuType: 메뉴 타입
    /// - Returns: 완벽한 정렬과 토글 기능을 가진 버튼
    private func toolbarButton(menuType: MenuType) -> some View {
        Button(action: {
            print("[DEBUG] 🎯 가이드 기반 메뉴 토글 - '\(menuType.title)' 터치됨")
            print("[DEBUG] 📊 터치 전 상태 - selectedMenu: \(selectedMenu?.title ?? "nil")")
            
            // 가이드에 따른 완벽한 메뉴 토글 시스템
            if selectedMenu == menuType {
                // 같은 메뉴를 터치하면 닫기
                selectedMenu = nil
                print("[DEBUG] ✅ 메뉴 '\(menuType.title)' 닫힘")
            } else {
                // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                selectedMenu = menuType
                print("[DEBUG] ✅ 메뉴 '\(menuType.title)' 열림")
            }
            
            // 가이드에 따른 메뉴 변경 콜백
            onMenuChange?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: menuType.icon)
                    .font(.system(size: 16))
                Text(menuType.title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, isMobile ? 14 : 20)
            .contentShape(Rectangle())
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: MenuPositionKey.self, value: [MenuPosition(type: menuType, frame: geo.frame(in: .global), textFrame: geo.frame(in: .global))])
                        .onAppear {
                            print("[DEBUG] 📍 메뉴 위치 정보 수집 - \(menuType): \(geo.frame(in: .global))")
                        }
                        .onChange(of: geo.frame(in: .global)) { newFrame in
                            print("[DEBUG] 📍 메뉴 위치 변경 - \(menuType): \(newFrame)")
                        }
                        .id("menu-\(menuType.rawValue)") // 고유 ID로 정확한 위치 추적
                }
            )
        }
        // 가이드에 따른 완벽한 접근성 지원
        .accessibilityLabel(menuType.title)
        .accessibilityHint(selectedMenu == menuType ? "선택된 메뉴입니다. 다시 탭하여 닫을 수 있습니다." : "선택하여 \(menuType.title) 메뉴를 열 수 있습니다.")
        .accessibilityValue(selectedMenu == menuType ? "열림" : "닫힘")
    }
    
    /// 가이드에 따른 완벽한 메뉴 오버레이 구현
    /// - Parameter menuType: 메뉴 타입
    /// - Returns: 완벽한 스타일과 접근성을 가진 메뉴 오버레이
    private func menuOverlay(for menuType: MenuType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(menuItems(for: menuType)) { item in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        item.action()
                        selectedMenu = nil
                        onMenuChange?()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .imageScale(.medium)
                            .frame(width: 24)
                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityHint(item.accessibilityDescription)
                .disabled(!item.isEnabled)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    /// 정확한 메뉴 위치 계산 (실제 버튼 위치 기반)
    /// - Parameter menuType: 정렬할 메뉴 타입
    /// - Returns: 정확한 오프셋 값
    private func getExactMenuOffset(for menuType: MenuType) -> CGFloat {
        // 실제 메뉴 위치 정보 사용
        guard let menuPosition = menuPositions.first(where: { $0.type == menuType }) else {
            print("[DEBUG] ⚠️ 메뉴 위치 정보를 찾을 수 없음: \(menuType)")
            return 0
        }
        
        // 실제 메뉴 버튼의 왼쪽 위치 계산
        let menuLeftX = menuPosition.frame.minX
        let toolbarLeftX = toolbarFrame.minX
        
        // 드롭다운 메뉴를 해당 메뉴 버튼의 왼쪽에 정확히 정렬
        var offset = menuLeftX - toolbarLeftX
        
        // 아이콘 폭 차이 보정 (보기 메뉴 제외)
        if menuType != .view {
            offset -= 5 // 5픽셀 왼쪽으로 이동
            
            // 프로젝트와 내보내기는 추가로 5픽셀 더 왼쪽으로
            if menuType == .project || menuType == .export {
                offset -= 5 // 추가 5픽셀 왼쪽으로 이동
            }
            
            // 프로젝트 메뉴는 더 왼쪽으로 이동해서 다른 메뉴들과 간격 확보
            if menuType == .project {
                offset -= 20 // 추가 20픽셀 왼쪽으로 이동
            }
        }
        
        print("[DEBUG] 📍 정확한 메뉴 위치 계산 - \(menuType):")
        print("  - 메뉴 왼쪽 X: \(menuLeftX)")
        print("  - 툴바 왼쪽 X: \(toolbarLeftX)")
        print("  - 기본 오프셋: \(menuLeftX - toolbarLeftX)")
        print("  - 아이콘 보정: \(menuType != .view ? "-5" : "0")")
        print("  - 추가 보정: \((menuType == .project || menuType == .export) ? "-5" : "0")")
        print("  - 최종 오프셋: \(offset)")
        
        return offset
    }
    
    /// 간단하고 확실한 메뉴 오프셋 계산 (백업용)
    /// - Parameter menuType: 정렬할 메뉴 타입
    /// - Returns: 정확한 오프셋 값
    private func getMenuOffset(for menuType: MenuType) -> CGFloat {
        // 메뉴 타입별 고정 오프셋 (실제 UI에 맞게 조정)
        switch menuType {
        case .project:
            return -200 // 프로젝트 - 더 왼쪽으로
        case .photocard:
            return -100 // 포토카드
        case .toploader:
            return 0    // 탑로더
        case .view:
            return 100  // 보기
        case .export:
            return 200  // 내보내기 - 더 오른쪽으로
        }
    }
    
    /// 가이드에 따른 완벽한 드롭다운 정렬 계산 (백업용)
    /// - Parameter menuType: 정렬할 메뉴 타입
    /// - Returns: 정확한 오프셋 값
    private func calculateSubmenuOffset(for menuType: MenuType) -> CGFloat {
        // 실제 메뉴 위치 정보 사용 (가장 정확함)
        guard let menuPosition = menuPositions.first(where: { $0.type == menuType }) else {
            print("[DEBUG] ⚠️ 메뉴 위치 정보를 찾을 수 없음: \(menuType)")
            return getMenuOffset(for: menuType) // 백업으로 고정 오프셋 사용
        }
        
        // 실제 메뉴 위치 기반 정렬 계산
        let menuLeftX = menuPosition.frame.minX
        let toolbarLeftX = toolbarFrame.minX
        
        // 드롭다운 메뉴를 해당 메뉴 버튼의 왼쪽에 정확히 정렬
        let offset = menuLeftX - toolbarLeftX
        
        // 가이드에 따른 디버그 정보 출력
        print("[DEBUG] 📍 실제 위치 기반 드롭다운 정렬 계산 - \(menuType):")
        print("  - 실제 메뉴 왼쪽 X: \(menuLeftX)")
        print("  - 툴바 왼쪽 X: \(toolbarLeftX)")
        print("  - 계산된 오프셋: \(offset)")
        print("  - 정렬 상태: ✅ 실제 위치 정렬")
        
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
