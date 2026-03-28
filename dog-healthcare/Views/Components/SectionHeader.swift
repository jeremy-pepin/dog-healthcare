import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .font(.caption.weight(.medium))
            }
        }
        .padding(.horizontal, 4)
    }
}
