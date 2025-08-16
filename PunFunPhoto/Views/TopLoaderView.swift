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
    @Binding var showContextMenu: Bool
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
    @Binding var showTopLoaderContextMenu: Bool
    @State private var showTopLoaderLibrary = false
    @State private var showSaveDialog = false
    @State private var newTopLoaderName = ""
    @State private var lastEmptyTapPosition: CGPoint
    
    // 원본 크기 기준 cornerRadius
    private let baseCornerRadius: CGFloat = 30
    
    init(state: TopLoaderState, boxSize: CGSize, boxOrigin: CGPoint = .zero, scaleFactor: CGFloat = 1.0, showToast: Binding<Bool>, toastMessage: Binding<String>, selectedMenu: Binding<MenuType?>, showContextMenu: Binding<Bool>, showTopLoaderContextMenu: Binding<Bool>) {
        self.state = state
        self.boxSize = boxSize
        self.boxOrigin = boxOrigin
        self.scaleFactor = scaleFactor
        self._showToast = showToast
        self._toastMessage = toastMessage
        self._selectedMenu = selectedMenu
        self._showContextMenu = showContextMenu
        self._showTopLoaderContextMenu = showTopLoaderContextMenu
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
                            // DragGesture가 걸린 빈 공간 레이어 (항상 맨 아래)
                            Color.clear
                            // Color.red.opacity(0.1) 
                                .contentShape(Rectangle())
                                .frame(width: boxSize.width, height: boxSize.height)
                                .zIndex(10)
                                .allowsHitTesting(true)
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                        .onEnded { value in
                                            let location = value.location
                                            // 더 엄밀한 hit test: 텍스트
                                            let isOnText = state.texts.contains { textItem in
                                                let textFrame = CGRect(
                                                    x: textItem.position.x - CGFloat(textItem.fontSize)/2,
                                                    y: textItem.position.y - CGFloat(textItem.fontSize)/2,
                                                    width: CGFloat(textItem.fontSize),
                                                    height: CGFloat(textItem.fontSize)
                                                )
                                                return textFrame.contains(location)
                                            }
                                            // 더 엄밀한 hit test: 스티커
                                            let isOnSticker = state.stickers.contains { sticker in
                                                let stickerFrame = CGRect(
                                                    x: sticker.position.x - sticker.size/2,
                                                    y: sticker.position.y - sticker.size/2,
                                                    width: sticker.size,
                                                    height: sticker.size
                                                )
                                                return stickerFrame.contains(location)
                                            }
                                            print("[DEBUG] DragGesture: location=\(location), isOnText=\(isOnText), isOnSticker=\(isOnSticker)")
                                            // 빈 공간을 탭한 경우에만 메뉴 상태 갱신
                                            if !isOnText && !isOnSticker {
                                                contextMenuPosition = location
                                                lastEmptyTapPosition = location
                                                showContextMenu = true
                                                showObjectMenu = false
                                                selectedStickerId = nil
                                                selectedTextId = nil
                                                print("[DEBUG] [빈공간탭] contextMenuPosition=\(contextMenuPosition), showContextMenu=\(showContextMenu), showObjectMenu=\(showObjectMenu), selectedTextId=\(String(describing: selectedTextId)), selectedStickerId=\(String(describing: selectedStickerId))")
                                            } else {
                                                // 스티커/텍스트 위를 탭한 경우에는 DragGesture에서 아무 동작도 하지 않음
                                                print("[DEBUG] [스티커/텍스트 hit] DragGesture 무시: location=\(location)")
                                            }
                                            print("[DEBUG] DragGesture: location=\(value.location)")
                                        }
                                )
                            // 스티커들
                            ForEach(state.stickers) { sticker in
                                stickerView(for: sticker)
                            }
                            
                            // 텍스트들 (항상 위에 보이도록)
                            ZStack {
                                ForEach(state.texts, id: \.id) { textItem in
                                    textView(for: textItem, geometry: geometry)
                                        .contentShape(Rectangle())
                                        .zIndex(10)
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
                if showObjectMenu && !showContextMenu {
                    // [스티커] 메뉴만!
                    ZStack {
                        Color.black.opacity(0.001)
                            .onTapGesture {
                                showObjectMenu = false
                            }
                            .zIndex(0)
                            .allowsHitTesting(true)
                        VStack(alignment: .leading, spacing: 0) {
                            if let textId = selectedTextId {
                                Button(action: {
                                    print("[DEBUG] 텍스트 수정 버튼 클릭됨")
                                    print("[DEBUG] selectedTextId: \(selectedTextId?.uuidString ?? "nil")")
                                    print("[DEBUG] state.texts ids: \(state.texts.map { $0.id.uuidString })")
                                    if let textId = selectedTextId,
                                       let textItem = state.texts.first(where: { $0.id == textId }) {
                                        editingTextItem = TextItem(
                                            id: textItem.id,
                                            text: textItem.text,
                                            fontSize: textItem.fontSize,
                                            textColor: textItem.textColor,
                                            style: textItem.style,
                                            strokeColor: textItem.strokeColor,
                                            fontInfo: textItem.fontInfo,
                                            highlightColor: textItem.highlightColor,
                                            position: textItem.position,
                                            rotation: textItem.rotation,
                                            scale: textItem.scale
                                        )
                                        print("[DEBUG] editingTextItem 할당됨: \(editingTextItem?.text ?? "nil")")
                                        selectedTextId = textId
                                        state.selectedItemId = textId
                                        showObjectMenu = false
                                        showContextMenu = false
                                        DispatchQueue.main.async {
                                            showTextEditor = true
                                            print("[DEBUG] showTextEditor = true")
                                        }
                                    } else {
                                        print("[DEBUG] 텍스트 수정 진입 실패: 조건 불일치")
                                    }
                                }) {
                                    Label("[스티커] 텍스트 수정", systemImage: "pencil")
                                        .contextMenuLabelStyle()
                                }
                                Divider().padding(.horizontal, 12)
                                Button(action: {
                                    state.removeText(textId)
                                    showObjectMenu = false
                                }) {
                                    Label("[스티커] 텍스트 삭제", systemImage: "trash")
                                        .contextMenuLabelStyle(isDestructive: true)
                                }
                            } else if let stickerId = selectedStickerId {
                                Button(action: {
                                    // 크기 조절 로직 추가 예정
                                }) {
                                    Label("[스티커] 크기 조절", systemImage: "arrow.up.left.and.arrow.down.right")
                                        .contextMenuLabelStyle()
                                }
                                Divider().padding(.horizontal, 12)
                                Button(action: {
                                    state.removeSticker(stickerId)
                                    showObjectMenu = false
                                }) {
                                    Label("[스티커] 스티커 삭제", systemImage: "trash")
                                        .contextMenuLabelStyle(isDestructive: true)
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
                        .position(contextMenuPosition)
                    }
                    .frame(width: boxSize.width, height: boxSize.height)
                    .zIndex(9998)
                }
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
        .onChange(of: showContextMenu) { newValue in
            print("[DEBUG] showContextMenu changed: \(newValue)")
            if newValue && !showObjectMenu {
                if lastEmptyTapPosition == .zero {
                    lastEmptyTapPosition = CGPoint(x: boxSize.width/2, y: boxSize.height/2)
                }
                contextMenuPosition = lastEmptyTapPosition
                print("[DEBUG] [onChange] 탑로더 메뉴 contextMenuPosition 강제 갱신: \(contextMenuPosition)")
            }
        }
        // 탑로더 컨텍스트 메뉴 오버레이
        .overlay(
            Group {
                if showTopLoaderContextMenu {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(contextMenuItems()) { item in
                            Button(action: {
                                withAnimation {
                                    item.action()
                                    showTopLoaderContextMenu = false
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
                            .disabled(!item.isEnabled)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    .frame(width: 200)
                    .position(
                        x: contextMenuPosition.x,
                        y: contextMenuPosition.y
                    )
                    .zIndex(9998)
                }
            }
        )
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
        .zIndex(100)
        .rotationEffect(textItem.rotation, anchor: .center)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .gesture(dragGesture)
        .simultaneousGesture(rotationGesture)
        .simultaneousGesture(magnificationGesture)
        .onTapGesture {
            print("[DEBUG] textView onTapGesture: \(textItem.id)")
            print("[DEBUG] textItem position: \(textItem.position)")
            contextMenuPosition = textItem.position
            selectedTextId = textItem.id
            showObjectMenu = true
            showContextMenu = false
            selectedStickerId = nil
            print("[DEBUG] [텍스트스티커탭] contextMenuPosition=\(contextMenuPosition), showContextMenu=\(showContextMenu), showObjectMenu=\(showObjectMenu), selectedTextId=\(String(describing: selectedTextId)), selectedStickerId=\(String(describing: selectedStickerId))")
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
        .highPriorityGesture(
        TapGesture().onEnded {
            print("[DEBUG] highPriorityGesture: text sticker tapped")
            // 스티커 선택 로직
            contextMenuPosition = textItem.position
            selectedTextId = textItem.id
            showObjectMenu = true
            showContextMenu = false
            selectedStickerId = nil
        }
    )
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
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            .gesture(dragGesture)
            .simultaneousGesture(rotationGesture)
            .simultaneousGesture(magnificationGesture)
            .onTapGesture {
                contextMenuPosition = sticker.position
                selectedStickerId = sticker.id
                showObjectMenu = true
                showContextMenu = false
                selectedTextId = nil
            }
    }
}
    
    private func contextMenuItems() -> [MenuItem] {
        var items: [MenuItem] = []
        
        // 탑로더 보기/가리기 메뉴
        let showHideTitle = state.showTopLoader ? "탑로더 가리기" : "탑로더 보기"
        let showHideIcon = state.showTopLoader ? "eye.slash" : "eye"
        items.append(
            MenuItem(title: showHideTitle, icon: showHideIcon) {
                state.showTopLoader.toggle()
                // 탑로더를 가리면 포토박스 컨텍스트 메뉴로 전환 (이제 자동 전환 없음)
                if !state.showTopLoader {
                    showContextMenu = false
                    selectedMenu = nil
                }
            }
        )
        
        // 나머지 메뉴 아이템들...
        return items
    }
}

#Preview {
    TopLoaderView(state: TopLoaderState(), boxSize: CGSize(width: 300, height: 400), showToast: .constant(false), toastMessage: .constant(""), selectedMenu: .constant(nil), showContextMenu: .constant(false))
        .background(Color.gray.opacity(0.2))
}

