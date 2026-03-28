import SwiftUI
import SwiftData

struct AgendaListView: View {
    let dog: Dog
    @Bindable var viewModel: EventsViewModel
    @Environment(\.modelContext) private var context

    @State private var vetEventToEdit: VetEvent?
    @State private var customEventToEdit: CustomEvent?

    private var groupedEvents: [(date: Date, events: [any AppEvent])] {
        let events = viewModel.futureEvents(for: dog)
        var groups: [Date: [any AppEvent]] = [:]
        for event in events {
            let day = Calendar.current.startOfDay(for: event.date)
            groups[day, default: []].append(event)
        }
        return groups
            .map { (date: $0.key, events: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        Group {
            if groupedEvents.isEmpty {
                ContentUnavailableView {
                    Label("Aucun événement", systemImage: "calendar.badge.exclamationmark")
                } description: {
                    Text("Ajoutez des rendez-vous ou événements\nvia le bouton +")
                }
            } else {
                List {
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
                .listStyle(.insetGrouped)
            }
        }
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
