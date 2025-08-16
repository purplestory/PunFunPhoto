import SwiftUI

struct StickerItem: Identifiable, Codable, Equatable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var rotation: Angle
    var imageData: Data
    
    var image: UIImage? {
        UIImage(data: imageData)
    }
    
    init(id: UUID = UUID(), position: CGPoint, size: CGFloat, rotation: Angle, image: UIImage) {
        self.id = id
        self.position = position
        self.size = size
        self.rotation = rotation
        self.imageData = image.pngData() ?? Data()
    }
    
    static func == (lhs: StickerItem, rhs: StickerItem) -> Bool {
        lhs.id == rhs.id
    }
} 