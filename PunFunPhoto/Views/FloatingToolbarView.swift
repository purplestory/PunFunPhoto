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
    let scaleFactor: CGFloat // 스케일 팩터 추가 (아이폰 최적화)

    
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
        onClosePopupMenus: (() -> Void)? = nil,
        onMenuStateChange: ((Bool) -> Void)? = nil,
        scaleFactor: CGFloat = 1.0

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
        self.onMenuStateChange = onMenuStateChange
        self.scaleFactor = scaleFactor
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
    
    /// 명시적 디바이스 타입 체크 (아이폰 여부)
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// 메뉴 폭 (화면의 1/5) - 아이폰용 아코디언 메뉴
    private var menuWidth: CGFloat {
        max(220, UIScreen.main.bounds.width / 5) // 최소 사용성 보장
    }
    
    /// 아이폰용 메뉴 상태 - 아코디언 메뉴 열림/닫힘
    @State private var isMenuOpen: Bool = UIDevice.current.userInterfaceIdiom == .phone ? false : true
    
    // 메뉴 상태를 외부에 알리는 콜백 (아이폰용)
    var onMenuStateChange: ((Bool) -> Void)? = nil
    
    /// 가이드에 따른 동적 레이아웃 계산
    /// 아이폰과 아이패드 각각 최적화
    private var dynamicSpacing: CGFloat {
        if isMobile {
            return 24 // 아이폰: 적당한 간격 (아이폰용 브랜치에서 최적화)
        } else {
            return 40 // 아이패드: 넉넉한 간격 (아이패드용 최적화)
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

    @State private var submenuHeight: CGFloat = 0
    @State private var showToast = false
    @State private var toastMessage: String = ""
    @State private var toastType: AlertMessage.AlertType = .success
    
    private var toolbarHeight: CGFloat {
        44 + getSafeAreaInsets().top
    }
    
    /// 가이드에 따른 완벽한 툴바 컨텐츠 구현
    /// 아이폰과 아이패드 각각 최적화된 UI 제공
    private var toolbarContent: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                // 아이폰: 세로 확장 가능한 툴바 (아이폰용 분기에서 가져온 최적화)
                VStack(spacing: 0) {
                    // 메인 툴바
                    HStack(spacing: 12) {
                        ForEach(MenuType.allCases, id: \.self) { menuType in
                            toolbarButton(menuType: menuType)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(.separator))
                            .offset(y: 0.25),
                        alignment: .bottom
                    )
                    
                    // 확장된 메뉴 영역
                    if let selected = selectedMenu {
                        VStack(spacing: 0) {
                            ForEach(menuItems(for: selected)) { item in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        item.action()
                                        selectedMenu = nil
                                        onMenuChange?()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                                            .frame(width: 24)
                                        Text(item.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!item.isEnabled)
                                
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                        .background(Color(.systemBackground))
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ViewPreferenceKeys.ToolbarFrameKey.self, value: geo.frame(in: .global))
                    }
                )
            } else {
                // 아이패드: 기존 최적화된 툴바 (아이패드용 분기에서 가져온 최적화)
                VStack(spacing: 0) {
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
        }
    }
    
    /// 가이드에 따른 완벽한 드롭다운 메뉴 오버레이
    /// 완벽한 정렬과 반응형 디자인을 구현
    private var submenuOverlay: some View {
        Group {
            if let selected = selectedMenu {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: dropdownSpacing) // 디바이스별 최적화된 드롭다운 간격
                    
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
            ZStack(alignment: .topLeading) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    // 아이폰: 아코디언 메뉴 구조
                    phoneToolbarContent
                    
                    // 아이폰용 앱 아이콘 (메뉴가 닫혀있을 때만 표시)
                    if !isMenuOpen {
                        if let icon = appIconUIImage() {
                            Image(uiImage: icon)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .background(Color.clear)
                                .allowsHitTesting(true)
                                .drawingGroup()
                                .compositingGroup()
                                .blendMode(.normal)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isMenuOpen = true
                                        onMenuStateChange?(true)
                                    }
                                }
                                .padding(.leading, 12)
                                .padding(.top, getSafeAreaInsets().top + 8)
                        } else {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isMenuOpen = true
                                    onMenuStateChange?(true)
                                }
                            }) {
                                Text("펀펀포토")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 12)
                            .padding(.top, getSafeAreaInsets().top + 8)
                        }
                    }
                } else {
                    // 아이패드: 기존 드롭다운 툴바 구조
                    ZStack(alignment: .top) {
                        Color.clear
                            .overlay {
                                toolbarContent
                            }
                    }
                    .overlay(
                        // 드롭다운 메뉴 오버레이
                        selectedMenu != nil ? AnyView(submenuOverlay) : AnyView(Color.clear)
                    )
                }
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
                
                // 아이폰에서만 토스트 메시지를 화면 중앙에 표시
                if UIDevice.current.userInterfaceIdiom == .phone {
                    CenterToastView(message: toastMessage, type: toastType.toCenterToastType, isVisible: $showToast)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    /// 가이드에 따른 완벽한 툴바 버튼 구현
    /// 아이폰과 아이패드 각각 최적화된 버튼 제공
    /// - Parameter menuType: 메뉴 타입
    /// - Returns: 완벽한 정렬과 토글 기능을 가진 버튼
    @ViewBuilder
    private func toolbarButton(menuType: MenuType) -> some View {
        let isSelected = selectedMenu == menuType
        let hasSubmenu = !menuItems(for: menuType).isEmpty
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // 아이폰: 세로 배치 (아이폰용 분기에서 가져온 최적화)
            VStack(spacing: 4) {
                Image(systemName: menuType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 24, height: 24)
                
                Text(menuType.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color(.separator).opacity(0.3), lineWidth: 1)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isSelected {
                        selectedMenu = nil
                    } else {
                        selectedMenu = menuType
                    }
                    onMenuChange?()
                }
            }
            .accessibilityLabel(menuType.title)
            .accessibilityHint(hasSubmenu ? "하위 메뉴를 보려면 탭하세요" : "기능을 실행하려면 탭하세요")
            .accessibilityValue(isSelected ? "선택됨" : "선택되지 않음")
        } else {
            // 아이패드: 가로 배치 (기존 최적화 유지)
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
                .padding(.horizontal, 20)
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
    }
    
    /// 가이드에 따른 완벽한 메뉴 오버레이 구현
    /// - Parameter menuType: 메뉴 타입
    /// - Returns: 완벽한 스타일과 접근성을 가진 메뉴 오버레이
    private func menuOverlay(for menuType: MenuType) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    .frame(height: 36)
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
    
    // MARK: - iPhone Accordion Menu Content
    /// 아이폰용 아코디언 메뉴 컨텐츠
    private var phoneToolbarContent: some View {
        HStack(spacing: 0) {
            if isMenuOpen {
                phoneMenuPanel
            }
            phoneCanvasArea
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewPreferenceKeys.ToolbarFrameKey.self, value: geo.frame(in: .named("CanvasSpace")))
            }
        )
    }
    
    /// 아이폰용 왼쪽 메뉴 패널 (화면의 1/5 폭)
    private var phoneMenuPanel: some View {
        VStack(spacing: 0) {
            phoneMenuHeader
            Divider()
            phoneMenuList
        }
        .frame(width: menuWidth)
        .background(Color(.systemBackground))
    }
    
    /// 아이폰용 메뉴 헤더
    private var phoneMenuHeader: some View {
        HStack {
            Text("펀펀포토")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMenu = nil
                    isMenuOpen = false
                    onClosePopupMenus?()
                    onMenuStateChange?(false)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    /// 아이폰용 메뉴 목록
    private var phoneMenuList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(MenuType.allCases, id: \.self) { menuType in
                    phoneMenuItemView(for: menuType)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// 아이폰용 개별 메뉴 아이템 뷰
    private func phoneMenuItemView(for menuType: MenuType) -> some View {
        VStack(spacing: 0) {
            phoneMainMenuButton(for: menuType)
            if selectedMenu == menuType {
                phoneSubMenuItems(for: menuType)
            }
        }
    }
    
    /// 아이폰용 메인 메뉴 버튼
    private func phoneMainMenuButton(for menuType: MenuType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedMenu == menuType {
                    selectedMenu = nil
                } else {
                    selectedMenu = menuType
                }
            }
        }) {
            HStack {
                Image(systemName: menuType.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedMenu == menuType ? .blue : .primary)
                    .frame(width: 24)
                
                Text(menuType.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedMenu == menuType ? .blue : .primary)
                
                Spacer()
                
                // 화살표 아이콘 (펼쳐진/닫힌 상태 구분)
                if selectedMenu == menuType {
                    Text("∧")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                } else {
                    Text("∨")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                selectedMenu == menuType ? Color.blue.opacity(0.08) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// 아이폰용 하위 메뉴 아이템들
    private func phoneSubMenuItems(for menuType: MenuType) -> some View {
        VStack(spacing: 0) {
            ForEach(menuItems(for: menuType)) { item in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        item.action()
                        selectedMenu = nil
                        onMenuChange?()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16))
                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                            .frame(width: 20)
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .padding(.leading, 20) // 들여쓰기
                    .background(Color.blue.opacity(0.05))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!item.isEnabled)
                
                Divider()
                    .padding(.leading, 52)
                    .opacity(0.3)
            }
        }
    }
    
    /// 아이폰용 캔버스 영역
    private var phoneCanvasArea: some View {
        canvasArea
    }
    
    /// 실제 편집 가능한 캔버스는 `PhotoEditorView`가 렌더링하며,
    /// 이 뷰는 메뉴 영역 외에는 아무 것도 그리지 않도록 비워둡니다.
    private var canvasArea: some View {
        GeometryReader { geometry in
            Color.clear
                .allowsHitTesting(false) // 아래 편집 캔버스의 터치를 가로막지 않음
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .offset(x: isMenuOpen ? menuWidth : 0) // 메뉴가 열려있을 때 오른쪽으로 이동
        }
    }
    
    /// 앱 아이콘(또는 자산의 로고)을 UIImage로 가져오기
    private func appIconUIImage() -> UIImage? {
        // 1순위: 투명 배경 로고를 우선 사용
        if let transparent = UIImage(named: "punfun_logo_transparent") { return transparent }
        // 2순위: 기본 로고
        if let logo = UIImage(named: "punfun_logo") { return logo }
        // 실패 시 앱 아이콘 중 하나를 시도
        if let iconsDict = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryDict = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primaryDict["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let image = UIImage(named: name) {
            return image
        }
        return nil
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
