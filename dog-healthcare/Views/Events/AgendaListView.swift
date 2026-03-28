import SwiftUI
import SwiftData

enum EventFilter: String, CaseIterable {
    case upcoming = "À venir"
    case past     = "Passés"
    case all      = "Tous"

    var systemImage: String {
        switch self {
        case .upcoming: return "arrow.forward.circle"
        case .past:     return "clock.arrow.circlepath"
        case .all:      return "list.bullet"
        }
    }
}

struct AgendaListView: View {
    let dog: Dog
    @Bindable var viewModel: EventsViewModel
    @Environment(\.modelContext) private var context

    @State private var searchText = ""
    @State private var filter: EventFilter = .upcoming
    @State private var vetEventToEdit: VetEvent?
    @State private var customEventToEdit: CustomEvent?

    private var filteredEvents: [any AppEvent] {
        let today = Calendar.current.startOfDay(for: .now)
        let base: [any AppEvent] = switch filter {
        case .upcoming: viewModel.allEvents(for: dog).filter { $0.date >= today }
        case .past:     viewModel.allEvents(for: dog).filter { $0.date < today }
        case .all:      viewModel.allEvents(for: dog)
        }
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) || $0.category.lowercased().contains(q)
        }
    }

    private var groupedEvents: [(date: Date, events: [any AppEvent])] {
        var groups: [Date: [any AppEvent]] = [:]
        for event in filteredEvents {
            let day = Calendar.current.startOfDay(for: event.date)
            groups[day, default: []].append(event)
        }
        let sorted = groups
            .map { (date: $0.key, events: $0.value.sorted { $0.date < $1.date }) }
        return filter == .past
            ? sorted.sorted { $0.date > $1.date }
            : sorted.sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            // Badges filtre — toujours visibles
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventFilter.allCases, id: \.self) { f in
                            FilterBadge(label: f.rawValue, icon: f.systemImage, isSelected: filter == f) {
                                withAnimation(.spring(duration: 0.25)) { filter = f }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)

            if groupedEvents.isEmpty {
                ContentUnavailableView {
                    Label(searchText.isEmpty ? "Aucun événement" : "Aucun résultat",
                          systemImage: searchText.isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass")
                } description: {
                    Text(searchText.isEmpty ? "Ajoutez des rendez-vous ou événements\nvia le bouton +" : "Essayez un autre terme de recherche")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(groupedEvents, id: \.date) { group in
                    Section {
                        ForEach(group.events, id: \.notificationID) { event in
                            EventRowView(event: event)
                                .contentShape(Rectangle())
                                .onTapGesture { openEdit(event) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteEvent(event)
                                    } label: {
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
                    } header: {
                        Text(group.date.longDateFR)
                            .textCase(nil)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Rechercher un événement")
        .sheet(item: $vetEventToEdit) { (event: VetEvent) in
            AddVetEventView(dog: dog, viewModel: viewModel, existingEvent: event)
        }
        .sheet(item: $customEventToEdit) { (event: CustomEvent) in
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

struct FilterBadge: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1), in: Capsule())
                .foregroundStyle(isSelected ? .white : .accentColor)
        }
        .buttonStyle(.plain)
    }
}

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
