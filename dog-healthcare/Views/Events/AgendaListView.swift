import SwiftUI
import SwiftData

// MARK: - Liste agenda avec scroll synchronisé

struct AgendaScrollView: View {
    let dog: Dog
    @Bindable var viewModel: EventsViewModel
    @Environment(\.modelContext) private var context

    @State private var vetEventToEdit: VetEvent?
    @State private var customEventToEdit: CustomEvent?

    private let cal = Calendar.current

    private var groupedEvents: [(date: Date, events: [any AppEvent])] {
        let today = cal.startOfDay(for: .now)
        let selected = cal.startOfDay(for: viewModel.selectedDate)

        var groups: [Date: [any AppEvent]] = [:]
        for event in viewModel.futureEvents(for: dog) {
            let day = cal.startOfDay(for: event.date)
            groups[day, default: []].append(event)
        }

        // Toujours afficher aujourd'hui même sans événement
        if groups[today] == nil { groups[today] = [] }
        // Afficher la date sélectionnée si dans le futur
        if selected >= today && groups[selected] == nil {
            groups[selected] = []
        }

        return groups
            .map { (date: $0.key, events: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(groupedEvents, id: \.date) { group in
                    Section {
                        if group.events.isEmpty {
                            Text("Aucun événement")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(group.events, id: \.notificationID) { event in
                                EventRowView(event: event)
                                    .contentShape(Rectangle())
                                    .onTapGesture { openEdit(event) }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) { deleteEvent(event) } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button { openEdit(event) } label: {
                                            Label("Modifier", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    } header: {
                        AgendaDateHeader(date: group.date)
                    }
                    .id(group.date)
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: viewModel.selectedDate) { _, newDate in
                let day = cal.startOfDay(for: newDate)
                if groupedEvents.contains(where: { cal.isDate($0.date, inSameDayAs: day) }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(day, anchor: .top)
                    }
                }
            }
        }
        .sheet(item: $vetEventToEdit) { event in
            AddVetEventView(dog: dog, viewModel: viewModel, existingEvent: event)
        }
        .sheet(item: $customEventToEdit) { event in
            AddCustomEventView(dog: dog, viewModel: viewModel, existingEvent: event)
        }
    }

    private func openEdit(_ event: any AppEvent) {
        if let vet = event as? VetEvent { vetEventToEdit = vet }
        else if let custom = event as? CustomEvent { customEventToEdit = custom }
    }

    private func deleteEvent(_ event: any AppEvent) {
        if let vet = event as? VetEvent {
            viewModel.deleteVetEvent(vet, dog: dog, context: context)
        } else if let custom = event as? CustomEvent {
            viewModel.deleteCustomEvent(custom, dog: dog, context: context)
        }
    }
}

// MARK: - En-tête de section date

struct AgendaDateHeader: View {
    let date: Date

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isTomorrow: Bool { Calendar.current.isDateInTomorrow(date) }

    var body: some View {
        HStack(spacing: 5) {
            if isToday {
                Text("Aujourd'hui")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(date.longDateFR.capitalized)
                    .foregroundStyle(.secondary)
            } else if isTomorrow {
                Text("Demain")
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(date.longDateFR.capitalized)
                    .foregroundStyle(.secondary)
            } else {
                Text(date.longDateFR.capitalized)
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
            }
        }
        .font(.subheadline)
        .textCase(nil)
    }
}

// MARK: - Ligne événement

struct EventRowView: View {
    let event: any AppEvent

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: event.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(event.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(event.date.timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
