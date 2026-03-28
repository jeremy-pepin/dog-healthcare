import SwiftData
import Foundation

enum ReminderType: String, Codable, CaseIterable {
    case deworming = "Vermifuge"
    case antiParasite = "Antiparasitaire"
    case vaccine = "Vaccin"
    case custom = "Personnalisé"

    var systemImage: String {
        switch self {
        case .deworming: return "pills.fill"
        case .antiParasite: return "shield.fill"
        case .vaccine: return "syringe.fill"
        case .custom: return "bell.fill"
        }
    }

    var defaultIntervalDays: Int {
        switch self {
        case .deworming: return 90
        case .antiParasite: return 30
        case .vaccine: return 365
        case .custom: return 30
        }
    }
}

@Model
final class Reminder {
    var title: String
    var type: String
    var lastDoneDate: Date?
    var intervalDays: Int
    var notificationID: String
    var isActive: Bool
    var dog: Dog?

    init(title: String, type: ReminderType, intervalDays: Int, lastDoneDate: Date? = nil) {
        self.title = title
        self.type = type.rawValue
        self.intervalDays = intervalDays
        self.lastDoneDate = lastDoneDate
        self.notificationID = UUID().uuidString
        self.isActive = true
    }

    var reminderType: ReminderType {
        ReminderType(rawValue: type) ?? .custom
    }

    var nextDueDate: Date? {
        guard let last = lastDoneDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: last)
    }

    var daysRemaining: Int? {
        guard let due = nextDueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: due)).day
    }

    var isOverdue: Bool {
        guard let days = daysRemaining else { return false }
        return days < 0
    }
}
