import SwiftUI

class TextItem: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var text: String
    @Published var fontSize: CGFloat
    @Published var textColor: Color
    @Published var style: TextStickerView.TextStyle
    @Published var strokeColor: Color
    @Published var fontInfo: FontInfo?
    @Published var highlightColor: Color?
    @Published var position: CGPoint
    @Published var rotation: Angle
    @Published var scale: CGFloat
    @Published var highlightInset: CGFloat
    
    init(
        id: UUID = UUID(),
        text: String,
        fontSize: CGFloat,
        textColor: Color,
        style: TextStickerView.TextStyle,
        strokeColor: Color,
        fontInfo: FontInfo? = nil,
        highlightColor: Color? = nil,
        position: CGPoint = .zero,
        rotation: Angle = .zero,
        scale: CGFloat = 1.0,
        highlightInset: CGFloat = 0.5
    ) {
        self.id = id
        self.text = text
        self.fontSize = fontSize
        self.textColor = textColor
        self.style = style
        self.strokeColor = strokeColor
        self.fontInfo = fontInfo
        self.highlightColor = highlightColor
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.highlightInset = highlightInset
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, fontSize, textColor, style, strokeColor, fontInfo, highlightColor, position, rotation, scale, highlightInset
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let text = try container.decode(String.self, forKey: .text)
        let fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        let textColor = try container.decode(Color.self, forKey: .textColor)
        let style = try container.decode(TextStickerView.TextStyle.self, forKey: .style)
        let strokeColor = try container.decode(Color.self, forKey: .strokeColor)
        let fontInfo = try container.decodeIfPresent(FontInfo.self, forKey: .fontInfo)
        let highlightColor = try container.decodeIfPresent(Color.self, forKey: .highlightColor)
        let position = try container.decode(CGPoint.self, forKey: .position)
        let rotation = try container.decode(Angle.self, forKey: .rotation)
        let scale = try container.decode(CGFloat.self, forKey: .scale)
        let highlightInset = try container.decode(CGFloat.self, forKey: .highlightInset)
        self.init(id: id, text: text, fontSize: fontSize, textColor: textColor, style: style, strokeColor: strokeColor, fontInfo: fontInfo, highlightColor: highlightColor, position: position, rotation: rotation, scale: scale, highlightInset: highlightInset)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(textColor, forKey: .textColor)
        try container.encode(style, forKey: .style)
        try container.encode(strokeColor, forKey: .strokeColor)
        try container.encode(fontInfo, forKey: .fontInfo)
        try container.encode(highlightColor, forKey: .highlightColor)
        try container.encode(position, forKey: .position)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(scale, forKey: .scale)
        try container.encode(highlightInset, forKey: .highlightInset)
    }
}

// Color를 Codable로 만들기 위한 확장
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(opacity, forKey: .opacity)
    }
}

// Angle을 Codable로 만들기 위한 확장
extension Angle: Codable {
    enum CodingKeys: String, CodingKey {
        case degrees
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let degrees = try container.decode(Double.self, forKey: .degrees)
        self.init(degrees: degrees)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(degrees, forKey: .degrees)
    }
} 
