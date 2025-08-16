import UIKit

struct ExportManager {
    static let canvasSize = CGSize(width: 1890, height: 1260) // 4R 1:1 기준
    static let boxSize = CGSize(width: 685, height: 1063)     // 58x90mm @32.5pt/mm
    static let boxSpacing: CGFloat = 30                       // 약 3mm 간격
    static let cornerRadius: CGFloat = 30                     // 3mm 라운딩

    /// 📸 캡처 이미지 저장 (사진 앱)
    static func saveToPhotos(_ image: UIImage?) {
        guard let image = image else {
            print("❗ 저장 실패: 렌더링된 이미지가 없습니다.")
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("✅ 사진 앱에 저장 완료")
    }

    /// 🖨 두 포토박스 병합 렌더링
    static func renderCombinedImage(photo1: PhotoState, photo2: PhotoState) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: canvasSize))

            drawPhoto(photo1, in: ctx, atIndex: 0)
            drawPhoto(photo2, in: ctx, atIndex: 1)
        }
    }

    /// 🧩 포토박스별 렌더링 처리
    private static func drawPhoto(_ photo: PhotoState, in ctx: CGContext, atIndex index: Int) {
        guard let image = photo.originalImage else { return }

        // 각 포토박스 위치 계산
        let totalWidth = boxSize.width * 2 + boxSpacing
        let groupOriginX = (canvasSize.width - totalWidth) / 2
        let originX = groupOriginX + CGFloat(index) * (boxSize.width + boxSpacing)
        let originY = (canvasSize.height - boxSize.height) / 2
        let boxRect = CGRect(origin: CGPoint(x: originX, y: originY), size: boxSize)

        // 스케일 및 오프셋 적용
        let totalScale = photo.coverScale * photo.scale
        let scaledSize = CGSize(
            width: image.size.width * totalScale,
            height: image.size.height * totalScale
        )

        let drawOrigin = CGPoint(
            x: boxRect.midX - scaledSize.width / 2 + photo.offset.width,
            y: boxRect.midY - scaledSize.height / 2 + photo.offset.height
        )
        let drawRect = CGRect(origin: drawOrigin, size: scaledSize)

        // 마스킹 및 그리기
        ctx.saveGState()
        let path = UIBezierPath(roundedRect: boxRect, cornerRadius: cornerRadius).cgPath
        ctx.addPath(path)
        ctx.clip()
        image.draw(in: drawRect)
        ctx.restoreGState()

        // 디버깅 로그
        print("[DEBUG] drawPhoto(index: \(index))")
        print("  imageSize: \(image.size)")
        print("  coverScale: \(photo.coverScale), scale: \(photo.scale)")
        print("  offset: \(photo.offset)")
        print("  boxRect: \(boxRect)")
        print("  drawRect: \(drawRect)")
    }
}
