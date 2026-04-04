import SwiftUI
import SwiftData
import PhotosUI

struct DogProfileView: View {
    @Bindable var dog: Dog
    @Environment(\.modelContext) private var context

    @State private var viewModel = DogViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var editMode = false

    // Champs d'édition
    @State private var editName = ""
    @State private var editBreed = ""
    @State private var editDOB = Date.now

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

                        Spacer()
                    }
                }
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                List {
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

                    // Poids
                    Section("Poids") {
                        NavigationLink {
                            WeightHistoryView(dog: dog)
                        } label: {
                            Label("Poids", systemImage: "scalemass.fill")
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
                }
            }
            .background(Color(.systemGroupedBackground))
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
