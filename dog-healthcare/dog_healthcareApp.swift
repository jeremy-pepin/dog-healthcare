//
//  dog_healthcareApp.swift
//  dog-healthcare
//
//  Created by Jérémy PEPIN on 28/03/2026.
//

import SwiftUI
import SwiftData

@main
struct dog_healthcareApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .modelContainer(for: [
                    Dog.self,
                    WeightEntry.self,
                    VetEvent.self,
                    CustomEvent.self,
                    Reminder.self,
                    Veterinarian.self,
                    Document.self
                ])
        }
    }

    init() {
        NotificationManager.shared.requestAuthorization()
    }
}
