import SwiftUI

struct GlassCard<Content: View>: View {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 20
    var solidBackground: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background {
                if let solid = solidBackground {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(solid)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.08))
                        }
                }
            }
    }
}
