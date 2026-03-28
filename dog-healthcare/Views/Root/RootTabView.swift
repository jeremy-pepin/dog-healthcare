import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query private var dogs: [Dog]

    var body: some View {
        if let dog = dogs.first {
            TabView {
                Tab("Accueil", systemImage: "house.fill") {
                    DashboardView(dog: dog)
                }
                Tab("Agenda", systemImage: "calendar") {
                    EventsView(dog: dog)
                }
                Tab("Rappels", systemImage: "bell.fill") {
                    RemindersView(dog: dog)
                }
                Tab("Documents", systemImage: "doc.fill") {
                    DocumentsView(dog: dog)
                }
                Tab("Profil", systemImage: "pawprint.fill") {
                    DogProfileView(dog: dog)
                }
            }
            .onAppear {
                NotificationManager.shared.refreshAllNotifications(for: dog)
            }
        } else {
            DogSetupView()
        }
    }
}
