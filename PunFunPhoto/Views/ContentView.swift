import SwiftUI

struct ContentView: View {
    @State private var showSafeFrame = false
    @StateObject private var photo1 = PhotoState()
    @StateObject private var photo2 = PhotoState()
    @StateObject private var topLoader1 = TopLoaderState()
    @StateObject private var topLoader2 = TopLoaderState()
    
    @State private var showContextMenu = false
    @State private var showTopLoader1ContextMenu: Bool? = false
    @State private var showTopLoader2ContextMenu: Bool? = false
    @State private var showObjectMenu = false
    @State private var contextMenuFrame: CGRect = .zero
    @State private var contextBoxIndex: Int? = nil
    @State private var canvasFrame: CGRect = .zero
    @State private var menuHeight: CGFloat = 0
    @State private var menuWidth: CGFloat = 0
    @State private var scaleFactor: CGFloat = 0.5 // 필요시 동적으로 계산
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @State private var rootOrigin: CGPoint = .zero
    @State private var showPhotoPicker = false
    @State private var photoPickerMode: PhotoPickerMode = .전체
    @State private var showAlreadySelectedAlert: Bool = false
    @State private var selectedMenu: MenuType? = nil
    
    // 메뉴 전환을 관리하는 함수들
    private func openPhotoCardMenu() {
        print("[DEBUG] 🔥 ContentView - 포토카드 메뉴 열기 시작")
        // 다른 모든 메뉴들을 먼저 닫기
        showTopLoader1ContextMenu = nil
        showTopLoader2ContextMenu = nil
        showObjectMenu = false
        // 포토카드 메뉴 열기
        showContextMenu = true
        print("[DEBUG] 🔥 ContentView - 포토카드 메뉴 열기 완료")
    }
    
    private func openTopLoader1Menu() {
        print("[DEBUG] 🔥 ContentView - 탑로더1 메뉴 열기 시작")
        // 다른 모든 메뉴들을 먼저 닫기
        showContextMenu = false
        showTopLoader2ContextMenu = nil
        showObjectMenu = false
        // 탑로더1 메뉴 열기
        showTopLoader1ContextMenu = true
        print("[DEBUG] 🔥 ContentView - 탑로더1 메뉴 열기 완료")
    }
    
    private func openTopLoader2Menu() {
        print("[DEBUG] 🔥 ContentView - 탑로더2 메뉴 열기 시작")
        // 다른 모든 메뉴들을 먼저 닫기
        showContextMenu = false
        showTopLoader1ContextMenu = nil
        showObjectMenu = false
        // 탑로더2 메뉴 열기
        showTopLoader2ContextMenu = true
        print("[DEBUG] 🔥 ContentView - 탑로더2 메뉴 열기 완료")
    }
    
    private func openObjectMenu() {
        print("[DEBUG] 🔥 ContentView - 스티커/텍스트 메뉴 열기 시작")
        // 다른 모든 메뉴들을 먼저 닫기
        showContextMenu = false
        showTopLoader1ContextMenu = nil
        showTopLoader2ContextMenu = nil
        // 스티커/텍스트 메뉴 열기
        showObjectMenu = true
        print("[DEBUG] 🔥 ContentView - 스티커/텍스트 메뉴 열기 완료")
    }
    
    var body: some View {
        GeometryReader { rootGeo in
            ZStack {
                let isPortrait = verticalSizeClass == .regular && horizontalSizeClass == .compact
                let isPhone = UIDevice.current.userInterfaceIdiom == .phone
                let shouldShowWarning = isPhone && isPortrait
                if shouldShowWarning {
                    VStack(spacing: 20) {
                        Image(systemName: "iphone.landscape")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("펀펀포토는 뻔뻔하게\n가로화면에서만 편집합니다.")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Text("포토카드를 저장하거나 불러올때는 세로로 가능합니다.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .position(x: rootGeo.size.width / 2, y: rootGeo.size.height / 2)
                } else {
                    ZStack {
                        PhotoEditorView(
                            showSafeFrame: $showSafeFrame,
                            photo1: photo1,
                            photo2: photo2,
                            topLoader1: topLoader1,
                            topLoader2: topLoader2,
                            showPhotoPicker: $showPhotoPicker,
                            showContextMenu: $showContextMenu,
                            selectedMenu: $selectedMenu,
                            showTopLoader1ContextMenu: $showTopLoader1ContextMenu,
                            showTopLoader2ContextMenu: $showTopLoader2ContextMenu,
                            showObjectMenu: $showObjectMenu
                        )
                        // FloatingToolbarView는 PhotoEditorView 내부에서 처리됨
                    }
                }
            }
            .onAppear {
                rootOrigin = rootGeo.frame(in: .global).origin
            }
            .onChange(of: rootGeo.frame(in: .global)) {
                rootOrigin = rootGeo.frame(in: .global).origin
            }
            .onChange(of: selectedMenu) { newValue in
                print("[DEBUG] ContentView - selectedMenu 변경됨: \(newValue?.title ?? "nil")")
                
                // 상단 메뉴 상태 변경만 로깅, 팝업 메뉴들은 PhotoEditorView에서 처리
            }
            .onChange(of: showContextMenu) { oldValue, newValue in
                print("[DEBUG] ContentView - showContextMenu 변경됨: \(oldValue) -> \(newValue)")
                
                // 포토박스 메뉴 상태 변경만 로깅, 다른 메뉴들은 PhotoEditorView에서 처리
            }
            .onChange(of: showTopLoader1ContextMenu) { oldValue, newValue in
                print("[DEBUG] ContentView - showTopLoader1ContextMenu 변경됨: \(oldValue ?? false) -> \(newValue ?? false)")
                
                // 탑로더1 메뉴 상태 변경만 로깅, 다른 메뉴들은 PhotoEditorView에서 처리
            }
            .onChange(of: showTopLoader2ContextMenu) { oldValue, newValue in
                print("[DEBUG] ContentView - showTopLoader2ContextMenu 변경됨: \(oldValue ?? false) -> \(newValue ?? false)")
                
                // 탑로더2 메뉴 상태 변경만 로깅, 다른 메뉴들은 PhotoEditorView에서 처리
            }
            .onChange(of: showObjectMenu) { oldValue, newValue in
                print("[DEBUG] ContentView - showObjectMenu 변경됨: \(oldValue) -> \(newValue)")
                
                // 스티커/텍스트 메뉴 상태 변경만 로깅, 다른 메뉴들은 PhotoEditorView에서 처리
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}

