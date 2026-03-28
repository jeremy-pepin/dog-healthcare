import SwiftData
import Foundation

@Model
final class Veterinarian {
    var name: String
    var clinic: String?
    var phone: String?
    var address: String?
    var notes: String?

    @Relationship(deleteRule: .nullify, inverse: \VetEvent.veterinarian)
    var vetEvents: [VetEvent] = []

    init(name: String, clinic: String? = nil, phone: String? = nil,
         address: String? = nil, notes: String? = nil) {
        self.name = name
        self.clinic = clinic
        self.phone = phone
        self.address = address
        self.notes = notes
    }

    var displayName: String {
        if let clinic { return "\(name) — \(clinic)" }
        return name
    }
}
