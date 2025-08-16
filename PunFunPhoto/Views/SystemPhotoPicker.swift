import SwiftUI
import PhotosUI

struct SystemPhotoPicker: UIViewControllerRepresentable {
    var allowsMultipleSelection: Bool = false
    var maxSelection: Int = 1
    var onImagePicked: ([UIImage]) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = allowsMultipleSelection ? maxSelection : 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagePicked: ([UIImage]) -> Void
        
        init(onImagePicked: @escaping ([UIImage]) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else {
                onImagePicked([])
                return
            }
            var images: [UIImage] = []
            let group = DispatchGroup()
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let uiImage = image as? UIImage {
                            images.append(uiImage)
                        }
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                self.onImagePicked(images)
            }
        }
    }
}
