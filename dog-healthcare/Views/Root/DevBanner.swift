import SwiftUI

#if DEVELOPMENT
struct DevBanner: View {
    var body: some View {
        Text("ENV. DÉVELOPPEMENT")
            .font(.caption2.weight(.bold))
            .kerning(1)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(.yellow)
    }
}
#endif
