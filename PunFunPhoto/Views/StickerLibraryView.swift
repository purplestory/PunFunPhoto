import SwiftUI

struct StickerLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (UIImage) -> Void
    
    // 스티커 카테고리
    enum Category: String, CaseIterable {
        case symbols = "심볼"
        case emoji = "이모지"
        case custom = "커스텀"
        
        var systemImage: String {
            switch self {
            case .symbols: return "square.grid.2x2"
            case .emoji: return "face.smiling"
            case .custom: return "plus.circle"
            }
        }
    }
    
    @State private var selectedCategory: Category = .symbols
    
    // SF Symbols 샘플
    private let symbols = [
        "heart.fill",
        "star.fill",
        "sparkles",
        "crown.fill",
        "cloud.fill",
        "moon.fill",
        "sun.max.fill",
        "rainbow",
        "bolt.fill",
        "snowflake",
        "flame.fill",
        "leaf.fill",
        "flower",
        "music.note",
        "heart.text.square.fill"
    ]
    
    // 이모지 샘플
    private let emojis = [
        "⭐️", "🌟", "✨", "💫", "🌙",
        "🌈", "☁️", "🌸", "🌺", "🌼",
        "🎀", "🎵", "💝", "💖", "💕"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 카테고리 선택
                Picker("카테고리", selection: $selectedCategory) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 스티커 그리드
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 5), spacing: 12) {
                        switch selectedCategory {
                        case .symbols:
                            ForEach(symbols, id: \.self) { name in
                                Button {
                                    if let image = createSymbolImage(name) {
                                        onSelect(image)
                                        dismiss()
                                    }
                                } label: {
                                    Image(systemName: name)
                                        .font(.system(size: 30))
                                        .frame(width: 60, height: 60)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                            
                        case .emoji:
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    if let image = createEmojiImage(emoji) {
                                        onSelect(image)
                                        dismiss()
                                    }
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 60, height: 60)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                            
                        case .custom:
                            Button {
                                // TODO: 이미지 피커 표시
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("스티커 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
    
    // SF Symbol을 UIImage로 변환
    private func createSymbolImage(_ name: String) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        return UIImage(systemName: name, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal)
    }
    
    // 이모지를 UIImage로 변환
    private func createEmojiImage(_ emoji: String) -> UIImage? {
        let size: CGFloat = 60
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.7),
                .paragraphStyle: paragraphStyle
            ]
            
            emoji.draw(with: CGRect(x: 0, y: size * 0.15, width: size, height: size),
                      options: .usesLineFragmentOrigin,
                      attributes: attrs,
                      context: nil)
        }
    }
}

#Preview {
    StickerLibraryView { _ in }
} 