import SwiftUI
import SwiftData

struct AddWeightView: View {
    let dog: Dog
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var weight = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var viewModel = DogViewModel()

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
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: [.date])
                }

                Section("Note (optionnel)") {
                    TextField("Ex: après stérilisation", text: $note)
                }
            }
            .navigationTitle("Ajouter un poids")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        if let w = weightValue {
                            viewModel.addWeightEntry(
                                value: w,
                                date: date,
                                note: note.isEmpty ? nil : note,
                                dog: dog,
                                context: context
                            )
                            dismiss()
                        }
                    }
                    .disabled(weightValue == nil)
                }
            }
        }
    }
}
