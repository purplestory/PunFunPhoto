import SwiftUI

struct PhotoEditView: View {
    @ObservedObject var editState: PhotoEditState
    let image: UIImage
    let onComplete: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // 이미지 프리뷰
                if let editedImage = editState.applyEdits(to: image) {
                    Image(uiImage: editedImage)
                        .resizable()
                        .scaledToFit()
                        .opacity(editState.opacity)
                        .padding()
                }
                
                // 편집 컨트롤
                Form {
                    Section(header: Text("기본 조정")) {
                        VStack {
                            HStack {
                                Text("밝기")
                                Spacer()
                                Text(String(format: "%.1f", editState.brightness))
                            }
                            Slider(value: $editState.brightness, in: -1...1, step: 0.1)
                        }
                        
                        VStack {
                            HStack {
                                Text("대비")
                                Spacer()
                                Text(String(format: "%.1f", editState.contrast))
                            }
                            Slider(value: $editState.contrast, in: 0...2, step: 0.1)
                        }
                        
                        VStack {
                            HStack {
                                Text("채도")
                                Spacer()
                                Text(String(format: "%.1f", editState.saturation))
                            }
                            Slider(value: $editState.saturation, in: 0...2, step: 0.1)
                        }
                        
                        VStack {
                            HStack {
                                Text("투명도")
                                Spacer()
                                Text(String(format: "%.1f", editState.opacity))
                            }
                            Slider(value: $editState.opacity, in: 0...1, step: 0.1)
                        }
                    }
                    
                    Section(header: Text("필터")) {
                        Picker("필터", selection: $editState.selectedFilter) {
                            ForEach(PhotoEditState.FilterType.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("사진 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        editState.reset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        if let editedImage = editState.applyEdits(to: image) {
                            onComplete(editedImage)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("초기화") {
                        editState.reset()
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoEditView(
        editState: PhotoEditState(),
        image: UIImage(systemName: "photo")!
    ) { _ in }
} 