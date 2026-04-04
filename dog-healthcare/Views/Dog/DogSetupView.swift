import SwiftUI
import SwiftData
import PhotosUI

struct DogSetupView: View {
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var breed = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -2, to: .now) ?? .now
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isCreating = false

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.accentColor.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)
                            .padding(24)
                            .background {
                                Circle()
                                    .fill(.regularMaterial)
                                    .overlay {
                                        Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                    }
                            }

                        Text("Bienvenue !")
                            .font(.largeTitle.bold())

                        Text("Commençons par créer le profil de votre chien.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    GlassCard(solidBackground: Color(white: 0.13)) {
                        VStack(spacing: 20) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    if let data = photoData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(.regularMaterial)
                                            .frame(width: 90, height: 90)
                                            .overlay {
                                                Image(systemName: "camera.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.secondary)
                                            }
                                    }
                                }
                            }
                            .onChange(of: selectedPhoto) {
                                Task {
                                    photoData = try? await selectedPhoto?.loadTransferable(type: Data.self)
                                }
                            }

                            VStack(spacing: 16) {
                                TextField("Nom du chien", text: $name)
                                    .textFieldStyle(.plain)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                                TextField("Race (optionnel)", text: $breed)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                                DatePicker("Date de naissance", selection: $dateOfBirth, in: ...Date.now, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                            }
                        }
                    }
                    .environment(\.colorScheme, .dark)
                    .padding(.horizontal)

                    Button {
                        createDog()
                    } label: {
                        Text("Créer le profil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCreate || isCreating)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func createDog() {
        isCreating = true
        let dog = Dog(
            name: name.trimmingCharacters(in: .whitespaces),
            breed: breed.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            photoData: photoData
        )
        context.insert(dog)

        // Rappels par défaut
        let defaultReminders: [(String, ReminderType, Int)] = [
            ("Vermifuge", .deworming, 90),
            ("Antiparasitaire", .antiParasite, 30),
            ("Vaccin annuel", .vaccine, 365)
        ]
        for (title, type, interval) in defaultReminders {
            let reminder = Reminder(title: title, type: type, intervalDays: interval)
            reminder.dog = dog
            dog.reminders = (dog.reminders ?? []) + [reminder]
            context.insert(reminder)
        }

        try? context.save()
    }
}
