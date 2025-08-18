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
    
    /// 가이드에 따른 동적 레이아웃 계산
    private var dynamicSpacing: CGFloat {
        isMobile ? 16 : (isTablet ? 30 : 20) // 아이패드에서 간격 확대
    }
    
    private var dynamicPadding: CGFloat {
        isMobile ? 10 : (isTablet ? 16 : 12) // 아이패드에서 패딩 확대
    }
    
    private var dynamicFontSize: CGFloat {
        isMobile ? 15 : 16
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
    @State private var selectedMenu: MenuType? = nil // 현재 선택된 메뉴
    @State private var showToast = false // 토스트 표시 여부
    @State private var toastMessage = "" // 토스트 메시지
    @State private var toastType: AlertMessage.AlertType = .success // 토스트 타입
    

    
    /// 가이드에 따른 완벽한 툴바 컨텐츠
    /// 반응형 디자인과 완벽한 정렬을 구현
    private var toolbarContent: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                // 아이폰: 세로 확장 가능한 툴바
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
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                // 아이패드: 가로 확장 가능한 툴바
                VStack(spacing: 0) {
                    // 메인 툴바
                    HStack(spacing: 8) {
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
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewPreferenceKeys.ToolbarFrameKey.self, value: geo.frame(in: .named("CanvasSpace")))
            }
        )
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
        .onAppear {
            print("[DEBUG] FloatingToolbarView init - onClosePopupMenus 콜백 저장됨: \(onClosePopupMenus != nil)")
        }
        .onChange(of: selectedMenu) { newValue in
            print("[DEBUG] 🔥 selectedMenu 변경됨: \(newValue?.title ?? "nil")")
            if newValue != nil {
                print("[DEBUG] 🔥 상단 메뉴 열림 - 컨텍스트 메뉴 닫기")
                onClosePopupMenus?()
            }
        }
    }
    
    // MARK: - Helper Views
    /// 가이드에 따른 완벽한 툴바 버튼
    /// 반응형 디자인과 접근성을 모두 고려한 구현
    private func toolbarButton(menuType: MenuType) -> some View {
        let isSelected = selectedMenu == menuType
        let hasSubmenu = !menuItems(for: menuType).isEmpty
        
        return Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                // 아이폰: 세로 배치
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
                    }
                }
                .accessibilityLabel(menuType.title)
                .accessibilityHint(hasSubmenu ? "하위 메뉴를 보려면 탭하세요" : "기능을 실행하려면 탭하세요")
                .accessibilityValue(isSelected ? "선택됨" : "선택되지 않음")
            } else {
                // 아이패드: 가로 배치
                HStack(spacing: 6) {
                    Image(systemName: menuType.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(width: 20, height: 20)
                    
                    Text(menuType.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? Color.blue : Color(.separator).opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isSelected {
                            selectedMenu = nil
                        } else {
                            selectedMenu = menuType
                        }
                    }
                }
                .accessibilityLabel(menuType.title)
                .accessibilityHint(hasSubmenu ? "하위 메뉴를 보려면 탭하세요" : "기능을 실행하려면 탭하세요")
                .accessibilityValue(isSelected ? "선택됨" : "선택되지 않음")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// 메뉴 아이템 생성
    /// - Parameter menuType: 메뉴 타입
    /// - Returns: 메뉴 아이템 배열
    private func menuItems(for menuType: MenuType) -> [MenuItem] {
        switch menuType {
        case .project:
            return [
                MenuItem(title: "새 프로젝트", icon: "plus.square", action: { /* 새 프로젝트 생성 */ }),
                MenuItem(title: "프로젝트 열기", icon: "folder", action: { /* 프로젝트 열기 */ }),
                MenuItem(title: "최근 프로젝트", icon: "clock", action: { /* 최근 프로젝트 */ })
            ]
        case .photocard:
            return [
                MenuItem(title: "포토카드 추가", icon: "photo", action: { /* 포토카드 추가 */ }),
                MenuItem(title: "포토카드 편집", icon: "pencil", action: { /* 포토카드 편집 */ }),
                MenuItem(title: "포토카드 삭제", icon: "trash", action: { /* 포토카드 삭제 */ })
            ]
        case .toploader:
            return [
                MenuItem(title: "탑로더 추가", icon: "plus.circle", action: { /* 탑로더 추가 */ }),
                MenuItem(title: "탑로더 편집", icon: "pencil.circle", action: { /* 탑로더 편집 */ }),
                MenuItem(title: "탑로더 삭제", icon: "minus.circle", action: { /* 탑로더 삭제 */ })
            ]
        case .view:
            return [
                MenuItem(title: "확대/축소", icon: "magnifyingglass", action: { /* 확대/축소 */ }),
                MenuItem(title: "그리드 보기", icon: "grid", action: { /* 그리드 보기 */ }),
                MenuItem(title: "전체 화면", icon: "arrow.up.left.and.arrow.down.right", action: { /* 전체 화면 */ })
            ]
        case .export:
            return [
                MenuItem(title: "이미지 저장", icon: "square.and.arrow.down", action: { /* 이미지 저장 */ }),
                MenuItem(title: "PDF 내보내기", icon: "doc.text", action: { /* PDF 내보내기 */ }),
                MenuItem(title: "공유하기", icon: "square.and.arrow.up", action: { /* 공유하기 */ })
            ]
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

