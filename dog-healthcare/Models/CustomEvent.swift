import SwiftData
import Foundation

@Model
final class CustomEvent: AppEvent {
    var title: String = ""
    var date: Date = Date.now
    var category: String = ""
    var notes: String?
    var notificationID: String = UUID().uuidString
    var dog: Dog?

    init(title: String, date: Date, category: String, notes: String? = nil) {
        self.title = title
        self.date = date
        self.category = category
        self.notes = notes
        self.notificationID = UUID().uuidString
    }

    var systemImage: String {
        switch category.lowercased() {
        case "toilettage", "toiletteur": return "scissors"
        case "kinésithérapie", "kiné", "ostéopathie": return "figure.walk"
        case "bain": return "drop.fill"
        case "dressage": return "star.fill"
        default: return "calendar.badge.plus"
        }
    }
}
