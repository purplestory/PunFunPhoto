import Foundation

struct SavedTopLoader: Identifiable, Codable {
    let id: UUID
    let name: String
    let stickers: [StickerItem]
    let texts: [TextItem]
    let createdAt: Date
    
    init(name: String, stickers: [StickerItem], texts: [TextItem]) {
        self.id = UUID()
        self.name = name
        self.stickers = stickers
        self.texts = texts
        self.createdAt = Date()
    }
} 