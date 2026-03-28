import SwiftUI
import SwiftData

struct DashboardView: View {
    let dog: Dog
    @State private var viewModel = RemindersViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.accentColor.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Hero
                        DogHeroCard(dog: dog)

                        // Prochain RDV
                        NextEventCard(dog: dog)

                        // Rappels countdown
                        let reminders = viewModel.sortedReminders(for: dog)
                        let deworming = reminders.first { $0.reminderType == .deworming }
                        let antiParasite = reminders.first { $0.reminderType == .antiParasite }

                        HStack(spacing: 12) {
                            MiniReminderCard(
                                title: "Vermifuge",
                                systemImage: "pills.fill",
                                reminder: deworming
                            )
                            MiniReminderCard(
                                title: "Antiparasitaire",
                                systemImage: "shield.fill",
                                reminder: antiParasite
                            )
                        }

                        // Événements à venir
                        UpcomingEventsCard(dog: dog)

                        // Poids
                        if dog.latestWeight != nil {
                            WeightChipCard(dog: dog)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Hero

struct DogHeroCard: View {
    let dog: Dog

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                if let data = dog.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 70, height: 70)
                        Image(systemName: "pawprint.fill")
                            .font(.title)
                            .foregroundStyle(.tint)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.name)
                        .font(.title2.bold())
                    if !dog.breed.isEmpty {
                        Text(dog.breed)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Label(dog.age, systemImage: "birthday.cake.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Prochain RDV

struct NextEventCard: View {
    let dog: Dog

    var body: some View {
        let next = dog.nextEvent
        GlassCard(tint: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Prochain rendez-vous")

                if let event = next {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: event.systemImage)
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.headline)
                            Text(event.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(event.date.abbreviatedDateFR)
                                .font(.subheadline.weight(.semibold))
                            Text(event.date.timeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundStyle(.secondary)
                        Text("Aucun rendez-vous prévu")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - Mini Rappel

struct MiniReminderCard: View {
    let title: String
    let systemImage: String
    let reminder: Reminder?
    @Environment(\.modelContext) private var context
    @State private var showConfirm = false
    @State private var viewModel = RemindersViewModel()

    var body: some View {
        let days = reminder?.daysRemaining
        Button {
            if reminder != nil { showConfirm = true }
        } label: {
            GlassCard(tint: Color.reminderColor(daysRemaining: days)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: systemImage)
                            .font(.title3)
                            .foregroundStyle(Color.reminderColor(daysRemaining: days))
                        Spacer()
                        CountdownBadge(daysRemaining: days)
                    }

                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    if let next = reminder?.nextDueDate {
                        Text(next.abbreviatedDateFR)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Non configuré")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .confirmationDialog("Marquer comme fait ?", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Marquer comme fait") {
                if let r = reminder {
                    viewModel.markAsDone(r, context: context)
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            if let r = reminder {
                Text("\(title) — prochain dans \(r.intervalDays) jours")
            }
        }
    }
}

// MARK: - Événements à venir

struct UpcomingEventsCard: View {
    let dog: Dog

    private var upcoming: [any AppEvent] {
        let all = dog.upcomingEvents
        let slice = all.count > 1 ? Array(all.dropFirst().prefix(3)) : []
        return slice
    }

    var body: some View {
        if !upcoming.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "À venir")

                    ForEach(upcoming, id: \.notificationID) { event in
                        HStack(spacing: 10) {
                            Image(systemName: event.systemImage)
                                .frame(width: 24)
                                .foregroundStyle(.tint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.subheadline.weight(.medium))
                                Text(event.date.abbreviatedDateTimeFR)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        if event.notificationID != upcoming.last?.notificationID {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Poids

struct WeightChipCard: View {
    let dog: Dog

    var body: some View {
        NavigationLink {
            WeightHistoryView(dog: dog)
        } label: {
            GlassCard(tint: .green) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dernier poids")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let weight = dog.latestWeight {
                            Text(String(format: "%.1f kg", weight))
                                .font(.title3.bold())
                        }
                    }
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
