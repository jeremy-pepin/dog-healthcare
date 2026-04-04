import SwiftData
import Foundation

@Model
final class VetEvent: AppEvent {
    var title: String = ""
    var date: Date = Date.now
    // Conservés comme fallback de migration — ne plus écrire dans le nouveau code
    var vetName: String?
    var clinic: String?
    var notes: String?
    var notificationID: String = UUID().uuidString
    var dog: Dog?
    var veterinarian: Veterinarian?

    init(title: String, date: Date, veterinarian: Veterinarian? = nil, notes: String? = nil) {
        self.title = title
        self.date = date
        self.veterinarian = veterinarian
        self.notes = notes
        self.notificationID = UUID().uuidString
    }

    var category: String { "Vétérinaire" }
    var systemImage: String { "stethoscope" }
}
