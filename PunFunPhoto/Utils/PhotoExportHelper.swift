import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PhotoExportHelper {
    
    // MARK: - 사진 앱에 저장 (선택사항)
    static func saveToPhotos(_ image: UIImage?) {
#if os(iOS)
        guard let image = image else {
            print("❗ 이미지가 nil이어서 저장할 수 없습니다.")
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("✅ 사진 앱에 저장 완료")
#endif
    }

    // MARK: - 출력
    static func printImage(_ image: UIImage) {
#if os(iOS)
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = "포토카드 인쇄"
        
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = image
        controller.present(animated: true, completionHandler: nil)
        
#elseif os(macOS)
        guard let cgImage = image.cgImage else { return }
        let size = NSSize(width: image.size.width, height: image.size.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        let imageView = NSImageView(image: nsImage)
        let printOperation = NSPrintOperation(view: imageView)
        printOperation.run()
#endif
    }
    
    // MARK: - 공유 (이미지 직접 공유, iOS만)
    static func shareImage(_ image: UIImage, from viewController: UIViewController) {
#if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = viewController.view // iPad 대응
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: viewController.view.bounds.midX,
            y: viewController.view.bounds.midY,
            width: 0, height: 0
        )
        activityVC.popoverPresentationController?.permittedArrowDirections = []
        viewController.present(activityVC, animated: true, completion: nil)
        print("✅ 이미지 공유 시트 표시 완료")
#endif
    }
}
