import SwiftUI
import SwiftData

struct DashboardView: View {
    let dog: Dog
    @State private var viewModel = RemindersViewModel()

    var body: some View {
        NavigationStack {
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

                        // Rappels urgents (en retard ou ≤ 7 jours)
                        UrgentRemindersCard(dog: dog)

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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Hero

struct DogHeroCard: View {
    let dog: Dog

    var body: some View {
        GlassCard(solidBackground: Color(white: 0.13)) {
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
                            .fill(.white.opacity(0.12))
                            .frame(width: 70, height: 70)
                        Image(systemName: "pawprint.fill")
                            .font(.title)
                            .foregroundStyle(.white)
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
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Prochain RDV

struct NextEventCard: View {
    let dog: Dog

    var body: some View {
        let next = dog.nextEvent
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Prochain rendez-vous")

                if let event = next {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue)
                                .frame(width: 44, height: 44)
                            Image(systemName: event.systemImage)
                                .font(.title3)
                                .foregroundStyle(.white)
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
                            Text(event.date.relativeDateFR)
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
    @State private var justDone = false
    @State private var viewModel = RemindersViewModel()

    var body: some View {
        let days = reminder?.daysRemaining
        Button {
            if reminder != nil { showConfirm = true }
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.reminderColor(daysRemaining: days))
                                .frame(width: 34, height: 34)
                            Image(systemName: systemImage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        CountdownBadge(daysRemaining: days)
                    }

                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    if let next = reminder?.nextDueDate {
                        Text(next.fullDateFR)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Non configuré")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .blur(radius: justDone ? 4 : 0)
                .animation(.easeInOut(duration: 0.25), value: justDone)
            }
            .overlay {
                if justDone {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.green.opacity(0.18))
                        .overlay {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.green)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .buttonStyle(.plain)
        .confirmationDialog("Marquer comme fait ?", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Marquer comme fait") {
                if let r = reminder {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) { justDone = true }
                    viewModel.markAsDone(r, context: context)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeOut(duration: 0.3)) { justDone = false }
                    }
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

// MARK: - Rappels urgents

struct UrgentRemindersCard: View {
    let dog: Dog
    @Environment(\.modelContext) private var context
    @State private var viewModel = RemindersViewModel()

    private var urgentReminders: [Reminder] {
        viewModel.sortedReminders(for: dog).filter { reminder in
            guard let days = reminder.daysRemaining else { return false }
            let excluded: Set<ReminderType> = [.deworming, .antiParasite]
            return days <= 7 && !excluded.contains(reminder.reminderType)
        }
    }

    var body: some View {
        if !urgentReminders.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Rappels à venir")

                    ForEach(urgentReminders, id: \.notificationID) { reminder in
                        UrgentReminderRow(reminder: reminder, onMarkDone: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(duration: 0.4)) {
                                viewModel.markAsDone(reminder, context: context)
                            }
                        })

                        if reminder.notificationID != urgentReminders.last?.notificationID {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct UrgentReminderRow: View {
    let reminder: Reminder
    let onMarkDone: () -> Void
    @State private var showConfirm = false

    private var accentColor: Color {
        .reminderColor(daysRemaining: reminder.daysRemaining)
    }

    var body: some View {
        Button { showConfirm = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 38, height: 38)
                    Image(systemName: reminder.reminderType.systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(reminder.title)
                        .font(.subheadline.weight(.semibold))
                    if let next = reminder.nextDueDate {
                        Text(next.fullDateFR)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                CountdownBadge(daysRemaining: reminder.daysRemaining)
            }
        }
        .buttonStyle(.plain)
        .confirmationDialog("Marquer comme fait ?", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Marquer comme fait", action: onMarkDone)
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("\(reminder.title) — prochain dans \(reminder.intervalDays) jours")
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
                                Text(event.date.relativeDateTimeFR)
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
    @State private var showAddWeight = false

    var body: some View {
        NavigationLink {
            WeightHistoryView(dog: dog)
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Poids")
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
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                showAddWeight = true
            }
        )
        .sheet(isPresented: $showAddWeight) {
            AddWeightView(dog: dog)
        }
    }
}
