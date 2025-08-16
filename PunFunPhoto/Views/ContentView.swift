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
                } else {
                    ZStack {
                        PhotoEditorView(
                            showSafeFrame: $showSafeFrame,
                            photo1: photo1,
                            photo2: photo2,
                            topLoader1: topLoader1,
                            topLoader2: topLoader2,
                            showPhotoPicker: $showPhotoPicker,
                            showTopLoader1ContextMenu: $showTopLoader1ContextMenu,
                            showTopLoader2ContextMenu: $showTopLoader2ContextMenu
                        )
                        FloatingToolbarView(
                            showSafeFrame: $showSafeFrame,
                            photo1: photo1,
                            photo2: photo2,
                            topLoader1: topLoader1,
                            topLoader2: topLoader2,
                            showPhotoPicker: $showPhotoPicker,
                            photoPickerMode: $photoPickerMode,
                            showAlreadySelectedAlert: $showAlreadySelectedAlert,
                            selectedMenu: $selectedMenu,
                            showContextMenu: $showContextMenu,
                            showTopLoader1ContextMenu: $showTopLoader1ContextMenu,
                            showTopLoader2ContextMenu: $showTopLoader2ContextMenu
                        )
                        .zIndex(999)
                    }
                }
            }
            .onAppear {
                rootOrigin = rootGeo.frame(in: .global).origin
            }
            .onChange(of: rootGeo.frame(in: .global)) {
                rootOrigin = rootGeo.frame(in: .global).origin
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
