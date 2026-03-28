import SwiftUI
import SwiftData
import PhotosUI

struct DogProfileView: View {
    @Bindable var dog: Dog
    @Environment(\.modelContext) private var context

    @State private var viewModel = DogViewModel()
    @State private var showAddWeight = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var editMode = false

    // Champs d'édition
    @State private var editName = ""
    @State private var editBreed = ""
    @State private var editDOB = Date.now

    private static let french = Locale(identifier: "fr_FR")

    var body: some View {
        NavigationStack {
            List {
                // Photo + identité
                Section {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            dogPhoto
                        }
                        .onChange(of: selectedPhoto) {
                            Task {
                                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                                    dog.photoData = data
                                    try? context.save()
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if editMode {
                                TextField("Nom", text: $editName)
                                    .font(.title2.bold())
                                TextField("Race", text: $editBreed)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(dog.name)
                                    .font(.title2.bold())
                                if !dog.breed.isEmpty {
                                    Text(dog.breed)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Informations
                Section("Informations") {
                    if editMode {
                        DatePicker("Date de naissance", selection: $editDOB, in: ...Date.now, displayedComponents: .date)
                    } else {
                        LabeledContent("Date de naissance") {
                            Text(dog.dateOfBirth.formatted(.dateTime.day().month(.wide).year().locale(Self.french)))
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("Âge") {
                            Text(dog.age)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Vétérinaires
                Section("Vétérinaires") {
                    NavigationLink {
                        VeterinarianListView()
                    } label: {
                        Label("Mes vétérinaires", systemImage: "stethoscope")
                    }
                }

                // Poids
                Section {
                    WeightChartView(entries: dog.weightEntries)
                        .listRowInsets(EdgeInsets())
                        .padding()

                    if let latest = dog.latestWeight {
                        LabeledContent("Dernier poids") {
                            Text(String(format: "%.1f kg", latest))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showAddWeight = true
                    } label: {
                        Label("Ajouter un poids", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Poids")
                }

                // Historique poids
                if !dog.weightEntries.isEmpty {
                    Section("Historique") {
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
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(editMode ? "Enregistrer" : "Modifier") {
                        if editMode {
                            viewModel.updateDog(
                                dog: dog,
                                name: editName,
                                breed: editBreed,
                                dob: editDOB,
                                photoData: dog.photoData,
                                context: context
                            )
                        } else {
                            editName = dog.name
                            editBreed = dog.breed
                            editDOB = dog.dateOfBirth
                        }
                        editMode.toggle()
                    }
                }
            }
            .sheet(isPresented: $showAddWeight) {
                AddWeightView(dog: dog)
            }
        }
    }

    @ViewBuilder
    private var dogPhoto: some View {
        if let data = dog.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
        } else {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
