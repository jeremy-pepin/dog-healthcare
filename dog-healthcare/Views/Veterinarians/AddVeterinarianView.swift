import SwiftUI
import SwiftData

struct AddVeterinarianView: View {
    var existingVet: Veterinarian? = nil
    var onSave: ((Veterinarian) -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var clinic = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""

    private var isEditing: Bool { existingVet != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identité") {
                    TextField("Cabinet / Clinique", text: $clinic)
                    TextField("Nom du vétérinaire", text: $name)
                }
                Section("Contact") {
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Adresse", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Modifier le vétérinaire" : "Nouveau vétérinaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    private func populateIfEditing() {
        guard let vet = existingVet else { return }
        name    = vet.name
        clinic  = vet.clinic  ?? ""
        phone   = vet.phone   ?? ""
        address = vet.address ?? ""
        notes   = vet.notes   ?? ""
    }

    private func save() {
        if let vet = existingVet {
            vet.name    = name
            vet.clinic  = clinic.isEmpty  ? nil : clinic
            vet.phone   = phone.isEmpty   ? nil : phone
            vet.address = address.isEmpty ? nil : address
            vet.notes   = notes.isEmpty   ? nil : notes
            try? context.save()
            dismiss()
        } else {
            let vet = Veterinarian(
                name:    name,
                clinic:  clinic.isEmpty  ? nil : clinic,
                phone:   phone.isEmpty   ? nil : phone,
                address: address.isEmpty ? nil : address,
                notes:   notes.isEmpty   ? nil : notes
            )
            context.insert(vet)
            try? context.save()
            onSave?(vet)
            dismiss()
        }
    }
}
