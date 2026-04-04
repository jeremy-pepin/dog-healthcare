import SwiftUI
import SwiftData

@Observable
final class EventsViewModel {
    var selectedDate: Date = .now
    var selectedMonth: Date = .now

    func allEvents(for dog: Dog) -> [any AppEvent] {
        let events: [any AppEvent] = (dog.vetEvents ?? []) + (dog.customEvents ?? [])
        return events.sorted { $0.date < $1.date }
    }

    func events(on date: Date, for dog: Dog) -> [any AppEvent] {
        allEvents(for: dog).filter { $0.date.isInSameDay(as: date) }
    }

    func futureEvents(for dog: Dog) -> [any AppEvent] {
        allEvents(for: dog).filter { $0.date >= Calendar.current.startOfDay(for: .now) }
    }

    func datesWithEvents(in month: Date, for dog: Dog) -> Set<Date> {
        let days = month.daysInMonth()
        let events = allEvents(for: dog)
        var result = Set<Date>()
        for day in days {
            if events.contains(where: { $0.date.isInSameDay(as: day) }) {
                result.insert(day)
            }
        }
        return result
    }

    func addVetEvent(title: String, date: Date, veterinarian: Veterinarian?, notes: String?, dog: Dog, context: ModelContext) {
        let event = VetEvent(title: title, date: date, veterinarian: veterinarian, notes: notes)
        event.dog = dog
        dog.vetEvents = (dog.vetEvents ?? []) + [event]
        context.insert(event)
        NotificationManager.shared.scheduleVetEventNotification(event)
    }

    func updateVetEvent(_ event: VetEvent, title: String, date: Date, veterinarian: Veterinarian?, notes: String?, context: ModelContext) {
        NotificationManager.shared.cancel(id: event.notificationID)
        event.title = title
        event.date = date
        event.veterinarian = veterinarian
        event.notes = notes.flatMap { $0.isEmpty ? nil : $0 }
        try? context.save()
        NotificationManager.shared.scheduleVetEventNotification(event)
    }

    func addCustomEvent(title: String, date: Date, category: String, notes: String?, dog: Dog, context: ModelContext) {
        let event = CustomEvent(title: title, date: date, category: category, notes: notes)
        event.dog = dog
        dog.customEvents = (dog.customEvents ?? []) + [event]
        context.insert(event)
        NotificationManager.shared.scheduleCustomEventNotification(event)
    }

    func updateCustomEvent(_ event: CustomEvent, title: String, date: Date, category: String, notes: String?, context: ModelContext) {
        NotificationManager.shared.cancel(id: event.notificationID)
        event.title = title
        event.date = date
        event.category = category
        event.notes = notes.flatMap { $0.isEmpty ? nil : $0 }
        try? context.save()
        NotificationManager.shared.scheduleCustomEventNotification(event)
    }

    func deleteVetEvent(_ event: VetEvent, dog: Dog, context: ModelContext) {
        NotificationManager.shared.cancel(id: event.notificationID)
        dog.vetEvents?.removeAll { $0.id == event.id }
        context.delete(event)
    }

    func deleteCustomEvent(_ event: CustomEvent, dog: Dog, context: ModelContext) {
        NotificationManager.shared.cancel(id: event.notificationID)
        dog.customEvents?.removeAll { $0.id == event.id }
        context.delete(event)
    }

    func previousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }

    func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}
