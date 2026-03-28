import SwiftUI
import SwiftData

struct WeightHistoryView: View {
    @Bindable var dog: Dog
    @Environment(\.modelContext) private var context
    @State private var viewModel = DogViewModel()
    @State private var showAddWeight = false

    var body: some View {
        List {
            Section {
                WeightChartView(entries: dog.weightEntries)
                    .listRowInsets(EdgeInsets())
                    .padding()
            }

            Section("Historique") {
                if dog.weightEntries.isEmpty {
                    Text("Aucune mesure enregistrée")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dog.weightEntries.sorted { $0.date > $1.date }) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.1f kg", entry.value))
                                    .font(.headline)
                                Text(entry.date.abbreviatedDateFR)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let note = entry.note {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteWeightEntry(entry, dog: dog, context: context)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Poids")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddWeight = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddWeight) {
            AddWeightView(dog: dog)
        }
    }
}
