import SwiftData
import Foundation

@Model
final class WeightEntry {
    var date: Date = Date.now
    var value: Double = 0
    var note: String?
    var dog: Dog?

    init(date: Date, value: Double, note: String? = nil) {
        self.date = date
        self.value = value
        self.note = note
    }
}
