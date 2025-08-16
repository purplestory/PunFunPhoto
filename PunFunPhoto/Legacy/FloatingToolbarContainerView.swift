import SwiftUI

struct FloatingToolbarContainerView: View {
    @Binding var showSafeFrame: Bool
    @ObservedObject var photo1: PhotoState
    @ObservedObject var photo2: PhotoState
    @ObservedObject var topLoader1: TopLoaderState
    @ObservedObject var topLoader2: TopLoaderState
    @Binding var showPhotoPicker: Bool
    @Binding var photoPickerMode: PhotoPickerMode
    @Binding var showAlreadySelectedAlert: Bool
    @Binding var selectedMenu: MenuType?
    @Binding var showContextMenu: Bool
    @Binding var showTopLoader1ContextMenu: Bool?
    @Binding var showTopLoader2ContextMenu: Bool?
    
    var body: some View {
        VStack {
            FloatingToolbarView(
                showSafeFrame: $showSafeFrame,
                photo1: photo1,
                photo2: photo2,
                topLoader1: topLoader1,
                topLoader2: topLoader2,
                showPhotoPicker: $showPhotoPicker,
                photoPickerMode: $photoPickerMode,
                showAlreadySelectedAlert: $showAlreadySelectedAlert,
                selectedMenu: $selectedMenu,
                showContextMenu: $showContextMenu,
                showTopLoader1ContextMenu: $showTopLoader1ContextMenu,
                showTopLoader2ContextMenu: $showTopLoader2ContextMenu
            )
            .padding(.top, 7)
            .padding(.horizontal, 0)
            .background(Color.clear)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .zIndex(1)
        // .contentShape(Rectangle())
    }
}

#Preview {
    FloatingToolbarContainerView(
        showSafeFrame: .constant(true),
        photo1: PhotoState(),
        photo2: PhotoState(),
        topLoader1: TopLoaderState(),
        topLoader2: TopLoaderState(),
        showPhotoPicker: .constant(false),
        photoPickerMode: .constant(.전체),
        showAlreadySelectedAlert: .constant(false),
        selectedMenu: .constant(nil),
        showContextMenu: .constant(false),
        showTopLoader1ContextMenu: .constant(nil),
        showTopLoader2ContextMenu: .constant(nil)
    )
}
