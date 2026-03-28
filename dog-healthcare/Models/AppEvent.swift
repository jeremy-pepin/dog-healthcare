import Foundation

protocol AppEvent: Identifiable {
    var title: String { get }
    var date: Date { get }
    var category: String { get }
    var systemImage: String { get }
    var notificationID: String { get }
    var notes: String? { get }
}
