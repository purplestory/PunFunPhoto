import SwiftUI
import UIKit

extension TextStickerView {
    enum TextStyle: String, Codable {
        case plain
        case stroke
        case shadow
        case blur
        case highlight
        case inlineStroke
    }
}

struct TextStickerView: View {
    @ObservedObject var textItem: TextItem
    @StateObject private var fontManager = FontManager.shared
    @State private var fontLoadingState: FontLoadingState = .notLoaded
    
    var body: some View {
        Group {
            if let fontInfo = textItem.fontInfo {
                fontLoadableText(fontInfo)
            } else {
                styledText(using: .system(size: textItem.fontSize))
            }
        }
    }
    
    private func fontLoadableText(_ fontInfo: FontInfo) -> some View {
        Group {
            switch fontLoadingState {
            case .notLoaded:
                styledText(using: .system(size: textItem.fontSize))
                    .opacity(0.5)
                    .overlay {
                        ProgressView()
                    }
                    .onAppear {
                        checkAndLoadFont(fontInfo)
                    }
            case .loading(let progress):
                styledText(using: .system(size: textItem.fontSize))
                    .opacity(0.5)
                    .overlay {
                        VStack {
                            ProgressView(value: progress) {
                                Text("폰트 다운로드 중...")
                                    .font(.caption)
                            } currentValueLabel: {
                                Text("\(Int(progress * 100))%")
                                    .font(.caption2)
                            }
                            .frame(width: 100)
                        }
                    }
            case .loaded:
                styledText(using: .custom(fontInfo.name, size: textItem.fontSize))
            case .error(let error):
                styledText(using: .system(size: textItem.fontSize))
                    .overlay {
                        VStack {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.red)
                            Button(action: {
                                checkAndLoadFont(fontInfo)
                            }) {
                                Label("다시 시도", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .padding(4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
            }
        }
    }
    
    private func checkAndLoadFont(_ fontInfo: FontInfo) {
        Task {
            if !fontManager.isDownloaded(fontInfo.name) {
                fontLoadingState = .loading(0)
                do {
                    try await fontManager.downloadFont(fontInfo)
                    await MainActor.run {
                        fontLoadingState = .loaded
                    }
                } catch {
                    await MainActor.run {
                        fontLoadingState = .error(error)
                    }
                }
            } else {
                fontLoadingState = .loaded
            }
        }
    }
    
    private func styledText(using font: Font) -> some View {
        let uiFont = UIFont.systemFont(ofSize: textItem.fontSize)
        switch textItem.style {
        case .plain:
            return AnyView(
                OutlinedText(
                    text: textItem.text,
                    font: uiFont,
                    textColor: UIColor(textItem.textColor),
                    strokeColor: nil,
                    strokeWidth: 0
                )
                .frame(height: textItem.fontSize * 1.3)
            )
        case .stroke:
            return AnyView(
                OutlinedText(
                    text: textItem.text,
                    font: uiFont,
                    textColor: UIColor(textItem.textColor),
                    strokeColor: UIColor(textItem.strokeColor),
                    strokeWidth: -3
                )
                .frame(height: textItem.fontSize * 1.3)
            )
        case .inlineStroke:
            return AnyView(
                OutlinedText(
                    text: textItem.text,
                    font: uiFont,
                    textColor: UIColor(textItem.textColor),
                    strokeColor: UIColor(textItem.strokeColor),
                    strokeWidth: 3
                )
                .frame(height: textItem.fontSize * 1.3)
            )
        case .shadow:
            return AnyView(
                OutlinedText(
                    text: textItem.text,
                    font: uiFont,
                    textColor: UIColor(textItem.textColor),
                    strokeColor: nil,
                    strokeWidth: 0,
                    shadow: true,
                    shadowColor: UIColor(textItem.strokeColor),
                    shadowOffset: CGSize(width: 2, height: 2),
                    shadowRadius: 3
                )
                .frame(height: textItem.fontSize * 1.3)
            )
        case .blur:
            return AnyView(
                OutlinedText(
                    text: textItem.text,
                    font: uiFont,
                    textColor: UIColor(textItem.textColor),
                    strokeColor: nil,
                    strokeWidth: 0,
                    backgroundColor: UIColor.systemGray5.withAlphaComponent(0.7)
                )
                .frame(height: textItem.fontSize * 1.3)
            )
        case .highlight:
            return AnyView(
                OutlinedText(
                    text: textItem.text,
                    font: uiFont,
                    textColor: UIColor(textItem.textColor),
                    strokeColor: nil,
                    strokeWidth: 0,
                    highlight: true,
                    highlightColor: UIColor(textItem.highlightColor ?? .yellow),
                    highlightHeight: 1.2,
                    highlightOpacity: 0.4,
                    highlightInset: textItem.highlightInset
                )
                .frame(height: textItem.fontSize * 1.3)
            )
        }
    }
}

struct OutlinedText: UIViewRepresentable {
    var text: String
    var font: UIFont
    var textColor: UIColor
    var strokeColor: UIColor?
    var strokeWidth: CGFloat // -: 아웃라인(바깥), +: 인라인(안쪽), 0: 없음
    var shadow: Bool = false
    var shadowColor: UIColor = .black
    var shadowOffset: CGSize = .zero
    var shadowRadius: CGFloat = 0
    var backgroundColor: UIColor? = nil
    var highlight: Bool = false
    var highlightColor: UIColor = .yellow
    var highlightHeight: CGFloat = 1.2
    var highlightOpacity: CGFloat = 0.4
    var highlightInset: CGFloat = 0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        let attr = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)
        attr.addAttribute(.font, value: font, range: range)
        attr.addAttribute(.foregroundColor, value: textColor, range: range)
        if let strokeColor = strokeColor, strokeWidth != 0 {
            attr.addAttribute(.strokeColor, value: strokeColor, range: range)
            attr.addAttribute(.strokeWidth, value: strokeWidth, range: range)
        }
        uiView.attributedText = attr
        if shadow {
            uiView.layer.shadowColor = shadowColor.cgColor
            uiView.layer.shadowOffset = shadowOffset
            uiView.layer.shadowRadius = shadowRadius
            uiView.layer.shadowOpacity = 0.7
        } else {
            uiView.layer.shadowOpacity = 0
        }
        if let bg = backgroundColor {
            uiView.backgroundColor = bg
        } else {
            uiView.backgroundColor = .clear
        }
        // 형광펜/싸인펜 효과는 UILabel로는 한계가 있으나, 배경색+투명도로 근접 구현
        if highlight {
            let width = uiView.intrinsicContentSize.width + (font.pointSize * highlightInset * 2)
            let height = uiView.intrinsicContentSize.height * highlightHeight
            let highlightView = UIView(frame: CGRect(x: -font.pointSize * highlightInset, y: 0, width: width, height: height))
            highlightView.backgroundColor = highlightColor.withAlphaComponent(highlightOpacity)
            highlightView.layer.cornerRadius = 4
            highlightView.isUserInteractionEnabled = false
            // 기존 하이라이트 뷰 제거
            uiView.subviews.forEach { if $0.tag == 9999 { $0.removeFromSuperview() } }
            highlightView.tag = 9999
            uiView.insertSubview(highlightView, at: 0)
            uiView.backgroundColor = .clear
        } else {
            // 하이라이트가 아닐 때 기존 하이라이트 뷰 제거
            uiView.subviews.forEach { if $0.tag == 9999 { $0.removeFromSuperview() } }
        }
    }
}

// 텍스트 스티커 속성 구조체
struct TextStickerData {
    var text: String
    var fontSize: CGFloat
    var textColor: Color
    var style: TextStickerView.TextStyle
    var strokeColor: Color
    var fontInfo: FontInfo?
    var highlightColor: Color
}

struct TextStickerEditorView: View {
    @Binding var isPresented: Bool
    var initialText: String = ""
    var initialFontSize: CGFloat = 24
    var initialColor: Color = .white
    var initialStyle: TextStickerView.TextStyle = .stroke
    var initialStrokeColor: Color = .black
    var initialFontInfo: FontInfo? = nil
    var isEdit: Bool = false
    let onComplete: (TextStickerData) -> Void

    @State private var text: String
    @State private var fontSize: CGFloat
    @State private var textColor: Color
    @State private var style: TextStickerView.TextStyle
    @State private var strokeColor: Color
    @State private var selectedFont: FontInfo?
    @State private var showingFontPicker = false
    @State private var highlightColor: Color = .yellow

    init(
        isPresented: Binding<Bool>,
        initialText: String = "",
        initialFontSize: CGFloat = 24,
        initialColor: Color = .white,
        initialStyle: TextStickerView.TextStyle = .stroke,
        initialStrokeColor: Color = .black,
        initialFontInfo: FontInfo? = nil,
        isEdit: Bool = false,
        onComplete: @escaping (TextStickerData) -> Void
    ) {
        self._isPresented = isPresented
        self.initialText = initialText
        self.initialFontSize = initialFontSize
        self.initialColor = initialColor
        self.initialStyle = initialStyle
        self.initialStrokeColor = initialStrokeColor
        self.initialFontInfo = initialFontInfo
        self.isEdit = isEdit
        self.onComplete = onComplete
        _text = State(initialValue: initialText)
        _fontSize = State(initialValue: initialFontSize)
        _textColor = State(initialValue: initialColor)
        _style = State(initialValue: initialStyle)
        _strokeColor = State(initialValue: initialStrokeColor)
        _selectedFont = State(initialValue: initialFontInfo)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("텍스트")) {
                    TextField("텍스트를 입력하세요", text: $text)
                }
                
                Section(header: Text("폰트")) {
                    Button(action: { showingFontPicker = true }) {
                        HStack {
                            Text(selectedFont?.displayName ?? "시스템 폰트")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("글자 크기")) {
                    Slider(value: $fontSize, in: 12...200, step: 1) {
                        Text("크기: \(Int(fontSize))")
                    }
                }
                
                Section(header: Text("색상")) {
                    ColorPicker("텍스트 색상", selection: $textColor)
                    if style != .plain && style != .blur {
                        ColorPicker("테두리/그림자 색상", selection: $strokeColor)
                    }
                    if style == .highlight {
                        ColorPicker("형광펜 색상", selection: $highlightColor)
                    }
                }
                
                Section(header: Text("스타일")) {
                    Picker("스타일", selection: $style) {
                        Text("기본").tag(TextStickerView.TextStyle.plain)
                        Text("테두리").tag(TextStickerView.TextStyle.stroke)
                        Text("인라인").tag(TextStickerView.TextStyle.inlineStroke)
                        Text("그림자").tag(TextStickerView.TextStyle.shadow)
                        Text("블러").tag(TextStickerView.TextStyle.blur)
                        Text("형광펜").tag(TextStickerView.TextStyle.highlight)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    HStack {
                        Spacer()
                        TextStickerView(
                            textItem: TextItem(
                                text: text,
                                fontSize: fontSize,
                                textColor: textColor,
                                style: style,
                                strokeColor: strokeColor,
                                fontInfo: selectedFont,
                                highlightColor: highlightColor
                            )
                        )
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("텍스트 스티커")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEdit ? "수정" : "추가") {
                        let data = TextStickerData(
                            text: text,
                            fontSize: fontSize,
                            textColor: textColor,
                            style: style,
                            strokeColor: strokeColor,
                            fontInfo: selectedFont,
                            highlightColor: highlightColor
                        )
                        onComplete(data)
                        isPresented = false
                    }
                    .disabled(text.isEmpty)
                }
            }
            .sheet(isPresented: $showingFontPicker) {
                FontPickerView(selectedFont: $selectedFont)
            }
        }
    }
}

#Preview {
    TextStickerView(
        textItem: TextItem(
            text: "샘플 텍스트",
            fontSize: 24,
            textColor: .white,
            style: .stroke,
            strokeColor: .black,
            fontInfo: nil,
            highlightColor: .yellow
        )
    )
} 