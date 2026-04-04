import SwiftUI
import SwiftData

@Observable
final class RemindersViewModel {

    func sortedReminders(for dog: Dog) -> [Reminder] {
        (dog.reminders ?? []).sorted { a, b in
            let aOverdue = a.isOverdue
            let bOverdue = b.isOverdue
            if aOverdue != bOverdue { return aOverdue }
            let aDays = a.daysRemaining ?? Int.max
            let bDays = b.daysRemaining ?? Int.max
            return aDays < bDays
        }
    }

    func markAsDone(_ reminder: Reminder, context: ModelContext) {
        reminder.lastDoneDate = .now
        try? context.save()
        NotificationManager.shared.scheduleReminderNotification(reminder)
    }

    func addReminder(title: String, type: ReminderType, intervalDays: Int, lastDoneDate: Date?, dog: Dog, context: ModelContext) {
        let reminder = Reminder(title: title, type: type, intervalDays: intervalDays, lastDoneDate: lastDoneDate)
        reminder.dog = dog
        dog.reminders = (dog.reminders ?? []) + [reminder]
        context.insert(reminder)
        NotificationManager.shared.scheduleReminderNotification(reminder)
    }

    func deleteReminder(_ reminder: Reminder, dog: Dog, context: ModelContext) {
        NotificationManager.shared.cancel(id: reminder.notificationID)
        dog.reminders?.removeAll { $0.id == reminder.id }
        context.delete(reminder)
    }
}
