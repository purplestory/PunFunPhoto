import SwiftUI

enum PhotoPickerMode {
    case 전체
    case 박스1
    case 박스2
    case 비어있는
}

struct PhotoEditorView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showSafeFrame: Bool
    @ObservedObject var photo1: PhotoState
    @ObservedObject var photo2: PhotoState
    @ObservedObject var topLoader1: TopLoaderState
    @ObservedObject var topLoader2: TopLoaderState
    @Binding var showPhotoPicker: Bool
    @State private var canvasFrame: CGRect = .zero
    @State private var showPicker1 = false
    @State private var showPicker2 = false
    @State private var debugMode = false
    @State private var contextMenuTargetBoxIndex: Int? = nil
    @State private var contextMenuTargetFrame: CGRect = .zero
    @State private var menuWidth: CGFloat = 0
    @State private var menuHeight: CGFloat = 0
    @State private var boxFrames: [Int: CGRect] = [:]
    @State private var rootOrigin: CGPoint = .zero
    @State private var selectedBoxIndex: Int? = nil
    @State private var photoPickerMode: PhotoPickerMode = .전체
    @State private var showAlreadySelectedAlert = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @Binding var showContextMenu: Bool
    @Binding var selectedMenu: MenuType?
    @Binding var showTopLoader1ContextMenu: Bool?
    @Binding var showTopLoader2ContextMenu: Bool?
    @State private var showTopLoaderLibrary = false
    @State private var selectedPhotoForTopLoader: PhotoState?
    @Binding var showObjectMenu: Bool
    @State private var selectedTextId: UUID? = nil
    @State private var selectedStickerId: UUID? = nil
    @State private var objectMenuPosition: CGPoint = .zero
    
    // 컨텍스트 메뉴 타입을 정의
    enum ContextMenuType: Equatable {
        case photoBox(Int)  // 포토박스 번호
        case topLoader(Int) // 탑로더 번호
        case object         // 스티커/텍스트
    }
    
    @State private var activeContextMenu: ContextMenuType? = nil
    
    private let baseCanvasSize = CGSize(width: 1800, height: 1200)
    private let baseBoxSize = CGSize(width: 685, height: 1063)
    
    private var currentProjectName: String {
        if let url = appState.currentProjectURL {
            return url.deletingPathExtension().lastPathComponent
        }
        return "새 프로젝트"
    }
    
    private var showMenu: Bool { showContextMenu }
    private var boxIndex: Int? { contextMenuTargetBoxIndex }
    private var unclampedX: CGFloat { contextMenuTargetFrame.midX + rootOrigin.x }
    private var unclampedY: CGFloat { contextMenuTargetFrame.midY + rootOrigin.y }
    
    private func closeAllMenus() {
        print("[DEBUG] 🔍 PhotoEditorView - closeAllMenus() 호출됨")
        selectedMenu = nil
        showContextMenu = false
        showTopLoader1ContextMenu = nil
        showTopLoader2ContextMenu = nil
        showObjectMenu = false
    }
    
    private func closeTopMenuOnly() {
        print("[DEBUG] 🔍 PhotoEditorView - closeTopMenuOnly() 호출됨")
        selectedMenu = nil
        showTopLoader1ContextMenu = nil
        showTopLoader2ContextMenu = nil
    }
    
    private func closeAllMenusExceptPhotoContext() {
        print("[DEBUG] 🔍 PhotoEditorView - closeAllMenusExceptPhotoContext() 호출됨")
        selectedMenu = nil
        showContextMenu = false
        showTopLoader1ContextMenu = nil
        showTopLoader2ContextMenu = nil
        showObjectMenu = false
    }
    
    // 메인 캔버스(포토박스, 프로젝트명 등)를 별도 뷰로 분리
    private func mainCanvas(scaleFactor: CGFloat) -> some View {
        ZStack {
            PhotoBoxContainerView(
                showSafeFrame: $showSafeFrame,
                scaleFactor: scaleFactor,
                canvasSize: baseCanvasSize,
                boxSize: baseBoxSize,
                ppi: 264,
                debugMode: debugMode,
                canvasFrame: canvasFrame,
                boxFrames: boxFrames,
                rootOrigin: rootOrigin,
                photo1: photo1,
                photo2: photo2,
                topLoader1: topLoader1,
                topLoader2: topLoader2,
                contextMenuTargetFrame: contextMenuTargetFrame,
                contextMenuTargetBoxIndex: $contextMenuTargetBoxIndex,
                onTapPhoto1: {
                    print("[DEBUG] 🔥 PhotoEditorView - 포토박스1 터치됨")
                    
                    if photo1.originalImage == nil && photo2.originalImage == nil {
                        photoPickerMode = .비어있는
                        selectedBoxIndex = nil
                        showPhotoPicker = true
                    } else if photo1.originalImage == nil {
                        photoPickerMode = .비어있는
                        selectedBoxIndex = 1
                        showPhotoPicker = true
                    } else if photo1.originalImage != nil {
                        // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                        if activeContextMenu == .photoBox(1) {
                            // 같은 포토박스 메뉴를 터치하면 닫기
                            activeContextMenu = nil
                            showContextMenu = false
                            print("[DEBUG] 🔥 포토박스1 메뉴 닫힘")
                        } else {
                            // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                            activeContextMenu = .photoBox(1)
                            contextMenuTargetBoxIndex = 1
                            if let frame = boxFrames[1] {
                                contextMenuTargetFrame = frame
                                showContextMenu = true
                                print("[DEBUG] 🔥 포토박스1 메뉴 열림")
                            }
                        }
                    }
                },
                onTapPhoto2: {
                    print("[DEBUG] 🔥 PhotoEditorView - 포토박스2 터치됨")
                    
                    if photo1.originalImage == nil && photo2.originalImage == nil {
                        photoPickerMode = .비어있는
                        selectedBoxIndex = nil
                        showPhotoPicker = true
                    } else if photo2.originalImage == nil {
                        photoPickerMode = .비어있는
                        selectedBoxIndex = 2
                        showPhotoPicker = true
                    } else if photo2.originalImage != nil {
                        // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                        if activeContextMenu == .photoBox(2) {
                            // 같은 포토박스 메뉴를 터치하면 닫기
                            activeContextMenu = nil
                            showContextMenu = false
                            print("[DEBUG] 🔥 포토박스2 메뉴 닫힘")
                        } else {
                            // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                            activeContextMenu = .photoBox(2)
                            contextMenuTargetBoxIndex = 2
                            if let frame = boxFrames[2] {
                                contextMenuTargetFrame = frame
                                showContextMenu = true
                                print("[DEBUG] 🔥 포토박스2 메뉴 열림")
                            }
                        }
                    }
                },
                onSwapPhoto1: { swapPhotos() },
                onSwapPhoto2: { swapPhotos() },
                onDuplicatePhoto1: { duplicatePhoto(from: photo1, to: photo2) },
                onDuplicatePhoto2: { duplicatePhoto(from: photo2, to: photo1) },
                onContextMenuRequested: { boxIdx, frame in
                    // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                    if activeContextMenu == .photoBox(boxIdx) {
                        // 같은 포토박스 메뉴를 터치하면 닫기
                        activeContextMenu = nil
                        showContextMenu = false
                        print("[DEBUG] 🔥 포토박스\(boxIdx) 메뉴 닫힘")
                    } else {
                        // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                        activeContextMenu = .photoBox(boxIdx)
                        contextMenuTargetBoxIndex = boxIdx
                        contextMenuTargetFrame = frame
                        showContextMenu = true
                        print("[DEBUG] 🔥 포토박스\(boxIdx) 메뉴 열림")
                    }
                },
                onStickerTapped: { stickerId, position in
                    print("[DEBUG] PhotoEditorView - 스티커 터치됨: \(stickerId)")
                    
                    // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                    if activeContextMenu == .object {
                        // 같은 오브젝트 메뉴를 터치하면 닫기
                        activeContextMenu = nil
                        showObjectMenu = false
                        print("[DEBUG] 🔥 스티커 메뉴 닫힘")
                    } else {
                        // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                        activeContextMenu = .object
                        selectedStickerId = stickerId
                        selectedTextId = nil
                        objectMenuPosition = position
                        showObjectMenu = true
                        print("[DEBUG] 🔥 스티커 메뉴 열림")
                    }
                },
                onTextTapped: { textId, position in
                    print("[DEBUG] PhotoEditorView - 텍스트 터치됨: \(textId)")
                    
                    // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                    if activeContextMenu == .object {
                        // 같은 오브젝트 메뉴를 터치하면 닫기
                        activeContextMenu = nil
                        showObjectMenu = false
                        print("[DEBUG] 🔥 텍스트 메뉴 닫힘")
                    } else {
                        // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                        activeContextMenu = .object
                        selectedTextId = textId
                        selectedStickerId = nil
                        objectMenuPosition = position
                        showObjectMenu = true
                        print("[DEBUG] 🔥 텍스트 메뉴 열림")
                    }
                },

                showToast: $showToast,
                toastMessage: $toastMessage,
                selectedMenu: $selectedMenu,
                showContextMenu: $showContextMenu,
                showTopLoader1ContextMenu: Binding(
                    get: { showTopLoader1ContextMenu ?? false },
                    set: { showTopLoader1ContextMenu = $0 }
                ),
                showTopLoader2ContextMenu: Binding(
                    get: { showTopLoader2ContextMenu ?? false },
                    set: { showTopLoader2ContextMenu = $0 }
                ),
                onTopLoader1Tapped: {
                    print("[DEBUG] PhotoEditorView - 탑로더1 터치됨")
                    
                    // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                    if activeContextMenu == .topLoader(1) {
                        // 같은 탑로더 메뉴를 터치하면 닫기
                        activeContextMenu = nil
                        showTopLoader1ContextMenu = nil
                        print("[DEBUG] 🔥 탑로더1 메뉴 닫힘")
                    } else {
                        // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                        activeContextMenu = .topLoader(1)
                        showTopLoader1ContextMenu = true
                        print("[DEBUG] 🔥 탑로더1 메뉴 열림")
                    }
                },
                onTopLoader2Tapped: {
                    print("[DEBUG] PhotoEditorView - 탑로더2 터치됨")
                    
                    // 상단 툴바 메뉴처럼 작동: 같은 메뉴를 터치하면 닫고, 다른 메뉴를 터치하면 전환
                    if activeContextMenu == .topLoader(2) {
                        // 같은 탑로더 메뉴를 터치하면 닫기
                        activeContextMenu = nil
                        showTopLoader2ContextMenu = nil
                        print("[DEBUG] 🔥 탑로더2 메뉴 닫힘")
                    } else {
                        // 다른 메뉴를 터치하면 기존 메뉴를 닫고 새 메뉴 열기
                        activeContextMenu = .topLoader(2)
                        showTopLoader2ContextMenu = true
                        print("[DEBUG] 🔥 탑로더2 메뉴 열림")
                    }
                }
            )
            .cornerRadius(0)
            .frame(width: baseCanvasSize.width, height: baseCanvasSize.height)
            .onPreferenceChange(ViewPreferenceKeys.CanvasFrameKey.self) { value in
                self.canvasFrame = value
            }
            .onPreferenceChange(ViewPreferenceKeys.PhotoBoxFrameKey.self) { frames in
                self.boxFrames = frames
            }

            Text(currentProjectName)
                .font(.title2)
                .foregroundColor(.black.opacity(0.5))
                .padding(.vertical, 10)
                .padding(.horizontal, 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .fixedSize()
                .frame(width: 380, height: 48)
                .position(x: baseCanvasSize.width / 2, y: baseCanvasSize.height + 50)
        }
        .scaleEffect(scaleFactor)
        .frame(width: baseCanvasSize.width * scaleFactor, height: baseCanvasSize.height * scaleFactor)
    }
    
    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            let safeAreaTop = geo.safeAreaInsets.top
            let toolbarHeight: CGFloat = 44 + safeAreaTop
            let toolbarMargin: CGFloat = max(70, screenHeight * 0.03) // 화면 높이의 3% (최소 24pt)
            let availableHeight = max(1, screenHeight - toolbarHeight - toolbarMargin - 60 )
            let scaleW = screenWidth / baseCanvasSize.width
            let scaleH = availableHeight / baseCanvasSize.height
            let scaleFactor = max(0.1, min(scaleW, scaleH))

            // context menu 관련 클로저를 computed property에서 boxIndex를 사용하도록 변경
            let onPick: () -> Void = {
                if boxIndex == 1 {
                    photoPickerMode = .박스1
                    selectedBoxIndex = 1
                    showPhotoPicker = true
                } else {
                    photoPickerMode = .박스2
                    selectedBoxIndex = 2
                    showPhotoPicker = true
                }
                // showContextMenu = false 제거 - 다른 메뉴들은 PhotoEditorView에서 처리
            }
            let onReset: () -> Void = {
                if boxIndex == 1 { photo1.reset() }
                else { photo2.reset() }
                // showContextMenu = false 제거 - 다른 메뉴들은 PhotoEditorView에서 처리
            }
            let onDuplicate: () -> Void = {
                if boxIndex == 1 { duplicatePhoto(from: photo1, to: photo2) }
                else { duplicatePhoto(from: photo2, to: photo1) }
                // showContextMenu = false 제거 - 다른 메뉴들은 PhotoEditorView에서 처리
            }
            let onSwap: () -> Void = {
                swapPhotos()
                // showContextMenu = false 제거 - 다른 메뉴들은 PhotoEditorView에서 처리
            }
            let onDelete: () -> Void = {
                if boxIndex == 1 { photo1.originalImage = nil }
                else { photo2.originalImage = nil }
                // showContextMenu = false 제거 - 다른 메뉴들은 PhotoEditorView에서 처리
            }

            ZStack {
                Color.white
                VStack {
                    Spacer()
                    mainCanvas(scaleFactor: scaleFactor)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .zIndex(0)
                
                // 메뉴가 열려있을 때만 배경 터치 처리
                if selectedMenu != nil {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            print("[DEBUG] PhotoEditorView - 전체 화면 배경 터치됨 - 메뉴 닫기")
                            selectedMenu = nil
                        }
                        .zIndex(98)
                }
                


                if showMenu, let boxIndex = boxIndex {
                    PhotoBoxContextMenuOverlay(
                        showSafeFrame: $showSafeFrame,
                        onDismiss: {
                            showContextMenu = false  // 포토카드 메뉴 닫기
                            selectedMenu = nil
                        },
                        targetFrame: contextMenuTargetFrame,
                        canvasFrame: canvasFrame,
                        scaleFactor: 1.0,
                        screenScale: UIScreen.main.scale,
                        onPick: onPick,
                        onReset: onReset,
                        onDuplicate: onDuplicate,
                        onSwap: onSwap,
                        onDelete: onDelete,
                        onShowTopLoader: {
                            if boxIndex == 1 {
                                topLoader1.showTopLoader = true
                            } else if boxIndex == 2 {
                                topLoader2.showTopLoader = true
                            }
                        },
                        selectedPhoto: boxIndex == 1 ? photo1 : photo2,
                        onShowTopLoaderMenu: { photo in showTopLoaderMenu(for: photo) },
                        isTopLoaderAttached: boxIndex == 1 ? topLoader1.isAttached : topLoader2.isAttached,
                        showTopLoader: boxIndex == 1 ? topLoader1.showTopLoader : topLoader2.showTopLoader
                    )
                    .position(x: unclampedX, y: unclampedY)
                    .zIndex(9999)
                    .allowsHitTesting(true)
                }
                if showToast {
                    CenterToastView(message: toastMessage, type: .success, isVisible: $showToast)
                }
                
                // 탑로더 1 컨텍스트 메뉴
                if showTopLoader1ContextMenu == true {
                    TopLoaderContextMenuOverlay(
                        onDismiss: { showTopLoader1ContextMenu = false },
                        targetFrame: boxFrames[1] ?? .zero,
                        canvasFrame: canvasFrame,
                        onTextAdd: { topLoader1.addText("", fontSize: 32, textColor: .black, style: .plain, strokeColor: .clear, boxSize: baseBoxSize) },
                        onManage: { /* 탑로더 관리 로직 */ },
                        onSave: { 
                            topLoader1.saveTopLoader(name: "내 탑로더 \(Date().formatted(date: .numeric, time: .shortened))")
                            showToast = true
                            toastMessage = "탑로더가 저장되었습니다."
                        },
                        onToggleVisibility: { topLoader1.showTopLoader.toggle() },
                        onRemove: { 
                            topLoader1.detach()
                            showToast = true
                            toastMessage = "탑로더가 제거되었습니다."
                        },
                        isVisible: topLoader1.showTopLoader
                    )
                    .position(x: boxFrames[1]?.midX ?? 0, y: boxFrames[1]?.midY ?? 0)
                    .zIndex(9998)
                }
                
                // 탑로더 2 컨텍스트 메뉴
                if showTopLoader2ContextMenu == true {
                    TopLoaderContextMenuOverlay(
                        onDismiss: { showTopLoader2ContextMenu = false },
                        targetFrame: boxFrames[2] ?? .zero,
                        canvasFrame: canvasFrame,
                        onTextAdd: { topLoader2.addText("", fontSize: 32, textColor: .black, style: .plain, strokeColor: .clear, boxSize: baseBoxSize) },
                        onManage: { /* 탑로더 관리 로직 */ },
                        onSave: { 
                            topLoader2.saveTopLoader(name: "내 탑로더 \(Date().formatted(date: .numeric, time: .shortened))")
                            showToast = true
                            toastMessage = "탑로더가 저장되었습니다."
                        },
                        onToggleVisibility: { topLoader2.showTopLoader.toggle() },
                        onRemove: { 
                            topLoader2.detach()
                            showToast = true
                            toastMessage = "탑로더가 제거되었습니다."
                        },
                        isVisible: topLoader2.showTopLoader
                    )
                    .position(x: boxFrames[2]?.midX ?? 0, y: boxFrames[2]?.midY ?? 0)
                    .zIndex(9998)
                }
                
                // 스티커 메뉴
                if showObjectMenu {
                    VStack(alignment: .leading, spacing: 0) {
                        if let textId = selectedTextId {
                            Button(action: {
                                print("[DEBUG] 텍스트 수정 버튼 클릭됨")
                                // 텍스트 수정 로직
                                showObjectMenu = false
                            }) {
                                Label("텍스트 수정", systemImage: "pencil")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            Divider().padding(.horizontal, 12)
                            Button(action: {
                                // 텍스트 삭제 로직
                                showObjectMenu = false
                            }) {
                                Label("텍스트 삭제", systemImage: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                        } else if let stickerId = selectedStickerId {
                            Button(action: {
                                // 크기 조절 로직
                                showObjectMenu = false
                            }) {
                                Label("크기 조절", systemImage: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            Divider().padding(.horizontal, 12)
                            Button(action: {
                                // 스티커 삭제 로직
                                showObjectMenu = false
                            }) {
                                Label("스티커 삭제", systemImage: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(alignment: .center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 10)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .zIndex(9999)
                    .position(x: objectMenuPosition.x, y: objectMenuPosition.y)
                    .onAppear {
                        print("[DEBUG] 스티커 메뉴 렌더링됨 - showObjectMenu: \(showObjectMenu), selectedTextId: \(String(describing: selectedTextId)), selectedStickerId: \(String(describing: selectedStickerId))")
                    }
                }
                
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
                    showTopLoader2ContextMenu: $showTopLoader2ContextMenu,
                    onClosePopupMenus: {
                        print("[DEBUG] 🔥 PhotoEditorView onClosePopupMenus 콜백 실행됨!")
                        showContextMenu = false
                        showTopLoader1ContextMenu = nil
                        showTopLoader2ContextMenu = nil
                        showObjectMenu = false
                        activeContextMenu = nil  // 활성 컨텍스트 메뉴 상태도 초기화
                    }
                )
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ViewPreferenceKeys.RootFrameKey.self, value: geo.frame(in: .global))
                }
            )
            .coordinateSpace(name: "RootSpace")
            .onPreferenceChange(ViewPreferenceKeys.RootFrameKey.self) { frame in
                self.rootOrigin = frame.origin
            }
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            .coordinateSpace(name: "CanvasSpace")
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .sheet(isPresented: $showPhotoPicker) {
            let emptyCount = [photo1.originalImage, photo2.originalImage].filter { $0 == nil }.count
            SystemPhotoPicker(
                allowsMultipleSelection: emptyCount > 1,
                maxSelection: emptyCount == 0 ? 1 : emptyCount
            ) { images in
                switch photoPickerMode {
                case .전체, .비어있는:
                    if images.count == 2 {
                        if photo1.originalImage == nil && photo2.originalImage == nil {
                            photo1.setImage(images[0], boxSize: baseBoxSize)
                            photo2.setImage(images[1], boxSize: baseBoxSize)
                        } else if photo1.originalImage == nil {
                            photo1.setImage(images[0], boxSize: baseBoxSize)
                            if images.count > 1 { photo2.setImage(images[1], boxSize: baseBoxSize) }
                        } else if photo2.originalImage == nil {
                            photo2.setImage(images[0], boxSize: baseBoxSize)
                            if images.count > 1 { photo1.setImage(images[1], boxSize: baseBoxSize) }
                        }
                    } else if images.count == 1 {
                        if photo1.originalImage == nil {
                            photo1.setImage(images[0], boxSize: baseBoxSize)
                        } else if photo2.originalImage == nil {
                            photo2.setImage(images[0], boxSize: baseBoxSize)
                        } else if let idx = selectedBoxIndex {
                            if idx == 1 { photo1.setImage(images[0], boxSize: baseBoxSize) }
                            else { photo2.setImage(images[0], boxSize: baseBoxSize) }
                        }
                    }
                case .박스1:
                    if images.count > 0 {
                        photo1.setImage(images[0], boxSize: baseBoxSize)
                    }
                case .박스2:
                    if images.count > 0 {
                        photo2.setImage(images[0], boxSize: baseBoxSize)
                    }
                }
                showPhotoPicker = false
            }
        }
        .alert("사진이 이미 선택되어있습니다", isPresented: $showAlreadySelectedAlert) {
            Button("확인", role: .cancel) {}
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
    
    private func swapPhotos() {
        let image1 = photo1.originalImage
        let scale1 = photo1.scale
        let offset1 = photo1.offset
        let cover1 = photo1.coverScale
        
        photo1.originalImage = photo2.originalImage
        photo1.scale = photo2.scale
        photo1.offset = photo2.offset
        photo1.coverScale = photo2.coverScale
        
        photo2.originalImage = image1
        photo2.scale = scale1
        photo2.offset = offset1
        photo2.coverScale = cover1
    }
    
    private func duplicatePhoto(from: PhotoState, to: PhotoState) {
        guard let image = from.originalImage else { return }
        to.originalImage = UIImage(data: image.pngData() ?? Data())
        to.scale = from.scale
        to.offset = from.offset
        to.coverScale = from.coverScale
    }
    
    private func showTopLoaderMenu(for photo: PhotoState) {
        selectedPhotoForTopLoader = photo
        showTopLoaderLibrary = true
    }
}

#Preview {
    PhotoEditorView(
        showSafeFrame: .constant(true),
        photo1: PhotoState(),
        photo2: PhotoState(),
        topLoader1: TopLoaderState(),
        topLoader2: TopLoaderState(),
        showPhotoPicker: .constant(false),
        showContextMenu: .constant(false),
        selectedMenu: .constant(nil),
        showTopLoader1ContextMenu: .constant(false as Bool?),
        showTopLoader2ContextMenu: .constant(false as Bool?),
        showObjectMenu: .constant(false)
    )
}
