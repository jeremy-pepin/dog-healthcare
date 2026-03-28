import SwiftUI
import SwiftData

struct VeterinarianListView: View {
    @Query(sort: \Veterinarian.name) private var vets: [Veterinarian]
    @Environment(\.modelContext) private var context

    @State private var showAdd = false
    @State private var vetToEdit: Veterinarian?

    var body: some View {
        Group {
            if vets.isEmpty {
                ContentUnavailableView {
                    Label("Aucun vétérinaire", systemImage: "stethoscope")
                } description: {
                    Text("Ajoutez votre vétérinaire via le bouton +")
                }
            } else {
                List {
                    ForEach(vets) { vet in
                        VeterinarianRowView(vet: vet)
                            .contentShape(Rectangle())
                            .onTapGesture { vetToEdit = vet }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    context.delete(vet)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button { vetToEdit = vet } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .navigationTitle("Vétérinaires")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddVeterinarianView()
        }
        .sheet(item: $vetToEdit) { (vet: Veterinarian) in
            AddVeterinarianView(existingVet: vet)
        }
    }
}

private struct VeterinarianRowView: View {
    let vet: Veterinarian

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "stethoscope")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(vet.name)
                    .font(.headline)
                if let clinic = vet.clinic {
                    Text(clinic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let phone = vet.phone {
                    Label(phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
