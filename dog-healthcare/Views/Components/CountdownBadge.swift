import SwiftUI

struct CountdownBadge: View {
    let daysRemaining: Int?
    @State private var pulsing = false

    private var label: String {
        guard let days = daysRemaining else { return "Non défini" }
        if days < 0 { return "En retard \(abs(days))j" }
        if days == 0 { return "Aujourd'hui" }
        return "\(days)j"
    }

    private var badgeColor: Color {
        .reminderColor(daysRemaining: daysRemaining)
    }

    private var isUrgent: Bool {
        guard let days = daysRemaining else { return false }
        return days <= 7
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
            .scaleEffect(pulsing ? 1.07 : 1.0)
            .onAppear {
                guard isUrgent else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}
