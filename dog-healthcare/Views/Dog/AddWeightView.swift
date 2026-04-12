import SwiftUI
import SwiftData

struct AddWeightView: View {
    let dog: Dog
    var existingEntry: WeightEntry? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var weight = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var viewModel = DogViewModel()
    @FocusState private var weightFocused: Bool

    private var isEditing: Bool { existingEntry != nil }

    private var weightValue: Double? {
        Double(weight.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Poids") {
                    HStack {
                        TextField("0.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .focused($weightFocused)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                    .listRowSeparator(.hidden)
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: [.date])
                }

                Section("Note (optionnel)") {
                    TextField("Ex: après stérilisation", text: $note)
                }
            }
            .navigationTitle(isEditing ? "Modifier le poids" : "Ajouter un poids")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        if let w = weightValue {
                            if let entry = existingEntry {
                                entry.value = w
                                entry.date = date
                                entry.note = note.isEmpty ? nil : note
                                try? context.save()
                            } else {
                                viewModel.addWeightEntry(
                                    value: w,
                                    date: date,
                                    note: note.isEmpty ? nil : note,
                                    dog: dog,
                                    context: context
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(weightValue == nil)
                }
            }
            .onAppear {
                if let entry = existingEntry {
                    weight = String(format: "%.2f", entry.value).replacingOccurrences(of: ".", with: ",")
                    date = entry.date
                    note = entry.note ?? ""
                }
                weightFocused = true
            }
        }
    }
}
