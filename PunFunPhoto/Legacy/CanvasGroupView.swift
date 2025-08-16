import SwiftUI

struct CanvasGroupView: View {
    @Binding var showSafeFrame: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    let scaleFactor: CGFloat
    let canvasSize: CGSize
    @ObservedObject var photo1: PhotoState
    @ObservedObject var photo2: PhotoState
    @ObservedObject var topLoader1: TopLoaderState
    @ObservedObject var topLoader2: TopLoaderState
    let boxSize: CGSize
    let spacing: CGFloat
    let ppi: CGFloat
    let debugMode: Bool
    let canvasFrame: CGRect
    let boxFrames: [Int: CGRect]
    let contextMenuTargetFrame: CGRect
    @Binding var contextMenuTargetBoxIndex: Int?
    
    let onTapPhoto1: () -> Void
    let onTapPhoto2: () -> Void
    let onSwapPhoto1: () -> Void
    let onSwapPhoto2: () -> Void
    let onDuplicatePhoto1: () -> Void
    let onDuplicatePhoto2: () -> Void
    let onContextMenuRequested: (Int, CGRect) -> Void
    @Binding var selectedMenu: MenuType?
    @Binding var showContextMenu: Bool
    
    var body: some View {
        PhotoBoxContainerView(
            showSafeFrame: $showSafeFrame,
            scaleFactor: scaleFactor, 
            canvasSize: canvasSize,
            boxSize: boxSize,
            ppi: ppi,
            debugMode: debugMode,
            canvasFrame: canvasFrame,
            boxFrames: boxFrames,
            rootOrigin: .zero,
            photo1: photo1,
            photo2: photo2,
            topLoader1: topLoader1,
            topLoader2: topLoader2,
            contextMenuTargetFrame: contextMenuTargetFrame,
            contextMenuTargetBoxIndex: $contextMenuTargetBoxIndex,
            onTapPhoto1: onTapPhoto1,
            onTapPhoto2: onTapPhoto2,
            onSwapPhoto1: onSwapPhoto1,
            onSwapPhoto2: onSwapPhoto2,
            onDuplicatePhoto1: onDuplicatePhoto1,
            onDuplicatePhoto2: onDuplicatePhoto2,
            onContextMenuRequested: onContextMenuRequested,
            showToast: $showToast,
            toastMessage: $toastMessage,
            selectedMenu: $selectedMenu,
            showContextMenu: $showContextMenu
        )
        
        EditablePhotoBox(
            scaleFactor: scaleFactor,
            photo: photo1,
            boxSize: boxSize,
            canvasSize: canvasSize,
            boxOrigin: .zero,
            isPrimary: true,
            boxIndex: 1,
            onTap: onTapPhoto1,
            onSwap: onSwapPhoto1,
            onDuplicate: onDuplicatePhoto1,
            onContextMenuRequested: { frame in onContextMenuRequested(1, frame) },
            spacing: spacing,
            isTopLoaderAttached: topLoader1.isAttached,
            showSafeFrame: $showSafeFrame,
            selectedMenu: $selectedMenu
        )
    }
}
