import SwiftUI
import SwiftData

struct AddCustomEventView: View {
    let dog: Dog
    var viewModel: EventsViewModel
    var existingEvent: CustomEvent? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date.now
    @State private var category = ""
    @State private var notes = ""

    private var isEditing: Bool { existingEvent != nil }

    private let suggestedCategories = [
        "Toilettage", "Kinésithérapie", "Garde", "Autre"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Événement") {
                    TextField("Titre", text: $title)
                    DatePicker("Date et heure", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Catégorie") {
                    TextField("Ex: Toilettage, Kiné...", text: $category)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedCategories, id: \.self) { cat in
                                Button {
                                    category = cat
                                    if title.isEmpty { title = cat }
                                } label: {
                                    Text(cat)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            category == cat ? Color.accentColor : Color.secondary.opacity(0.15),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(category == cat ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Modifier l'événement" : "Nouvel événement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        if let event = existingEvent {
                            viewModel.updateCustomEvent(
                                event,
                                title: title.isEmpty ? category : title,
                                date: date,
                                category: category.isEmpty ? "Autre" : category,
                                notes: notes.isEmpty ? nil : notes,
                                context: context
                            )
                        } else {
                            viewModel.addCustomEvent(
                                title: title.isEmpty ? category : title,
                                date: date,
                                category: category.isEmpty ? "Autre" : category,
                                notes: notes.isEmpty ? nil : notes,
                                dog: dog,
                                context: context
                            )
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty && category.isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let event = existingEvent else { return }
        title = event.title
        date = event.date
        category = event.category
        notes = event.notes ?? ""
    }
}
