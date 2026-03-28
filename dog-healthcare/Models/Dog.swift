import SwiftData
import Foundation

@Model
final class Dog {
    var name: String
    var breed: String
    var dateOfBirth: Date
    @Attribute(.externalStorage) var photoData: Data?

    @Relationship(deleteRule: .cascade, inverse: \WeightEntry.dog)
    var weightEntries: [WeightEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \VetEvent.dog)
    var vetEvents: [VetEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \CustomEvent.dog)
    var customEvents: [CustomEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.dog)
    var reminders: [Reminder] = []

    @Relationship(deleteRule: .cascade, inverse: \Document.dog)
    var documents: [Document] = []

    init(name: String, breed: String, dateOfBirth: Date, photoData: Data? = nil) {
        self.name = name
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.photoData = photoData
    }

    var age: String {
        dateOfBirth.ageString()
    }

    var latestWeight: Double? {
        weightEntries.sorted { $0.date > $1.date }.first?.value
    }

    var nextEvent: (any AppEvent)? {
        let now = Date.now
        let allEvents: [any AppEvent] = vetEvents + customEvents
        return allEvents
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .first
    }

    var upcomingEvents: [any AppEvent] {
        let now = Date.now
        let allEvents: [any AppEvent] = vetEvents + customEvents
        return allEvents
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
    }
}
