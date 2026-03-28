import SwiftUI

extension Color {
    static let reminderUrgent = Color.red
    static let reminderWarning = Color.orange
    static let reminderSafe = Color.green
    static let reminderNeutral = Color.secondary

    static func reminderColor(daysRemaining: Int?) -> Color {
        guard let days = daysRemaining else { return .reminderNeutral }
        if days < 0 { return .reminderUrgent }
        if days <= 7 { return .reminderWarning }
        return .reminderSafe
    }
}
