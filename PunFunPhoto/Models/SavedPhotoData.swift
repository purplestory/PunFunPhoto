import Foundation
import CoreGraphics

struct SavedPhotoData: Codable {
    let filePath: String
    let offset: CGSize
    let scale: CGFloat
    let coverScale: CGFloat
}
