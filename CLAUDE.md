# Dog Healthcare — iOS App

Application iOS de suivi santé pour chiens, construite avec SwiftUI et SwiftData.

## Stack technique

- **Langage** : Swift (Swift 6.3 / Xcode 26.3)
- **Cible iOS** : iOS 26.2+
- **UI** : 100% SwiftUI
- **Persistance** : SwiftData
- **Localisation** : Français (fr_FR)
- **Frameworks** : UserNotifications, PhotosUI, UniformTypeIdentifiers

## Structure du projet

```
dog-healthcare/
├── Models/          # Modèles SwiftData (Dog, WeightEntry, VetEvent, CustomEvent, Reminder, Veterinarian, Document)
├── Views/           # Composants UI organisés par feature
├── ViewModels/      # DogViewModel, EventsViewModel, RemindersViewModel (@Observable)
├── Managers/        # NotificationManager (singleton)
├── Utilities/       # Extensions (Date, etc.)
├── ContentView.swift
└── dog_healthcareApp.swift
```

## Architecture

- **Pattern Observable** : ViewModels utilisent le macro `@Observable` (Swift 5.9+)
- **Query-driven UI** : `@Query` SwiftData pour le binding réactif
- **Protocol AppEvent** : adopté par `VetEvent` et `CustomEvent` pour le polymorphisme
- **ModelContainer** : `Dog`, `WeightEntry`, `VetEvent`, `CustomEvent`, `Reminder`, `Veterinarian`, `Document` — suppressions en cascade

## Fonctionnalités principales

1. **Dashboard** — carte chien, prochain RDV vétérinaire, rappels santé, poids
2. **Agenda** — vue liste et grille calendrier, deux types d'événements (vétérinaire / personnalisé)
3. **Rappels** — vermifuge (90j), antiparasitaire (30j), vaccins (365j), rappels personnalisés
4. **Documents** — scan et import de PDFs/photos, regroupés par catégorie
5. **Profil** — suivi du poids avec graphique, liste des vétérinaires, onboarding

## Conventions

- L'interface et les libellés sont **entièrement en français**
- Les dates sont formatées avec les extensions Swift localisées `fr_FR`
- Les rappels utilisent un code couleur : rouge (en retard), orange (< 7 jours), vert (ok)
- Les photos et documents sont stockés en **external storage** SwiftData
- L'onboarding s'affiche automatiquement si aucun chien n'est enregistré (`dogs.isEmpty`)
- Composants UI réutilisables : `GlassCard` (`.regularMaterial`), `CountdownBadge`, `SectionHeader`
