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

        // Annule les notifs existantes (ancien ID + nouveaux suffixes)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminder.notificationID, reminder.notificationID + "_week", reminder.notificationID + "_day"]
        )

        // 1 semaine avant à 9h
        if let weekBefore = Calendar.current.date(byAdding: .day, value: -7, to: nextDue) {
            scheduleEventNotification(
                id: reminder.notificationID + "_week",
                title: reminder.title,
                body: "dans 7 jours",
                date: at9h(weekBefore)
            )
        }

        // Le jour J à 9h
        scheduleEventNotification(
            id: reminder.notificationID + "_day",
            title: reminder.title,
            body: "aujourd'hui",
            date: at9h(nextDue)
        )
    }

    private func at9h(_ date: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? date
    }

    func scheduleVetEventNotification(_ event: VetEvent) {
        let notifDate = event.date.addingTimeInterval(-3600)
        scheduleEventNotification(
            id: event.notificationID,
            title: event.title,
            body: event.date.relativeDateTimeFR,
            date: notifDate
        )
    }

    func scheduleCustomEventNotification(_ event: CustomEvent) {
        let notifDate = event.date.addingTimeInterval(-3600)
        scheduleEventNotification(
            id: event.notificationID,
            title: event.title,
            body: event.date.relativeDateTimeFR,
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
