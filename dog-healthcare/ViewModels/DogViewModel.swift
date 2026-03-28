import SwiftUI
import SwiftData

@Observable
final class DogViewModel {

    func addWeightEntry(value: Double, date: Date, note: String?, dog: Dog, context: ModelContext) {
        let entry = WeightEntry(date: date, value: value, note: note)
        entry.dog = dog
        dog.weightEntries.append(entry)
        context.insert(entry)
    }

    func deleteWeightEntry(_ entry: WeightEntry, dog: Dog, context: ModelContext) {
        dog.weightEntries.removeAll { $0.id == entry.id }
        context.delete(entry)
    }

    func weightChartData(for dog: Dog) -> [(date: Date, weight: Double)] {
        dog.weightEntries
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, weight: $0.value) }
    }

    func updateDog(dog: Dog, name: String, breed: String, dob: Date, photoData: Data?, context: ModelContext) {
        dog.name = name
        dog.breed = breed
        dog.dateOfBirth = dob
        dog.photoData = photoData
        try? context.save()
    }
}
