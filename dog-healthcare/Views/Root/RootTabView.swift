import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query private var dogs: [Dog]

    var body: some View {
        Group {
        if let dog = dogs.first {
            VStack(spacing: 0) {
                #if DEVELOPMENT
                DevBanner()
                #endif
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
            }
            .transition(.opacity)
        } else {
            DogSetupView()
                .transition(.opacity)
        }
        }
        .animation(.easeIn(duration: 0.4), value: dogs.first?.id)
    }
}
