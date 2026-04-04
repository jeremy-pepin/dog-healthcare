import SwiftUI
import SwiftData
import PhotosUI

struct DogProfileView: View {
    @Bindable var dog: Dog
    @Environment(\.modelContext) private var context

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showEditSheet = false

    private static let french = Locale(identifier: "fr_FR")

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GlassCard(solidBackground: Color(white: 0.13)) {
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
                            Text(dog.name)
                                .font(.title2.bold())
                            if !dog.breed.isEmpty {
                                Text(dog.breed)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                List {
                    Section("Informations") {
                        LabeledContent("Date de naissance") {
                            Text(dog.dateOfBirth.formatted(.dateTime.day().month(.wide).year().locale(Self.french)))
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("Âge") {
                            Text(dog.age)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Poids") {
                        NavigationLink {
                            WeightHistoryView(dog: dog)
                        } label: {
                            Label("Poids", systemImage: "scalemass.fill")
                        }
                    }

                    Section("Vétérinaires") {
                        NavigationLink {
                            VeterinarianListView()
                        } label: {
                            Label("Mes vétérinaires", systemImage: "stethoscope")
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Modifier") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditDogView(dog: dog)
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
                .fill(.white.opacity(0.12))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
        }
    }
}

// MARK: - Feuille d'édition

struct EditDogView: View {
    @Bindable var dog: Dog
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var breed = ""
    @State private var dateOfBirth = Date.now
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var viewModel = DogViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 14) {
                            photoPreview
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo")
                                    .font(.headline)
                                Text("Appuyer pour modifier")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: selectedPhoto) {
                        Task {
                            if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                }

                Section("Identité") {
                    TextField("Nom", text: $name)
                    TextField("Race (optionnel)", text: $breed)
                }

                Section("Date de naissance") {
                    DatePicker("Date", selection: $dateOfBirth, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        viewModel.updateDog(
                            dog: dog,
                            name: name.trimmingCharacters(in: .whitespaces),
                            breed: breed.trimmingCharacters(in: .whitespaces),
                            dob: dateOfBirth,
                            photoData: photoData ?? dog.photoData,
                            context: context
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = dog.name
                breed = dog.breed
                dateOfBirth = dog.dateOfBirth
                photoData = dog.photoData
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let data = photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
