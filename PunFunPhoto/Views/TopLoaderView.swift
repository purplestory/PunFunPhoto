import SwiftUI
import UniformTypeIdentifiers
//import ZipArchive

// 컨텍스트 메뉴 스타일을 위한 ViewModifier
private struct ContextMenuLabelStyle: ViewModifier {
    let isDestructive: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isDestructive ? .red : .primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

// ViewModifier를 쉽게 사용하기 위한 View extension
private extension View {
    func contextMenuLabelStyle(isDestructive: Bool = false) -> some View {
        modifier(ContextMenuLabelStyle(isDestructive: isDestructive))
    }
}

struct TopLoaderView: View {
    @ObservedObject var state: TopLoaderState

    @State private var showTextEditor = false
    @State private var contextMenuPosition: CGPoint = .zero {
        didSet {
            print("[DEBUG] contextMenuPosition 변경: \(contextMenuPosition)")
        }
    }
    @State private var selectedStickerId: UUID? = nil
    @State private var selectedTextId: UUID? = nil
    @State private var showObjectMenu = false
    @State private var editingTextItem: TextItem? = nil
    let boxSize: CGSize
    let boxOrigin: CGPoint
    let scaleFactor: CGFloat
    @State private var contextMenuBoxIndex: Int? = nil
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    @Binding var selectedMenu: MenuType?
    @Binding var showTopLoaderContextMenu: Bool?
    @State private var showTopLoaderLibrary = false
    @State private var showContextMenu: Bool = false
    @State private var showSaveDialog = false
    @State private var newTopLoaderName = ""
    @State private var lastEmptyTapPosition: CGPoint
    
    // 스티커 터치 콜백
    var onStickerTapped: ((UUID, CGPoint) -> Void)? = nil
    var onTextTapped: ((UUID, CGPoint) -> Void)? = nil
    // 탑로더 터치 시 다른 메뉴들을 닫는 콜백
    var onTopLoaderTapped: (() -> Void)? = nil
    
    // 원본 크기 기준 cornerRadius
    private let baseCornerRadius: CGFloat = 30
    
    init(state: TopLoaderState, boxSize: CGSize, boxOrigin: CGPoint = .zero, scaleFactor: CGFloat = 1.0, showToast: Binding<Bool>, toastMessage: Binding<String>, selectedMenu: Binding<MenuType?>, showTopLoaderContextMenu: Binding<Bool?>, onStickerTapped: ((UUID, CGPoint) -> Void)? = nil, onTextTapped: ((UUID, CGPoint) -> Void)? = nil, onTopLoaderTapped: (() -> Void)? = nil) {
        self.state = state
        self.boxSize = boxSize
        self.boxOrigin = boxOrigin
        self.scaleFactor = scaleFactor
        self._showToast = showToast
        self._toastMessage = toastMessage
        self._selectedMenu = selectedMenu
        self._showTopLoaderContextMenu = showTopLoaderContextMenu
        self.onStickerTapped = onStickerTapped
        self.onTextTapped = onTextTapped
        self.onTopLoaderTapped = onTopLoaderTapped
        // 박스 중앙으로 초기화
        self._lastEmptyTapPosition = State(initialValue: CGPoint(x: boxSize.width/2, y: boxSize.height/2))
    }
    
    var body: some View {
        // 스케일된 cornerRadius 계산
        let scaledCornerRadius = baseCornerRadius * (boxSize.width / 685)  // 685는 baseBoxSize.width
        
        GeometryReader { geometry in
            ZStack {
                // 1. 탑로더/포토박스 본체 (clipShape 적용)
                ZStack {
                    if state.showTopLoader {
                // 탑로더 외부 프레임 (포토박스와 동일한 cornerRadius 사용)
                RoundedRectangle(cornerRadius: scaledCornerRadius)
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 10)
                            .frame(width: boxSize.width+10, height: boxSize.height+10)
                        // 내부 컨텐츠 컨테이너
                        ZStack {
                                                    // 탑로더 터치 영역 (실제 컨텐츠가 있는 영역만)
                        if state.isAttached && state.showTopLoader {
                            // 실제 탑로더 컨텐츠가 있을 때만 터치 영역 활성화
                            // 스티커와 텍스트가 없는 빈 공간만 터치 가능하도록 설정
                            Color.clear
                                .contentShape(Rectangle())
                                .frame(width: boxSize.width, height: boxSize.height)
                                .zIndex(50) // 스티커와 텍스트보다 낮게 설정
                                .allowsHitTesting(true)
                                .onTapGesture {
                                    print("[DEBUG] 탑로더 터치 영역 감지됨")
                                    // 다른 메뉴들을 먼저 닫기
                                    onTopLoaderTapped?()
                                    selectedMenu = nil
                                    
                                    // 탑로더 메뉴 토글
                                    if showTopLoaderContextMenu == true {
                                        showTopLoaderContextMenu = false
                                        print("[DEBUG] 탑로더 메뉴 닫힘")
                                    } else {
                                        showTopLoaderContextMenu = true
                                        print("[DEBUG] 탑로더 메뉴 열림 - 중앙 위치")
                                    }
                                    showObjectMenu = false
                                    selectedStickerId = nil
                                    selectedTextId = nil
                                    print("[DEBUG] [탑로더 터치] showTopLoaderContextMenu=\(showTopLoaderContextMenu)")
                                }
                        }
                            // 스티커들
                            ForEach(state.stickers) { sticker in
                                stickerView(for: sticker)
                            }
                            
                            // 텍스트들 (항상 위에 보이도록)
                            ZStack {
                                ForEach(state.texts, id: \.id) { textItem in
                                    textView(for: textItem, geometry: geometry)
                                        .contentShape(Rectangle())
                                        .zIndex(200) // 스티커보다 높게 설정
                                }
                            }
                        }
                    }
                }
                .frame(width: boxSize.width, height: boxSize.height)
                .clipShape(RoundedRectangle(cornerRadius: scaledCornerRadius))
                // 2. 컨텍스트 메뉴 (clipShape 영향 X)
                if showContextMenu && !showObjectMenu {
                    // [탑로더] 메뉴만!
                    let menuWidth: CGFloat = 220
                    let menuHeight: CGFloat = 200
                    let minX = menuWidth / 2
                    let maxX = boxSize.width - menuWidth / 2
                    let minY = menuHeight / 2
                    let maxY = boxSize.height - menuHeight / 2
                    let clampedX = min(max(contextMenuPosition.x, minX), maxX)
                    let clampedY = min(max(contextMenuPosition.y, minY), maxY)
                    ZStack {
                        Color.black.opacity(0.001)
                            .onTapGesture {
                                showContextMenu = false
                            }
                            .zIndex(0)
                            .allowsHitTesting(true)
                        VStack(spacing: 0) {
                            if state.isAttached {
                                Button(action: {
                                    let newTextItem = TextItem(
                                        text: "",
                                        fontSize: 32,
                                        textColor: .black,
                                        style: .plain,
                                        strokeColor: .clear,
                                        position: contextMenuPosition,
                                        rotation: .zero,
                                        scale: 1.0
                                    )
                                    editingTextItem = newTextItem
                                    selectedTextId = nil  // 새로운 텍스트 추가 시 selectedTextId를 nil로 설정
                                    showTextEditor = true
                                    showContextMenu = false
                                }) {
                                    Label("[탑로더] 텍스트 추가", systemImage: "text.badge.plus")
                                        .contextMenuLabelStyle()
                                }
                                Divider().padding(.horizontal, 12)
                                Button(action: {
                                    showTopLoaderLibrary = true
                                }) {
                                    Label("[탑로더] 탑로더 관리", systemImage: "rectangle.stack.badge.plus")
                                        .contextMenuLabelStyle()
                                }
                                Divider().padding(.horizontal, 12)
                                Button(action: {
                                    showSaveDialog = true
                                }) {
                                    Label("[탑로더] 탑로더 저장", systemImage: "square.and.arrow.down")
                                        .contextMenuLabelStyle()
                                }
                                Divider().padding(.horizontal, 12)
                                Button(action: {
                                    state.showTopLoader.toggle()
                                    showContextMenu = false
                                    contextMenuPosition = .zero
                                    if !state.showTopLoader {
                                        showContextMenu = false
                                        selectedMenu = nil
                                    }
                                    print("[DEBUG] 탑로더 가시성 변경: \(state.showTopLoader ? "보임" : "가려짐")")
                                }) {
                                    Label(state.showTopLoader ? "[탑로더] 탑로더 가리기" : "[탑로더] 탑로더 보기", systemImage: state.showTopLoader ? "eye.slash" : "eye")
                                        .contextMenuLabelStyle()
                                }
                                Divider().padding(.horizontal, 12)
                                Button(action: {
                                    state.detach()
                                    showContextMenu = false
                                    selectedMenu = nil  // 메뉴 상태 초기화
                                    contextMenuPosition = .zero  // 위치 초기화
                                    print("[DEBUG] 탑로더 제거: detach() 호출됨, 메뉴 상태 초기화")
                                }) {
                                    Label("[탑로더] 탑로더 제거", systemImage: "xmark.circle")
                                        .contextMenuLabelStyle(isDestructive: true)
                                }
                            } else {
                                Button(action: {
                                    state.attach()
                                    showContextMenu = false
                                }) {
                                    Label("[탑로더] 탑로더 관리", systemImage: "rectangle.stack.badge.plus")
                                        .contextMenuLabelStyle()
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 10)
                        .fixedSize(horizontal: true, vertical: false)
                        .scaleEffect(1 / scaleFactor)
                        .zIndex(1)
                        .allowsHitTesting(true)
                    }
                    .frame(width: boxSize.width, height: boxSize.height)
                    .position(x: clampedX, y: clampedY)
                    .zIndex(9998)
                    .onAppear {
                        print("[DEBUG] 컨텍스트 메뉴 뷰 onAppear, contextMenuPosition=\(contextMenuPosition)")
                    }
                }
                // 스티커 메뉴는 PhotoEditorView에서 관리됨
            }
            .coordinateSpace(name: "CanvasSpace")
            .overlay(
                GeometryReader { geo in
                    Color(.clear)
                        .preference(key: ViewPreferenceKeys.TopLoaderFrameKey.self, value: [0: geo.frame(in: .named("CanvasSpace"))])
                }
            )
            .onTapGesture { location in
                if !showContextMenu && !showObjectMenu {
                    selectedMenu = nil
                    contextMenuPosition = location
                    showContextMenu = true
                }
            }
            .sheet(isPresented: $showTextEditor, onDismiss: {
                editingTextItem = nil
                showContextMenu = false
                showObjectMenu = false
            }) {
                if let editingTextItem = editingTextItem {
                    TextStickerEditorView(
                        isPresented: $showTextEditor,
                        initialText: editingTextItem.text,
                        initialFontSize: editingTextItem.fontSize,
                        initialColor: editingTextItem.textColor,
                        initialStyle: editingTextItem.style,
                        initialStrokeColor: editingTextItem.strokeColor,
                        initialFontInfo: editingTextItem.fontInfo,
                        isEdit: selectedTextId != nil,  // selectedTextId가 nil이면 새로운 텍스트 추가
                        onComplete: { data in
                            if let textId = selectedTextId {
                                state.selectedItemId = textId
                                state.updateText(
                                    textId,
                                    text: data.text,
                                    fontSize: data.fontSize,
                                    textColor: data.textColor,
                                    style: data.style,
                                    strokeColor: data.strokeColor,
                                    fontInfo: data.fontInfo,
                                    highlightColor: data.highlightColor
                                )
                            } else {
                                print("[DEBUG] addText 호출: contextMenuPosition=\(contextMenuPosition), boxSize=\(boxSize)")
                                print("[DEBUG] addText 호출: parentView=TopLoaderView > ZStack > TextStickerView")
                                state.addText(
                                    data.text,
                                    fontSize: data.fontSize,
                                    textColor: data.textColor,
                                    style: data.style,
                                    strokeColor: data.strokeColor,
                                    fontInfo: data.fontInfo,
                                    highlightColor: data.highlightColor,
                                    boxSize: boxSize,
                                    position: (contextMenuPosition == .zero ? nil : contextMenuPosition)
                                )
                            }
                            showObjectMenu = false
                        }
                    )
                    .onAppear {
                        print("[DEBUG] TextStickerEditorView sheet 표시됨")
                    }
                }
            }
            .sheet(isPresented: $showTopLoaderLibrary) {
                TopLoaderLibraryView(isPresented: $showTopLoaderLibrary) { savedTopLoader in
                    state.loadFrom(savedTopLoader)
                    state.attach()
                    // contextMenuPosition을 박스의 정중앙으로 초기화
                    contextMenuPosition = CGPoint(x: boxSize.width / 2, y: boxSize.height / 2)
                    showContextMenu = false
                    showObjectMenu = false
                    selectedStickerId = nil
                    selectedTextId = nil
                    print("[DEBUG] 탑로더 선택 완료: contextMenuPosition 중앙으로 초기화, attach() 호출됨")
                }
            }
            .alert("탑로더 저장", isPresented: $showSaveDialog) {
                TextField("탑로더 이름", text: $newTopLoaderName)
                Button("취소", role: .cancel) {
                    newTopLoaderName = ""
                }
                Button("저장") {
                    state.saveTopLoader(name: newTopLoaderName.isEmpty ? "내 탑로더 \(Date().formatted(date: .numeric, time: .shortened))" : newTopLoaderName)
                    showToast = true
                    toastMessage = "탑로더가 저장되었습니다"
                    showContextMenu = false
                    newTopLoaderName = ""
                }
            } message: {
                Text("저장할 탑로더의 이름을 입력하세요")
            }
        }
        .onChange(of: showObjectMenu) { newValue in
            print("[DEBUG] showObjectMenu changed: \(newValue)")
        }


    }
    
@ViewBuilder
private func textView(for textItem: TextItem, geometry: GeometryProxy) -> some View {
    let dragGesture = DragGesture(coordinateSpace: .local)
        .onChanged { value in
            let newPosition = value.location
            let x = min(max(newPosition.x, textItem.fontSize/2), boxSize.width - textItem.fontSize/2)
            let y = min(max(newPosition.y, textItem.fontSize/2), boxSize.height - textItem.fontSize/2)
            state.updateTextPosition(textItem.id, position: CGPoint(x: x, y: y))
        }
        .onEnded { value in
            let newPosition = value.location
            let x = min(max(newPosition.x, textItem.fontSize/2), boxSize.width - textItem.fontSize/2)
            let y = min(max(newPosition.y, textItem.fontSize/2), boxSize.height - textItem.fontSize/2)
            state.updateTextPosition(textItem.id, position: CGPoint(x: x, y: y))
        }

    let rotationGesture = RotationGesture()
        .onChanged { angle in
            state.updateTextRotation(textItem.id, rotation: angle)
        }
        .onEnded { _ in }

    let magnificationGesture = MagnificationGesture()
        .onChanged { value in
            let newFontSize = max(10, min(200, textItem.fontSize * value))
            print("[DEBUG] magnificationGesture onChanged: \(newFontSize)")
            state.updateTextFontSize(textItem.id, fontSize: newFontSize)
        }
        .onEnded { _ in
            print("[DEBUG] magnificationGesture onEnded")
        }

    TextStickerView(textItem: textItem)
        .position(textItem.position)
        .zIndex(200) // 스티커보다 높게 설정
        .rotationEffect(textItem.rotation, anchor: .center)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .gesture(dragGesture)
        .simultaneousGesture(rotationGesture)
        .simultaneousGesture(magnificationGesture)
        .onTapGesture {
            print("[DEBUG] textView onTapGesture: \(textItem.id)")
            print("[DEBUG] textItem position: \(textItem.position)")
            onTextTapped?(textItem.id, textItem.position)
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 10) {
            print("[DEBUG] textView onLongPressGesture: \(textItem.id)")
            editingTextItem = textItem
            selectedTextId = textItem.id
            state.selectedItemId = textItem.id
            DispatchQueue.main.async {
                showTextEditor = true
            }
        }
}

    @ViewBuilder
private func stickerView(for sticker: StickerItem) -> some View {
    if let image = sticker.image {
        let dragGesture = DragGesture(coordinateSpace: .named("CanvasSpace"))
            .onChanged { value in
                let newPosition = value.location
                let x = min(max(newPosition.x, sticker.size/2), boxSize.width - sticker.size/2)
                let y = min(max(newPosition.y, sticker.size/2), boxSize.height - sticker.size/2)
                state.updateStickerPosition(sticker.id, position: CGPoint(x: x, y: y))
            }
        let rotationGesture = RotationGesture()
            .onChanged { angle in
                state.updateStickerRotation(sticker.id, rotation: angle)
            }
        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                let newSize = max(20, min(400, sticker.size * value))
                state.updateStickerSize(sticker.id, size: newSize)
            }
        Image(uiImage: image)
            .resizable()
            .frame(width: sticker.size, height: sticker.size)
            .position(sticker.position)
            .rotationEffect(sticker.rotation)
            .scaleEffect(1/scaleFactor)
            .zIndex(150) // 탑로더 터치 영역보다 높게, 텍스트보다 낮게
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            .gesture(dragGesture)
            .simultaneousGesture(rotationGesture)
            .simultaneousGesture(magnificationGesture)
            .onTapGesture {
                print("[DEBUG] stickerView onTapGesture: \(sticker.id)")
                print("[DEBUG] sticker position: \(sticker.position)")
                onStickerTapped?(sticker.id, sticker.position)
            }
    }
}
    

}

#Preview {
    TopLoaderView(state: TopLoaderState(), boxSize: CGSize(width: 300, height: 400), showToast: .constant(false), toastMessage: .constant(""), selectedMenu: .constant(nil), showTopLoaderContextMenu: .constant(false))
        .background(Color.gray.opacity(0.2))
}

