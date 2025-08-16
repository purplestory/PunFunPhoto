import SwiftUI

struct EditablePhotoBox: View {
    var scaleFactor: CGFloat
    @ObservedObject var photo: PhotoState
    var boxSize: CGSize
    var canvasSize: CGSize
    var boxOrigin: CGPoint
    var isPrimary: Bool
    var boxIndex: Int
    var onTap: () -> Void
    var onSwap: () -> Void
    var onDuplicate: () -> Void
    var onContextMenuRequested: (CGRect) -> Void = { _ in }
    var spacing: CGFloat = 0
    var isTopLoaderAttached: Bool
    @Binding var showSafeFrame: Bool
    @Binding var selectedMenu: MenuType?

    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var magnifyLastValue: CGFloat = 1.0
    @State private var showScanAnimation = false
    @State private var canTap = true

    private let cornerRadius: CGFloat = 30
    private let mmToPt: CGFloat = 72.0 / 25.4
    private let cuttingMargin: CGFloat = 1.0 * (72.0 / 25.4)
    private var cuttingFrameSize: CGSize {
        CGSize(
            width: boxSize.width - cuttingMargin * 2,
            height: boxSize.height - cuttingMargin * 2
        )
    }

    private var safeFrameSize: CGSize {
        CGSize(width: boxSize.width * 0.9, height: boxSize.height * 0.9)
    }

    private var adjustedCorner: CGFloat {
        cornerRadius * (safeFrameSize.width / boxSize.width)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
//                Color.white

                // 디버그용 임시 배경/텍스트 삭제
                // 이미지 렌더링
                if let image = photo.originalImage {
                    let totalScale = photo.coverScale * photo.scale
                    let displaySize = CGSize(
                        width: image.size.width * totalScale,
                        height: image.size.height * totalScale
                    )

                    Image(uiImage: image)
                        .resizable()
                        .frame(width: displaySize.width, height: displaySize.height)
                        .offset(photo.offset)
                        .position(x: boxSize.width / 2, y: boxSize.height / 2)
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .size(width: boxSize.width, height: boxSize.height)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: cornerRadius)
                            .size(width: boxSize.width, height: boxSize.height))
                        .onTapGesture {
                            print("[EditablePhotoBox] 이미지 탭: boxIndex=\(boxIndex)")
                            onTap() // 먼저 onTap 호출
                            let globalFrame = geo.frame(in: .named("RootSpace"))
                            onContextMenuRequested(globalFrame)
                            selectedMenu = nil
                        }
                        .zIndex(0)
                        .transaction { $0.animation = nil }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.gray.opacity(0.1))
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .overlay(
                            VStack(spacing: 4) {
                                Text("탭 해서 사진 선택")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                Text("그리고 다시 사진을 탭 해보세요!")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .multilineTextAlignment(.center)
                            .scaleEffect(1 / scaleFactor)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: cornerRadius)
                            .size(width: boxSize.width, height: boxSize.height))
                        .onTapGesture {
                            print("[EditablePhotoBox] 빈 박스 탭: boxIndex=\(boxIndex)")
                            onTap()
                        }
                        .zIndex(0)
                }

                // 흐림 오버레이: 커팅선 바깥 흐리게 (1mm margin)
                if showSafeFrame {
                    Canvas { context, size in
                        // 전체 박스 영역
                        var path = Path(CGRect(origin: .zero, size: size))
                        // 커팅선 영역(투명하게 뚫을 부분)
                        let cutRect = CGRect(
                            x: (boxSize.width - cuttingFrameSize.width) / 2,
                            y: (boxSize.height - cuttingFrameSize.height) / 2,
                            width: cuttingFrameSize.width,
                            height: cuttingFrameSize.height
                        )
                        path.addPath(RoundedRectangle(cornerRadius: cornerRadius).path(in: cutRect))
                        context.fill(path, with: .color(Color.white.opacity(0.8)), style: .init(eoFill: true))
                    }
                    .frame(width: boxSize.width, height: boxSize.height)
//                    .blur(radius: 3)
                    .compositingGroup()
                    // .allowsHitTesting(false)

                    // 커팅선 테두리
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.red.opacity(0.6), lineWidth: 1)
                        .frame(width: cuttingFrameSize.width, height: cuttingFrameSize.height)
                        .position(x: boxSize.width / 2, y: boxSize.height / 2)
                        // .allowsHitTesting(false)
                }

                // 강조 애니메이션
                if showScanAnimation {
                    PhotoBoxScanHighlight(size: boxSize)
                        // .allowsHitTesting(false)
                }

                // 중심선 가이드라인 (수평)
                // Rectangle()
                //     .fill(Color.red.opacity(0.7))
                //     .frame(height: 2)
                //     .frame(maxWidth: .infinity)
                //     .position(x: boxSize.width / 2, y: boxSize.height / 2)
                //     .allowsHitTesting(false)

                // 중심선 가이드라인 (수직)
                // Rectangle()
                //     .fill(Color.blue.opacity(0.7))
                //     .frame(width: 2)
                //     .frame(maxHeight: .infinity)
                //     .position(x: boxSize.width / 2, y: boxSize.height / 2)
                //     .allowsHitTesting(false)

                // 디버그: 포토박스 내부 중심
                // Circle()
                //     .fill(Color.green)
                //     .frame(width: 14, height: 14)
                //     .position(x: boxSize.width / 2, y: boxSize.height / 2)
                //     .zIndex(10001)
            }
            .frame(width: boxSize.width, height: boxSize.height)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .gesture(
                TapGesture()
                    .onEnded {
                        print("[EditablePhotoBox] TapGesture onEnded: boxIndex=\(boxIndex), isTopLoaderAttached=\(isTopLoaderAttached), hasImage=\(photo.originalImage != nil)")
                        if isTopLoaderAttached {
                            let globalFrame = geo.frame(in: .named("RootSpace"))
                            onContextMenuRequested(globalFrame)
                        } else if photo.originalImage == nil {
                            onTap()
                        } else {
                            let globalFrame = geo.frame(in: .named("RootSpace"))
                            onContextMenuRequested(globalFrame)
                        }
                    }
            )
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    if isTopLoaderAttached { return }
                    photo.offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    if isTopLoaderAttached { return }
                    lastOffset = photo.offset
                    snapToEdges()
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    if isTopLoaderAttached { return }
                    let delta = value / magnifyLastValue
                    photo.scale *= delta
                    magnifyLastValue = value
                }
                .onEnded { _ in
                    if isTopLoaderAttached { return }
                    magnifyLastValue = 1.0
                    let minScale = calculateMinScale()
                    photo.scale = max(photo.scale, minScale)
                    lastScale = photo.scale
                    photo.clampScale(to: photo.scale, min: minScale, max: 4.0)
                    snapToEdges()
                }
        )
            .onAppear {
                print("[EditablePhotoBox] 렌더링: boxIndex=\(boxIndex)")
            }
        }
    }

    private func calculateMinScale() -> CGFloat {
        guard let image = photo.originalImage else { return 1.0 }
        let widthRatio = boxSize.width / image.size.width
        let heightRatio = boxSize.height / image.size.height
        let requiredCoverScale = max(widthRatio, heightRatio)
        return max(1.0, requiredCoverScale / photo.coverScale)
    }
    
    private func snapToEdges() {
        guard let image = photo.originalImage else { return }
        let totalScale = photo.coverScale * photo.scale
        let displaySize = CGSize(width: image.size.width * totalScale, height: image.size.height * totalScale)
        let origin = CGPoint(
            x: (boxSize.width - displaySize.width) / 2,
            y: (boxSize.height - displaySize.height) / 2
        )
        var offset = photo.offset
        let imageLeft = origin.x + offset.width
        let imageRight = origin.x + displaySize.width + offset.width
        let imageTop = origin.y + offset.height
        let imageBottom = origin.y + displaySize.height + offset.height
        
        if imageLeft > 0 { offset.width -= imageLeft }
        if imageRight < boxSize.width { offset.width += boxSize.width - imageRight }
        if imageTop > 0 { offset.height -= imageTop }
        if imageBottom < boxSize.height { offset.height += boxSize.height - imageBottom }
        
        withAnimation(.easeOut(duration: 0.2)) {
            photo.offset = offset
            lastOffset = offset
        }
    }
}
