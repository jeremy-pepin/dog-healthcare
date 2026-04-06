import SwiftUI
import SwiftData

struct AddVetEventView: View {
    let dog: Dog
    var viewModel: EventsViewModel
    var existingEvent: VetEvent? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Veterinarian.name) private var vets: [Veterinarian]

    @State private var title = "Consultation vétérinaire"
    @State private var date = Date.now
    @State private var selectedVet: Veterinarian? = nil
    @State private var notes = ""
    @State private var showAddVet = false

    private var isEditing: Bool { existingEvent != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Événement") {
                    TextField("Titre", text: $title)
                    HStack {
                        Text("Date et heure")
                        Spacer(minLength: 8)
                        DatePickerWithInterval(selection: $date, minuteInterval: 5)
                            .frame(height: 34)
                    }
                }

                Section("Vétérinaire (optionnel)") {
                    if vets.isEmpty {
                        Button {
                            showAddVet = true
                        } label: {
                            Label("Ajouter un vétérinaire", systemImage: "plus.circle.fill")
                        }
                    } else {
                        Picker("Vétérinaire", selection: $selectedVet) {
                            Text("Aucun").tag(Optional<Veterinarian>.none)
                            ForEach(vets) { vet in
                                Text(vet.displayName).tag(Optional(vet))
                            }
                        }

                        if let vet = selectedVet, let clinic = vet.clinic {
                            Label(clinic, systemImage: "building.2.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 2)
                        }

                        if selectedVet == nil {
                            Button {
                                showAddVet = true
                            } label: {
                                Label("Ajouter un vétérinaire...", systemImage: "plus.circle")
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Modifier le RDV" : "RDV vétérinaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        if let event = existingEvent {
                            viewModel.updateVetEvent(
                                event,
                                title: title,
                                date: date,
                                veterinarian: selectedVet,
                                notes: notes.isEmpty ? nil : notes,
                                context: context
                            )
                        } else {
                            viewModel.addVetEvent(
                                title: title,
                                date: date,
                                veterinarian: selectedVet,
                                notes: notes.isEmpty ? nil : notes,
                                dog: dog,
                                context: context
                            )
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showAddVet) {
                AddVeterinarianView { newVet in
                    selectedVet = newVet
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let event = existingEvent else { return }
        title = event.title
        date = event.date
        selectedVet = event.veterinarian
        notes = event.notes ?? ""
    }
}
