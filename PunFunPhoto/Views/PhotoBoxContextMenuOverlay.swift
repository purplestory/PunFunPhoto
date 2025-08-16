import SwiftUI

struct PhotoBoxContextMenuOverlay: View {
    @Binding var showSafeFrame: Bool
    var targetFrame: CGRect
    let canvasFrame: CGRect
    var scaleFactor: CGFloat
    var screenScale: CGFloat

    var onPick: () -> Void
    var onReset: () -> Void
    var onDuplicate: () -> Void
    var onSwap: () -> Void
    var onDelete: () -> Void
    var onMenuHeightChanged: (CGFloat) -> Void = { _ in }
    var onMenuWidthChanged: (CGFloat) -> Void = { _ in }
    var onAttachTopLoader: (() -> Void)? = nil
    var onShowTopLoader: (() -> Void)? = nil
    var selectedPhoto: PhotoState? = nil
    var onShowTopLoaderMenu: ((PhotoState) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
//    @State private var selectedPhotoForTopLoader: PhotoState?
//    @State private var showTopLoaderLibrary = false
//
//    private func showTopLoaderMenu(for photo: PhotoState) {
//        selectedPhotoForTopLoader = photo
//        showTopLoaderLibrary = true
//    }
    
    @State private var menuHeight: CGFloat = 0
    
    // 메뉴 너비는 고정값(예: 340)으로 설정
    private var menuWidth: CGFloat { 340 }

    private var baseFontSize: CGFloat {
        // 툴바와 동일한 16pt 폰트 크기 사용
        16
    }
    
    private var basePadding: CGFloat {
        // 툴바의 패딩(12pt)을 기준으로 menuWidth에 비례
        12 * (menuWidth / 200)
    }
    
    var isTopLoaderAttached: Bool
    var showTopLoader: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 터치 제거 - PhotoEditorView에서 처리

                // 메뉴 본체: 중앙 정렬
                VStack(spacing: 0) {
                    menuItem(title: "다른 사진 선택", systemImage: "photo", action: {
                        onPick()
                    })
                    Divider().padding(.horizontal, 12)
                    menuItem(
                        title: showSafeFrame ? "커팅선 가리기" : "커팅선 보기",
                        systemImage: "rectangle.dashed",
                        action: {
                            showSafeFrame.toggle()
                        }
                    )
                    Divider().padding(.horizontal, 12)
                    if !isTopLoaderAttached {
                        menuItem(title: "탑로더 관리", systemImage: "rectangle.stack.badge.plus", action: {
                            if let selectedPhoto = selectedPhoto {
                                onShowTopLoaderMenu?(selectedPhoto)
                            }
                        })
                        Divider().padding(.horizontal, 12)
                    } else if isTopLoaderAttached && !showTopLoader {
                        menuItem(title: "탑로더 보기", systemImage: "eye", action: {
                            onShowTopLoader?()
                        })
                        Divider().padding(.horizontal, 12)
                    } else if isTopLoaderAttached && showTopLoader {
                        menuItem(title: "탑로더 가리기", systemImage: "eye.slash", action: {
                            onShowTopLoader?()
                        })
                        Divider().padding(.horizontal, 12)
                    }
                    menuItem(title: "편집 초기화", systemImage: "arrow.counterclockwise", action: {
                        onReset()
                    })
                    menuItem(title: "사진 복제", systemImage: "plus.square.on.square", action: {
                        onDuplicate()
                    })
                    menuItem(title: "좌우 사진 바꾸기", systemImage: "arrow.left.arrow.right", action: {
                        onSwap()
                    })
                    Divider().padding(.horizontal, 12)
                    menuItem(
                        title: "사진 삭제",
                        systemImage: "trash",
                        action: {
                            onDelete()
                        },
                        textColor: .red
                    )
                }
                .frame(alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    Color(uiColor: .systemBackground)
                )
                .cornerRadius(8)
                .shadow(radius: 10)
                .fixedSize(horizontal: true, vertical: false)
                .background(GeometryReader { menuGeo in
                    Color.clear.onAppear {
                        menuHeight = menuGeo.size.height
                        onMenuHeightChanged(menuGeo.size.height)
                        onMenuWidthChanged(menuGeo.size.width)
                    }
//                    .onChange(of: menuGeo.size.height) { ... }
//                    .onChange(of: menuGeo.size.width) { ... }
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .zIndex(1)
                .allowsHitTesting(true)
                .onTapGesture {
                }
            }
            .onAppear {
                print("PhotoBoxContextMenuOverlay 렌더링")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        // 오버레이 전체 프레임은 상위에서 관리, 내부에서는 중앙 정렬만 신경
        .coordinateSpace(name: "CanvasSpace")
        .zIndex(9999)
    }

    @ViewBuilder
    private func menuItem(
        title: String,
        systemImage: String,
        action: @escaping () -> Void,
        textColor: Color = .primary
    ) -> some View {
        Button(action: {
            action()
            // 메뉴 아이템 액션만 실행, 메뉴 닫기는 것은 PhotoEditorView에서 처리
        }) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - ViewSizeKey
private struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
