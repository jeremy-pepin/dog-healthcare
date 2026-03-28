import SwiftUI
import SwiftData

struct ReminderRowView: View {
    let reminder: Reminder
    let onMarkDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: reminder.reminderType.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.headline)

                if let nextDue = reminder.nextDueDate {
                    Text("Prochain : \(nextDue.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Aucun traitement enregistré")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Tous les \(reminder.intervalDays) jours")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                CountdownBadge(daysRemaining: reminder.daysRemaining)

                Button("Fait") { onMarkDone() }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    .tint(accentColor)
            }
        }
        .padding(.vertical, 4)
    }

    private var accentColor: Color {
        .reminderColor(daysRemaining: reminder.daysRemaining)
    }
}
