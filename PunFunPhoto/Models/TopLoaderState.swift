import SwiftUI

class TopLoaderState: ObservableObject {
    @Published var isAttached: Bool = false
    @Published var showTopLoader: Bool = true
    @Published var stickers: [StickerItem] = []
    @Published var texts: [TextItem] = []
    @Published var selectedItemId: UUID? = nil
    @Published var showEditMenu: Bool = false
    @Published var showContextMenu: Bool = false
    @Published var showTextEditor: Bool = false
    @Published var editingTextItem: TextItem? = nil
    
    enum SelectedItemType {
        case sticker
        case text
    }
    
    var selectedItemType: SelectedItemType? {
        guard let id = selectedItemId else { return nil }
        if stickers.contains(where: { $0.id == id }) {
            return .sticker
        } else if texts.contains(where: { $0.id == id }) {
            return .text
        }
        return nil
    }
    
    var selectedSticker: StickerItem? {
        guard let id = selectedItemId else { return nil }
        return stickers.first { $0.id == id }
    }
    
    var selectedText: TextItem? {
        guard let id = selectedItemId else { return nil }
        return texts.first { $0.id == id }
    }
    
    // 아이템 선택
    func selectItem(_ id: UUID?) {
        selectedItemId = id
        if id != nil {
            showEditMenu = true
        }
    }
    
    // 선택된 아이템 삭제
    func deleteSelectedItem() {
        guard let id = selectedItemId else { return }
        
        if let index = stickers.firstIndex(where: { $0.id == id }) {
            stickers.remove(at: index)
        } else if let index = texts.firstIndex(where: { $0.id == id }) {
            texts.remove(at: index)
        }
        
        selectedItemId = nil
        showEditMenu = false
    }
    
    // 선택된 텍스트 아이템 업데이트
    func updateSelectedText(text: String? = nil, fontSize: CGFloat? = nil, textColor: Color? = nil, style: TextStickerView.TextStyle? = nil, strokeColor: Color? = nil, fontInfo: FontInfo? = nil) {
        guard let id = selectedItemId,
              let index = texts.firstIndex(where: { $0.id == id }) else { return }
        
        let updatedItem = texts[index]
        if let text = text { updatedItem.text = text }
        if let fontSize = fontSize { updatedItem.fontSize = fontSize }
        if let textColor = textColor { updatedItem.textColor = textColor }
        if let style = style { updatedItem.style = style }
        if let strokeColor = strokeColor { updatedItem.strokeColor = strokeColor }
        if let fontInfo = fontInfo { updatedItem.fontInfo = fontInfo }
        
        texts[index] = updatedItem
    }
    
    // 선택된 스티커 아이템 크기 업데이트
    func updateSelectedStickerSize(_ size: CGFloat) {
        guard let id = selectedItemId,
              let index = stickers.firstIndex(where: { $0.id == id }) else { return }
        
        stickers[index].size = size
    }
    
    func attach() {
        DispatchQueue.main.async {
            self.isAttached = true
            self.showTopLoader = true
            print("[DEBUG] attach() 호출됨, isAttached=\(self.isAttached), showTopLoader=\(self.showTopLoader)")
        }
    }
    
    func detach() {
        isAttached = false
        showTopLoader = false
        stickers.removeAll()
        texts.removeAll()
        selectedItemId = nil
        showEditMenu = false
        showContextMenu = false
        print("[DEBUG] detach() 호출됨: isAttached=\(isAttached), showTopLoader=\(showTopLoader)")
    }
    
    func addSticker(_ image: UIImage) {
        let sticker = StickerItem(
            position: CGPoint(x: 0, y: 0),
            size: 100,
            rotation: .zero,
            image: image
        )
        stickers.append(sticker)
    }
    
    func addText(_ text: String, fontSize: CGFloat, textColor: Color, style: TextStickerView.TextStyle, strokeColor: Color, fontInfo: FontInfo? = nil, highlightColor: Color? = nil, boxSize: CGSize, position: CGPoint? = nil) {
        let textPosition = position ?? CGPoint(x: boxSize.width / 2, y: boxSize.height / 2)
        let textItem = TextItem(
            text: text,
            fontSize: fontSize,
            textColor: textColor,
            style: style,
            strokeColor: strokeColor,
            fontInfo: fontInfo,
            highlightColor: highlightColor,
            position: textPosition
        )
        texts.append(textItem)
        print("[DEBUG] addText 호출됨, texts.count: \(texts.count), text: \(text), pos: \(textItem.position)")
    }
    
    func addSFSymbolSticker(_ symbolName: String, size: CGFloat = 50, color: Color = .primary, boxSize: CGSize, position: CGPoint? = nil) {
        let stickerPosition = position ?? CGPoint(x: boxSize.width / 2, y: boxSize.height / 2)
        
        // SF Symbol을 UIImage로 변환
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: config)?.withTintColor(UIColor(color), renderingMode: .alwaysOriginal)
        
        if let image = symbolImage {
            let stickerItem = StickerItem(
                position: stickerPosition,
                size: size,
                rotation: .zero,
                image: image
            )
            stickers.append(stickerItem)
            print("[DEBUG] addSFSymbolSticker 호출됨, stickers.count: \(stickers.count), symbol: \(symbolName)")
        }
    }
    
    func openTextEditor(boxSize: CGSize) {
        let newTextItem = TextItem(
            text: "",
            fontSize: 32,
            textColor: .black,
            style: .plain,
            strokeColor: .clear,
            fontInfo: nil,
            highlightColor: nil,
            position: CGPoint(x: boxSize.width / 2, y: boxSize.height / 2)
        )
        editingTextItem = newTextItem
        showTextEditor = true
        print("[DEBUG] openTextEditor 호출됨")
    }
    
    func updateStickerPosition(_ id: UUID, position: CGPoint) {
        if let index = stickers.firstIndex(where: { $0.id == id }) {
            stickers[index].position = position
        }
    }
    
    func updateTextPosition(_ id: UUID, position: CGPoint) {
        if let index = texts.firstIndex(where: { $0.id == id }) {
            texts[index].position = position
            texts = texts.map { $0 }
        }
    }
    
    func updateStickerRotation(_ id: UUID, rotation: Angle) {
        if let index = stickers.firstIndex(where: { $0.id == id }) {
            stickers[index].rotation = rotation
        }
    }
    
    func updateTextRotation(_ id: UUID, rotation: Angle) {
        if let index = texts.firstIndex(where: { $0.id == id }) {
            texts[index].rotation = rotation
            texts = texts.map { $0 }
        }
    }
    
    func updateText(_ id: UUID, text: String, fontSize: CGFloat, textColor: Color, style: TextStickerView.TextStyle, strokeColor: Color, fontInfo: FontInfo?, highlightColor: Color?) {
        if let index = texts.firstIndex(where: { $0.id == id }) {
            texts[index].text = text
            texts[index].fontSize = fontSize
            texts[index].textColor = textColor
            texts[index].style = style
            texts[index].strokeColor = strokeColor
            texts[index].fontInfo = fontInfo
            texts[index].highlightColor = highlightColor
        }
    }

    func removeText(_ id: UUID) {
        texts.removeAll { $0.id == id }
    }

    func removeSticker(_ id: UUID) {
        stickers.removeAll { $0.id == id }
    }
    
    // 다른 TopLoaderState로부터 복사
    func copyFrom(_ other: TopLoaderState) {
        stickers = other.stickers.compactMap { sticker in
            guard let image = sticker.image else { return nil }
            return StickerItem(
                position: sticker.position,
                size: sticker.size,
                rotation: sticker.rotation,
                image: image
            )
        }
        
        texts = other.texts.map { text in
            TextItem(
                text: text.text,
                fontSize: text.fontSize,
                textColor: text.textColor,
                style: text.style,
                strokeColor: text.strokeColor,
                fontInfo: text.fontInfo,
                highlightColor: text.highlightColor,
                position: text.position,
                rotation: text.rotation
            )
        }
    }
    
    // 저장된 탑로더 데이터로부터 로드
    func loadFrom(_ savedTopLoader: SavedTopLoader) {
        stickers = savedTopLoader.stickers
        texts = savedTopLoader.texts
        selectedItemId = nil
        showEditMenu = false
        print("[DEBUG] 탑로더 데이터 로드 완료: stickers=\(stickers.count), texts=\(texts.count)")
    }
    
    // 현재 상태를 저장 가능한 형태로 변환
    func toSavedTopLoader(name: String = "Untitled") -> SavedTopLoader {
        return SavedTopLoader(
            name: name,
            stickers: stickers,
            texts: texts
        )
    }
    
    // 자동 저장을 위한 상태 저장
    func saveState() -> SavedTopLoader {
        return SavedTopLoader(
            name: "AutoSave",
            stickers: stickers,
            texts: texts
        )
    }
    
    func updateTextFontSize(_ id: UUID, fontSize: CGFloat) {
        if let index = texts.firstIndex(where: { $0.id == id }) {
            texts[index].fontSize = fontSize
            texts = texts.map { $0 }
        }
    }
    
    func updateStickerSize(_ id: UUID, size: CGFloat) {
        if let idx = stickers.firstIndex(where: { $0.id == id }) {
            stickers[idx].size = size
        }
    }

    private static let savedKey = "SavedTopLoaders"

    static func loadSavedTopLoaders() -> [SavedTopLoader] {
        if let data = UserDefaults.standard.data(forKey: savedKey),
           let decoded = try? JSONDecoder().decode([SavedTopLoader].self, from: data) {
            return decoded
        }
        return []
    }

    static func saveAllTopLoaders(_ loaders: [SavedTopLoader]) {
        if let encoded = try? JSONEncoder().encode(loaders) {
            UserDefaults.standard.set(encoded, forKey: savedKey)
        }
    }

    func saveTopLoader(name: String? = nil) {
        var all = TopLoaderState.loadSavedTopLoaders()
        let new = self.toSavedTopLoader(name: name ?? "내 탑로더 \(Date().formatted(date: .numeric, time: .shortened))")
        
        // 새로운 탑로더 추가
        all.append(new)
        
        TopLoaderState.saveAllTopLoaders(all)
        print("[DEBUG] 탑로더 저장됨: \(new.name)")
    }

    func selectTopLoader() {
        let all = TopLoaderState.loadSavedTopLoaders()
        guard let last = all.last else {
            print("[DEBUG] 저장된 탑로더 없음")
            return
        }
        self.loadFrom(last)
        print("[DEBUG] 탑로더 불러오기 완료: \(last.name)")
    }
} 