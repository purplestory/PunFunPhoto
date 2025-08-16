import SwiftUI

struct TopLoaderContextMenuOverlay: View {
    let onDismiss: () -> Void
    let targetFrame: CGRect
    let canvasFrame: CGRect
    let onTextAdd: () -> Void
    let onManage: () -> Void
    let onSave: () -> Void
    let onToggleVisibility: () -> Void
    let onRemove: () -> Void
    let isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 텍스트 추가
            Button(action: {
                onTextAdd()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "textformat")
                        .imageScale(.medium)
                        .frame(width: 24)
                    Text("텍스트 추가")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.horizontal, 12)
            
            // 탑로더 관리
            Button(action: {
                onManage()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .imageScale(.medium)
                        .frame(width: 24)
                    Text("탑로더 관리")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.horizontal, 12)
            
            // 탑로더 저장
            Button(action: {
                onSave()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .imageScale(.medium)
                        .frame(width: 24)
                    Text("탑로더 저장")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.horizontal, 12)
            
            // 탑로더 보기/가리기
            Button(action: {
                onToggleVisibility()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .imageScale(.medium)
                        .frame(width: 24)
                    Text(isVisible ? "탑로더 가리기" : "탑로더 보기")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.horizontal, 12)
            
            // 탑로더 제거
            Button(action: {
                onRemove()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.medium)
                        .frame(width: 24)
                    Text("탑로더 제거")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .frame(width: 200)
        .background(
            Color.black.opacity(0.001)
                .onTapGesture {
                    onDismiss()
                }
        )
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
