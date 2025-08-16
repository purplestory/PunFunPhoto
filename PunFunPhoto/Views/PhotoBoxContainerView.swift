import SwiftUI
import UIKit

struct PhotoBoxContainerView: View {
    @Binding var showSafeFrame: Bool
    let scaleFactor: CGFloat
    let canvasSize: CGSize
    let boxSize: CGSize
    let ppi: CGFloat
    let debugMode: Bool
    let canvasFrame: CGRect
    let boxFrames: [Int: CGRect]
    let rootOrigin: CGPoint
    let photo1: PhotoState
    let photo2: PhotoState
    @ObservedObject var topLoader1: TopLoaderState
    @ObservedObject var topLoader2: TopLoaderState
    let contextMenuTargetFrame: CGRect
    @Binding var contextMenuTargetBoxIndex: Int?

    let onTapPhoto1: () -> Void
    let onTapPhoto2: () -> Void
    let onSwapPhoto1: () -> Void
    let onSwapPhoto2: () -> Void
    let onDuplicatePhoto1: () -> Void
    let onDuplicatePhoto2: () -> Void
    let onContextMenuRequested: (Int, CGRect) -> Void
    let onStickerTapped: ((UUID, CGPoint) -> Void)?
    let onTextTapped: ((UUID, CGPoint) -> Void)?
    let onTopLoader1Tapped: (() -> Void)?
    let onTopLoader2Tapped: (() -> Void)?
    
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    @Binding var selectedMenu: MenuType?
    @Binding var showContextMenu: Bool
    @Binding var showTopLoader1ContextMenu: Bool?
    @Binding var showTopLoader2ContextMenu: Bool?
    
    private var spacing: CGFloat {
        let baseSpacing = CanvasConstants.boxSpacing
        return baseSpacing * scaleFactor
    }
    private var totalWidth: CGFloat { boxSize.width * 2 + spacing }

    var box1: some View {
        EditablePhotoBox(
            scaleFactor: scaleFactor,
            photo: photo1,
            boxSize: boxSize,
            canvasSize: canvasSize,
            boxOrigin: .zero,
            isPrimary: true,
            boxIndex: 1,
            onTap: {
                print("[DEBUG] 🔥 PhotoBoxContainerView - 포토박스1 onTap 호출됨")
                // PhotoEditorView의 onTapPhoto1에서 다른 메뉴들을 닫는 로직이 있으므로 여기서는 제거
                onTapPhoto1()
            },
            onSwap: onSwapPhoto1,
            onDuplicate: onDuplicatePhoto1,
            onContextMenuRequested: { frame in
                selectedMenu = nil
                showTopLoader1ContextMenu = nil
                showTopLoader2ContextMenu = nil
                onContextMenuRequested(1, frame)
            },
            spacing: spacing,
            isTopLoaderAttached: topLoader1.isAttached,
            showSafeFrame: $showSafeFrame,
            selectedMenu: $selectedMenu
        )
    }
    var box2: some View {
        EditablePhotoBox(
            scaleFactor: scaleFactor,
            photo: photo2,
            boxSize: boxSize,
            canvasSize: canvasSize,
            boxOrigin: .zero,
            isPrimary: false,
            boxIndex: 2,
            onTap: {
                print("[DEBUG] 🔥 PhotoBoxContainerView - 포토박스2 onTap 호출됨")
                // PhotoEditorView의 onTapPhoto2에서 다른 메뉴들을 닫는 로직이 있으므로 여기서는 제거
                onTapPhoto2()
            },
            onSwap: onSwapPhoto2,
            onDuplicate: onDuplicatePhoto2,
            onContextMenuRequested: { frame in
                selectedMenu = nil
                showTopLoader1ContextMenu = nil
                showTopLoader2ContextMenu = nil
                onContextMenuRequested(2, frame)
            },
            spacing: spacing,
            isTopLoaderAttached: topLoader2.isAttached,
            showSafeFrame: $showSafeFrame,
            selectedMenu: $selectedMenu
        )
    }

    var body: some View {
        ZStack {
            // 디버그용 임시 배경/텍스트 삭제
//            Color.white

            HStack(spacing: spacing) {
                ZStack {
                    box1
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ViewPreferenceKeys.PhotoBoxFrameKey.self, value: [1: geo.frame(in: .named("RootSpace"))])
                            }
                        )
                    if topLoader1.isAttached && topLoader1.showTopLoader {
                        TopLoaderView(
                            state: topLoader1,
                            boxSize: boxSize,
                            boxOrigin: .zero,
                            scaleFactor: scaleFactor,
                            showToast: $showToast,
                            toastMessage: $toastMessage,
                            selectedMenu: $selectedMenu,
                            showTopLoaderContextMenu: $showTopLoader1ContextMenu,
                            onStickerTapped: onStickerTapped,
                            onTextTapped: onTextTapped,
                            onTopLoaderTapped: {
                                onTopLoader1Tapped?()
                            }
                        )
                        .onAppear {
                            print("[DEBUG] TopLoaderView 조건: isAttached=\(topLoader1.isAttached), showTopLoader=\(topLoader1.showTopLoader)")
                        }
                    }
                }
                .frame(width: boxSize.width, height: boxSize.height)
                ZStack {
                    box2
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ViewPreferenceKeys.PhotoBoxFrameKey.self, value: [2: geo.frame(in: .named("RootSpace"))])
                            }
                        )
                    if topLoader2.isAttached && topLoader2.showTopLoader {
                        TopLoaderView(
                            state: topLoader2,
                            boxSize: boxSize,
                            boxOrigin: .zero,
                            scaleFactor: scaleFactor,
                            showToast: $showToast,
                            toastMessage: $toastMessage,
                            selectedMenu: $selectedMenu,
                            showTopLoaderContextMenu: $showTopLoader2ContextMenu,
                            onStickerTapped: onStickerTapped,
                            onTextTapped: onTextTapped,
                            onTopLoaderTapped: {
                                onTopLoader2Tapped?()
                            }
                        )
                        .onAppear {
                            print("[DEBUG] TopLoaderView 조건: isAttached=\(topLoader2.isAttached), showTopLoader=\(topLoader2.showTopLoader)")
                        }
                    }
                }
                .frame(width: boxSize.width, height: boxSize.height)
            }
            .frame(width: totalWidth, height: boxSize.height, alignment: .center)
            .simultaneousGesture(
                TapGesture().onEnded {
                    // 모든 메뉴 닫기
                    selectedMenu = nil
                    showContextMenu = false
                    showTopLoader1ContextMenu = nil
                    showTopLoader2ContextMenu = nil
                }
            )
//            .overlay(
//                GeometryReader { geo in
//                    // 디버그용 오버레이 제거
//                }
//            )
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .background(Color.white)
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewPreferenceKeys.CanvasFrameKey.self, value: geo.frame(in: .named("CanvasSpace")))
            }
        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 0)
//                // 디버그용 테두리 제거
//        )
        .coordinateSpace(name: "CanvasSpace")
        .onPreferenceChange(ViewPreferenceKeys.PhotoBoxFrameKey.self) { frames in
            // boxFrames를 상태로 업데이트 (만약 @State가 아니라면, 상위로 전달)
            // self.boxFrames = frames
            // 만약 상위에서 관리한다면, onBoxFramesChanged 같은 콜백으로 전달
        }

    }
}
