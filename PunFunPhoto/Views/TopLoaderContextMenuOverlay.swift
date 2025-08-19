import SwiftUI

struct TopLoaderContextMenuOverlay: View {
    let onDismiss: () -> Void
    let targetFrame: CGRect
    let canvasFrame: CGRect
    let onTextAdd: () -> Void
    let onSFSymbolsAdd: () -> Void
    let onManage: () -> Void
    let onSave: () -> Void
    let onToggleVisibility: () -> Void
    let onRemove: () -> Void
    let isVisible: Bool
    
    // 포토카드 메뉴와 동일한 스타일 적용
    private var menuWidth: CGFloat { 340 }
    private var baseFontSize: CGFloat { 16 }
    private var basePadding: CGFloat { 12 * (menuWidth / 200) }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 터치 제거 - PhotoEditorView에서 처리

                // 메뉴 본체: 중앙 정렬
                VStack(spacing: 0) {
                    menuItem(title: "텍스트 추가", systemImage: "textformat", action: {
                        onTextAdd()
                    })
                    Divider().padding(.horizontal, 12)
                    menuItem(title: "SF Symbols 추가", systemImage: "square.grid.3x3", action: {
                        onSFSymbolsAdd()
                    })
                    Divider().padding(.horizontal, 12)
                    menuItem(title: "탑로더 관리", systemImage: "music.note", action: {
                        onManage()
                    })
                    Divider().padding(.horizontal, 12)
                    menuItem(title: "탑로더 저장", systemImage: "square.and.arrow.down", action: {
                        onSave()
                    })
                    Divider().padding(.horizontal, 12)
                    menuItem(
                        title: isVisible ? "탑로더 가리기" : "탑로더 보기",
                        systemImage: isVisible ? "eye.slash" : "eye",
                        action: {
                            onToggleVisibility()
                        }
                    )
                    Divider().padding(.horizontal, 12)
                    menuItem(
                        title: "탑로더 제거",
                        systemImage: "xmark.circle.fill",
                        action: {
                            onRemove()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .zIndex(1)
                .allowsHitTesting(true)
            }
            .onAppear {
                print("TopLoaderContextMenuOverlay 렌더링")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            onDismiss()
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

#Preview {
    TopLoaderContextMenuOverlay(
        onDismiss: {},
        targetFrame: CGRect(x: 100, y: 100, width: 200, height: 300),
        canvasFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
        onTextAdd: {},
        onManage: {},
        onSave: {},
        onToggleVisibility: {},
        onRemove: {},
        isVisible: true
    )
}
