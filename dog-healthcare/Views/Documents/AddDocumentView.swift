import SwiftUI
import SwiftData

struct AddDocumentView: View {
    let dog: Dog
    let pendingData: Data
    let pendingFileType: String
    var existingDocument: Document? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category = ""
    @State private var date = Date.now
    @State private var notes = ""

    private var isEditing: Bool { existingDocument != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private let suggestedCategories = [
        "Facture", "Ordonnance", "Carnet vaccin",
        "Radio / Écho", "Analyse", "Compte-rendu", "Autre"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    TextField("Titre", text: $title)
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }

                Section("Catégorie") {
                    TextField("Ex: Facture, Ordonnance…", text: $category)

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
                    TextField("Notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Modifier" : "Nouveau document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        if let doc = existingDocument {
            title = doc.title
            category = doc.category
            date = doc.date
            notes = doc.notes ?? ""
        }
    }

    private func save() {
        if let doc = existingDocument {
            doc.title = title
            doc.category = category.isEmpty ? "Autre" : category
            doc.date = date
            doc.notes = notes.isEmpty ? nil : notes
            try? context.save()
        } else {
            let doc = Document(
                title: title,
                category: category.isEmpty ? "Autre" : category,
                date: date,
                fileType: pendingFileType,
                data: pendingData,
                notes: notes.isEmpty ? nil : notes
            )
            doc.dog = dog
            dog.documents.append(doc)
            context.insert(doc)
            try? context.save()
        }
    }
}
