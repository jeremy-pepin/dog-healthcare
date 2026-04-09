import UserNotifications
import Foundation

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized = false

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
    }

    func scheduleEventNotification(id: String, title: String, subtitle: String = "", body: String, date: Date) {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleReminderNotification(_ reminder: Reminder) {
        guard reminder.isActive, let nextDue = reminder.nextDueDate else { return }
        cancel(id: reminder.notificationID)
        scheduleEventNotification(
            id: reminder.notificationID,
            title: reminder.title,
            body: "Il est temps de renouveler : \(reminder.title)",
            date: nextDue
        )
    }

    func scheduleVetEventNotification(_ event: VetEvent) {
        let notifDate = event.date.addingTimeInterval(-3600)
        let vetName = event.veterinarian?.name ?? event.vetName
        scheduleEventNotification(
            id: event.notificationID,
            title: event.title,
            subtitle: event.date.relativeDateTimeFR,
            body: vetName.map { "chez \($0)" } ?? "",
            date: notifDate
        )
    }

    func scheduleCustomEventNotification(_ event: CustomEvent) {
        let notifDate = event.date.addingTimeInterval(-3600)
        scheduleEventNotification(
            id: event.notificationID,
            title: event.title,
            subtitle: event.date.relativeDateTimeFR,
            body: "",
            date: notifDate
        )
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func refreshAllNotifications(for dog: Dog) {
        for reminder in dog.reminders ?? [] where reminder.isActive {
            scheduleReminderNotification(reminder)
        }
        for event in dog.vetEvents ?? [] where event.date > .now {
            scheduleVetEventNotification(event)
        }
        for event in dog.customEvents ?? [] where event.date > .now {
            scheduleCustomEventNotification(event)
        }
    }
}
