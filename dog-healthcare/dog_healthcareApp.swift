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
    let container: ModelContainer
    let isCloudKitActive: Bool

    init() {
        NotificationManager.shared.requestAuthorization()

        let schema = Schema([
            Dog.self,
            WeightEntry.self,
            VetEvent.self,
            CustomEvent.self,
            Reminder.self,
            Veterinarian.self,
            Document.self
        ])
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: config)
            isCloudKitActive = true
        } catch {
            print("⚠️ CloudKit indisponible, stockage local : \(error)")
            let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            container = try! ModelContainer(for: schema, configurations: localConfig)
            isCloudKitActive = false
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .environment(\.isCloudKitActive, isCloudKitActive)
                .modelContainer(container)
        }
    }
}
