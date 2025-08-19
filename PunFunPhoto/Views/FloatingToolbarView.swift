import SwiftUI
import UniformTypeIdentifiers
import ZipArchive
import UIKit

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
    let scaleFactor: CGFloat // 스케일 팩터 추가
    


    
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
    
    /// 가이드에 따른 동적 레이아웃 계산
    private var dynamicSpacing: CGFloat {
        isMobile ? 16 : (isTablet ? 7.5 : 20) // 아이패드에서 간격 1/2로 축소
    }
    
    private var dynamicPadding: CGFloat {
        isMobile ? 10 : (isTablet ? 16 : 12) // 아이패드에서 패딩 확대
    }
    
    private var dynamicFontSize: CGFloat {
        isMobile ? 15 : 16
    }
    
    /// 메뉴 폭 (화면의 1/5)
    private var menuWidth: CGFloat {
        max(220, UIScreen.main.bounds.width / 5) // 최소 사용성 보장
    }
    
    /// 아이패드 전용 상단 여백 계산
    private var topPaddingForDevice: CGFloat {
        // 아이패드만 정확히 감지 (UIDevice로 확인)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return getSafeAreaInsets().top + 20 // 아이패드에서만 추가 여백
        } else {
            return getSafeAreaInsets().top // 아이폰은 기존 유지
        }
    }
    
    /// 동적 툴바 높이 계산
    private var toolbarHeight: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 50 // 아이폰 기본 높이
        } else {
            return 44 // 아이패드 기본 높이
        }
    }
    
    // MARK: - State Variables
    @State private var showToast = false // 토스트 표시 여부
    @State private var toastMessage = "" // 토스트 메시지
    @State private var toastType: AlertMessage.AlertType = .success // 토스트 타입
    @State private var isMenuOpen: Bool = UIDevice.current.userInterfaceIdiom == .phone ? false : true // 메뉴 패널 열림/닫힘 상태 (아이폰: 접힘, 아이패드: 펼침)
    
    // 파일 선택 및 저장 관련 상태
    @State private var isFileImporterPresented = false
    @State private var showSaveProjectPrompt = false
    @State private var showSavedProjectList = false
    
    // 메뉴 상태를 외부에 알리는 콜백
    var onMenuStateChange: ((Bool) -> Void)? = nil
    
    // 아이패드용 상태 변수들
    @State private var menuPositions: [PunFunPhoto.MenuPosition] = []
    @State private var toolbarFrame: CGRect = .zero
    
    // MARK: - Main View
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    // 아이폰: 아코디언 메뉴 구조
                    toolbarContent
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
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        isMenuOpen = true
                                        onMenuStateChange?(true)
                                    }
                                }
                                .padding(.leading, 12)
                                .padding(.top, topPaddingForDevice + 43) // 아이콘 35픽셀 아래로
                        } else {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.1)) {
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
                        .padding(.top, topPaddingForDevice + 8)
                        }
                    }
                } else {
                    // 아이패드: 상단 드롭다운 툴바 구조
                    ipadToolbarContent
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
        .onAppear {
            print("[DEBUG] FloatingToolbarView init - onClosePopupMenus 콜백 저장됨: \(onClosePopupMenus != nil)")
        }
        .onChange(of: selectedMenu) { _, newValue in
            print("[DEBUG] 🔥 selectedMenu 변경됨: \(newValue?.title ?? "nil")")
            if newValue != nil {
                print("[DEBUG] 🔥 상단 메뉴 열림 - 컨텍스트 메뉴 닫기")
                onClosePopupMenus?()
            }
        }
        // 파일 선택기 sheet
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType.punfunProject],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        // 저장된 프로젝트 목록 sheet
        .sheet(isPresented: $showSaveProjectPrompt) {
            SaveProjectPrompt(
                isPresented: $showSaveProjectPrompt,
                photo1: photo1,
                photo2: photo2
            )
            .environmentObject(appState)
        }
        // 프로젝트 열기 sheet
        .sheet(isPresented: $showSavedProjectList) {
            SavedProjectListView(
                isPresented: $showSavedProjectList,
                photo1: photo1,
                photo2: photo2
            )
            .environmentObject(appState)
        }
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some View {
        HStack(spacing: 0) {
            if isMenuOpen {
                menuPanel
                    .padding(.top, UIDevice.current.userInterfaceIdiom == .phone ? 30 : 0) // 아이폰에서만 30픽셀 아래로
                    .transition(.opacity)
            }
            canvasArea
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewPreferenceKeys.ToolbarFrameKey.self, value: geo.frame(in: .named("CanvasSpace")))
            }
        )
    }
    
    // MARK: - Sub Views
    
    /// 왼쪽 메뉴 패널 (화면의 1/5 폭)
    private var menuPanel: some View {
        VStack(spacing: 0) {
            menuHeader
            Divider()
                .padding(.horizontal, 0)
            menuList
        }
        .frame(width: menuWidth)
        .padding(.top, 10) // 왼쪽 메뉴를 10픽셀 아래로
        .background(Color(.systemBackground))
    }
    
    /// 메뉴 헤더
    private var menuHeader: some View {
        HStack {
            Text("펀펀포토")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
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
        .padding(.top, 16)
        .padding(.bottom, 8) // 하단 여백 최소화
        .background(Color(.systemBackground))
    }
    
    /// 메뉴 목록
    private var menuList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(MenuType.allCases, id: \.self) { menuType in
                    menuItemView(for: menuType)
                }
            }
            .padding(.top, 0) // 상단 여백 제거
            .padding(.bottom, 8)
        }
    }
    
    /// 개별 메뉴 아이템 뷰
    private func menuItemView(for menuType: MenuType) -> some View {
        VStack(spacing: 0) {
            mainMenuButton(for: menuType)
            if selectedMenu == menuType {
                subMenuItems(for: menuType)
            }
        }
    }
    
    /// 메인 메뉴 버튼
    private func mainMenuButton(for menuType: MenuType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
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
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                Text(menuType.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 화살표 아이콘 (펼쳐진/닫힌 상태 구분)
                if selectedMenu == menuType {
                    Text("∧")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                } else {
                    Text("∨")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                selectedMenu == menuType ? Color(red: 126/255, green: 98/255, blue: 214/255).opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// 하위 메뉴 아이템들
    private func subMenuItems(for menuType: MenuType) -> some View {
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
                    .background(Color(red: 126/255, green: 98/255, blue: 214/255).opacity(0.05))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!item.isEnabled)
                
                Divider()
                    .padding(.leading, 52)
                    .opacity(0.3)
            }
        }
        .background(Color(.systemBackground))
        .transition(.opacity)
    }
    
    /// 오른쪽 캔버스 영역 (메뉴 상태에 따라 동적 크기 조정)
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
    
    // MARK: - iPad Toolbar Content
    /// 아이패드용 상단 툴바 컨텐츠
    private var ipadToolbarContent: some View {
        VStack(spacing: 0) {
            // 상단 툴바
            HStack(spacing: dynamicSpacing) {
                ForEach(MenuType.allCases, id: \.self) { menuType in
                    ipadToolbarButton(menuType: menuType)
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
        .padding(.top, getSafeAreaInsets().top + 10) // 아이패드 툴바를 10픽셀 위로
        .overlay(ipadSubmenuOverlay)
        .overlay(
            CenterToastView(message: toastMessage, type: toastType.toCenterToastType, isVisible: $showToast)
        )
    }
    
    /// 아이패드용 상단 툴바 버튼
    @ViewBuilder
    private func ipadToolbarButton(menuType: MenuType) -> some View {
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
    
    /// 아이패드용 서브메뉴 오버레이
    private var ipadSubmenuOverlay: some View {
        Group {
            if let selected = selectedMenu {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: isMobile ? 61 : 80) // 아이패드에서 드롭다운과 캔버스 간격 조정
                    
                    // 정확한 메뉴 위치에 드롭다운 배치
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: getExactMenuOffset(for: selected))
                        
                        ipadMenuOverlay(for: selected)
                            .fixedSize(horizontal: true, vertical: false)
                            .zIndex(100)
                            .transition(.opacity)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.1), value: selected)
            }
        }
    }
    
    /// 아이패드용 메뉴 오버레이
    private func ipadMenuOverlay(for menuType: MenuType) -> some View {
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
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!item.isEnabled)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
    }
    
    // MARK: - Helper Functions
    
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
    
    /// 파일 import 처리
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                print("✅ 선택된 파일:", url)
                Task {
                    await loadProjectManually(from: url)
                }
            } else {
                showToast = true
                toastMessage = "선택된 파일이 없습니다."
            }
        case .failure(let error):
            showToast = true
            toastMessage = "파일 가져오기 실패: \(error.localizedDescription)"
        }
    }
    
    /// 프로젝트 수동 로드
    @MainActor
    private func loadProjectManually(from url: URL) async {
        // 기존 함수 사용
        loadProjectFromArchive(from: url, photo1: photo1, photo2: photo2)
        
        showToast = true
        toastMessage = "프로젝트가 성공적으로 로드되었습니다."
    }
    
    /// Safe Area Insets 가져오기
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
    
    /// 메뉴 아이템 생성
    /// - Parameter menuType: 메뉴 타입
    /// - Returns: 메뉴 아이템 배열
    private func menuItems(for menuType: MenuType) -> [MenuItem] {
        switch menuType {
        case .project:
            return [
                MenuItem(title: "새 프로젝트", icon: "plus.square", action: { 
                    // 새 프로젝트 생성
                    photo1.originalImage = nil
                    photo2.originalImage = nil
                    topLoader1.detach()
                    topLoader2.detach()
                    showToast = true
                    toastMessage = "새 프로젝트가 생성되었습니다."
                }),
                MenuItem(title: "프로젝트 열기", icon: "folder", action: { 
                    // 프로젝트 열기 - 저장된 프로젝트 목록에서 선택
                    showSavedProjectList = true
                }),
                MenuItem(title: "파일에서 직접 열기", icon: "folder.badge.plus", action: { 
                    // 파일에서 직접 열기 - 파일 선택기 열기
                    isFileImporterPresented = true
                }),
                MenuItem(title: "저장", icon: "square.and.arrow.down", action: { 
                    // 저장
                    if let _ = saveProject(photo1: photo1, photo2: photo2) {
                        showToast = true
                        toastMessage = "프로젝트가 저장되었습니다."
                    } else {
                        showToast = true
                        toastMessage = "저장에 실패했습니다."
                    }
                }),
                MenuItem(title: "새 이름으로 저장", icon: "square.and.pencil", action: { 
                    // 새 이름으로 저장 - SaveProjectPrompt 열기
                    showSaveProjectPrompt = true
                })
            ]
        case .photocard:
            return [
                MenuItem(title: "사진 불러오기", icon: "photo.on.rectangle", action: { 
                    // 사진 불러오기
                    photoPickerMode = .전체
                    showPhotoPicker = true
                }),
                MenuItem(title: "편집 초기화", icon: "arrow.counterclockwise", action: { 
                    // 편집 초기화
                    photo1.reset()
                    photo2.reset()
                    showToast = true
                    toastMessage = "편집이 초기화되었습니다."
                }),
                MenuItem(title: "사진 복제", icon: "plus.square.on.square", action: { 
                    // 사진 복제
                    if let image1 = photo1.originalImage {
                        photo2.originalImage = image1
                        showToast = true
                        toastMessage = "사진이 복제되었습니다."
                    }
                }),
                MenuItem(title: "좌우 사진 바꾸기", icon: "arrow.left.arrow.right", action: { 
                    // 좌우 사진 바꾸기 - 모든 상태값을 함께 바꿈
                    let tempImage = photo1.originalImage
                    let tempScale = photo1.scale
                    let tempOffset = photo1.offset
                    let tempCoverScale = photo1.coverScale
                    
                    photo1.originalImage = photo2.originalImage
                    photo1.scale = photo2.scale
                    photo1.offset = photo2.offset
                    photo1.coverScale = photo2.coverScale
                    
                    photo2.originalImage = tempImage
                    photo2.scale = tempScale
                    photo2.offset = tempOffset
                    photo2.coverScale = tempCoverScale
                    
                    showToast = true
                    toastMessage = "좌우 사진이 바뀌었습니다."
                })
            ]
        case .toploader:
            return [
                MenuItem(title: "왼쪽 탑로더 관리", icon: "square.grid.2x2", action: { 
                    // 왼쪽 탑로더 관리
                    showTopLoader1ContextMenu = true
                }),
                MenuItem(title: "오른쪽 탑로더 관리", icon: "square.grid.2x2", action: { 
                    // 오른쪽 탑로더 관리
                    showTopLoader2ContextMenu = true
                }),
                MenuItem(title: "탑로더 복제", icon: "square.on.square", action: { 
                    // 탑로더 복제
                    if topLoader1.showTopLoader {
                        topLoader2.copyFrom(topLoader1)
                        showToast = true
                        toastMessage = "탑로더가 복제되었습니다."
                    }
                }),
                MenuItem(title: "탑로더 모두 제거", icon: "xmark.circle", action: {
                    // 탑로더 모두 제거
                    topLoader1.detach()
                    topLoader2.detach()
                    showToast = true
                    toastMessage = "탑로더가 모두 제거되었습니다."
                })
            ]
        case .view:
            return [
                MenuItem(title: "커팅선 보기/가리기", icon: "rectangle.dashed", action: { 
                    // 커팅선 보기/가리기
                    showSafeFrame.toggle()
                    showToast = true
                    toastMessage = showSafeFrame ? "커팅선이 표시됩니다." : "커팅선이 숨겨집니다."
                }),
                MenuItem(title: "탑로더 보기/가리기", icon: "eye", action: { 
                    // 탑로더 보기/가리기
                    topLoader1.showTopLoader.toggle()
                    topLoader2.showTopLoader.toggle()
                    showToast = true
                    toastMessage = topLoader1.showTopLoader ? "탑로더가 표시됩니다." : "탑로더가 숨겨집니다."
                })
            ]
        case .export:
            return [
                MenuItem(title: "바로 인쇄하기", icon: "printer", action: { 
                    // 바로 인쇄하기 - 실제 인쇄 기능 실행
                    let combinedImage = ExportManager.renderCombinedImage(photo1: photo1, photo2: photo2)
                    PhotoExportHelper.printImage(combinedImage)
                    showToast = true
                    toastMessage = "인쇄 대화상자가 열렸습니다."
                }),
                MenuItem(title: "사진으로 내보내기", icon: "photo", action: { 
                    // 사진으로 내보내기 - 실제 사진 앱에 저장
                    let combinedImage = ExportManager.renderCombinedImage(photo1: photo1, photo2: photo2)
                    ExportManager.saveToPhotos(combinedImage)
                    showToast = true
                    toastMessage = "포토카드가 사진 앱에 저장되었습니다."
                }),
                MenuItem(title: "파일로 내보내기", icon: "tray.and.arrow.down", action: { 
                    // 파일로 내보내기 - 현재 프로젝트를 .pfp 파일로 저장
                    if let savedURL = saveProjectAsArchive(photo1: photo1, photo2: photo2) {
                        showToast = true
                        toastMessage = "프로젝트가 저장되었습니다: \(savedURL.lastPathComponent)"
                    } else {
                        showToast = true
                        toastMessage = "프로젝트 저장에 실패했습니다."
                    }
                })
            ]
        }
    }
    
        /// 메뉴 오프셋 계산 (아이폰용)
    private func getMenuOffset(for menuType: MenuType) -> CGFloat {
        let menuIndex = MenuType.allCases.firstIndex(of: menuType) ?? 0
        let buttonWidth: CGFloat = 120 // 각 메뉴 버튼의 대략적인 폭
        let spacing: CGFloat = dynamicSpacing
        let padding: CGFloat = dynamicPadding

        return padding + CGFloat(menuIndex) * (buttonWidth + spacing)
    }
    

    
    /// 정확한 메뉴 위치 계산 (실제 버튼 위치 기반)
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
        
        // 아이콘 폭 차이 보정 (간격이 1/2로 줄어든 것을 고려하여 조정)
        if menuType != .view {
            offset -= 1.5 // 1.5픽셀 왼쪽으로 이동 (간격 축소에 맞춰 조정)
            
            // 프로젝트와 내보내기는 추가로 1.5픽셀 더 왼쪽으로
            if menuType == .project || menuType == .export {
                offset -= 1.5 // 추가 1.5픽셀 왼쪽으로 이동 (간격 축소에 맞춰 조정)
            }
            
            // 프로젝트 메뉴는 오른쪽으로 이동해서 정확한 위치에 배치
            if menuType == .project {
                offset += 1.5 // 1.5픽셀 오른쪽으로 이동 (간격 축소에 맞춰 조정)
            }
        }
        
        print("[DEBUG] 📍 정확한 메뉴 위치 계산 - \(menuType):")
        print("  - 메뉴 왼쪽 X: \(menuLeftX)")
        print("  - 툴바 왼쪽 X: \(toolbarLeftX)")
        print("  - 기본 오프셋: \(menuLeftX - toolbarLeftX)")
        print("  - 아이콘 보정: \(menuType != .view ? "-1.5" : "0")")
        print("  - 추가 보정: \((menuType == .project || menuType == .export) ? "-1.5" : "0")")
        print("  - 최종 오프셋: \(offset)")
        
        return offset
    }
}

// MARK: - Extensions

/// AlertMessage.AlertType을 CenterToastView.AlertType으로 변환하는 extension
extension AlertMessage.AlertType {
    var toCenterToastType: CenterToastView.AlertType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        }
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