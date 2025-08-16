import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

class PhotoEditState: ObservableObject {
    @Published var brightness: Double = 0.0     // -1.0 ~ 1.0
    @Published var contrast: Double = 1.0       // 0.0 ~ 4.0
    @Published var saturation: Double = 1.0     // 0.0 ~ 2.0
    @Published var opacity: Double = 1.0        // 0.0 ~ 1.0
    @Published var selectedFilter: FilterType = .none
    
    enum FilterType: String, CaseIterable {
        case none = "없음"
        case mono = "모노"
        case sepia = "세피아"
        case vibrant = "비비드"
        case noir = "느와르"
        case fade = "페이드"
        case instant = "인스턴트"
        case process = "프로세스"
        case tonal = "토널"
        case transfer = "트랜스퍼"
    }
    
    private let context = CIContext()
    
    func applyEdits(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        var currentCIImage = ciImage
        
        // 밝기 조정
        if brightness != 0 {
            let brightnessFilter = CIFilter.exposureAdjust()
            brightnessFilter.inputImage = currentCIImage
            brightnessFilter.ev = Float(brightness * 2) // 범위 조정
            if let outputImage = brightnessFilter.outputImage {
                currentCIImage = outputImage
            }
        }
        
        // 대비 조정
        if contrast != 1 {
            let contrastFilter = CIFilter.colorControls()
            contrastFilter.inputImage = currentCIImage
            contrastFilter.contrast = Float(contrast)
            if let outputImage = contrastFilter.outputImage {
                currentCIImage = outputImage
            }
        }
        
        // 채도 조정
        if saturation != 1 {
            let saturationFilter = CIFilter.colorControls()
            saturationFilter.inputImage = currentCIImage
            saturationFilter.saturation = Float(saturation)
            if let outputImage = saturationFilter.outputImage {
                currentCIImage = outputImage
            }
        }
        
        // 필터 적용
        if selectedFilter != .none {
            if let filteredImage = applyFilter(selectedFilter, to: currentCIImage) {
                currentCIImage = filteredImage
            }
        }
        
        // CIImage를 UIImage로 변환
        if let cgImage = context.createCGImage(currentCIImage, from: currentCIImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    private func applyFilter(_ filter: FilterType, to image: CIImage) -> CIImage? {
        switch filter {
        case .none:
            return image
        case .mono:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = image
            return filter.outputImage
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = image
            filter.intensity = 0.8
            return filter.outputImage
        case .vibrant:
            let filter = CIFilter.vibrance()
            filter.inputImage = image
            filter.amount = 1.0
            return filter.outputImage
        case .noir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = image
            return filter.outputImage
        case .fade:
            let filter = CIFilter.photoEffectFade()
            filter.inputImage = image
            return filter.outputImage
        case .instant:
            let filter = CIFilter.photoEffectInstant()
            filter.inputImage = image
            return filter.outputImage
        case .process:
            let filter = CIFilter.photoEffectProcess()
            filter.inputImage = image
            return filter.outputImage
        case .tonal:
            let filter = CIFilter.photoEffectTonal()
            filter.inputImage = image
            return filter.outputImage
        case .transfer:
            let filter = CIFilter.photoEffectTransfer()
            filter.inputImage = image
            return filter.outputImage
        }
    }
    
    func reset() {
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        opacity = 1.0
        selectedFilter = .none
    }
} 