import SwiftUI

struct CountdownBadge: View {
    let daysRemaining: Int?

    private var label: String {
        guard let days = daysRemaining else { return "Non défini" }
        if days < 0 { return "En retard \(abs(days))j" }
        if days == 0 { return "Aujourd'hui" }
        return "\(days)j"
    }

    private var badgeColor: Color {
        .reminderColor(daysRemaining: daysRemaining)
    }

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(badgeColor.opacity(0.15))
                    .overlay {
                        Capsule()
                            .strokeBorder(badgeColor.opacity(0.3), lineWidth: 0.5)
                    }
            }
    }
}
