import SwiftUI
import WordPeekCore

/// 「中文词 → 英文」浮窗视图。
///
/// 视觉对齐工作区设计 Token：深色面板 #1a1f2e/95、圆角 12、白色 15% 描边，
/// 品牌珊瑚色 #FF6B35 用于强调英文。
struct OverlayView: View {
    let result: LookupResult

    private let brandColor = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let panelColor = Color(red: 0.102, green: 0.122, blue: 0.180)

    var body: some View {
        HStack(spacing: 10) {
            Text(result.word)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.92))

            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.35))

            Text(result.english)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(brandColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 380, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(panelColor.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .fixedSize()
    }
}
