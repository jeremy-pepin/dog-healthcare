import SwiftUI
import SwiftData

struct AddReminderView: View {
    let dog: Dog
    var existingReminder: Reminder? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedType: ReminderType = .custom
    @State private var intervalDays = 30
    @State private var customInterval = "30"
    @State private var hasLastDone = false
    @State private var lastDoneDate = Date.now
    @State private var viewModel = RemindersViewModel()

    private var isEditing: Bool { existingReminder != nil }
    private let presets = [7, 14, 30, 60, 90, 180, 365]

    var body: some View {
        NavigationStack {
            Form {
                Section("Rappel") {
                    TextField("Nom du rappel", text: $title)

                    Picker("Type", selection: $selectedType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .onChange(of: selectedType) {
                        if !isEditing && (title.isEmpty || presetTitles.contains(title)) {
                            title = selectedType.rawValue
                        }
                        if !isEditing {
                            intervalDays = selectedType.defaultIntervalDays
                            customInterval = "\(intervalDays)"
                        }
                    }
                }

                Section("Fréquence") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Raccourcis")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.self) { preset in
                                    Button {
                                        withAnimation(.spring(duration: 0.2)) {
                                            intervalDays = preset
                                            customInterval = "\(preset)"
                                        }
                                    } label: {
                                        Text(presetLabel(preset))
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                intervalDays == preset ? Color.accentColor : Color.secondary.opacity(0.15),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(intervalDays == preset ? Color(.systemBackground) : .primary)
                                            .animation(.spring(duration: 0.2), value: intervalDays)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    HStack {
                        Text("Tous les")
                        TextField("30", text: $customInterval)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(.vertical, 6)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .onChange(of: customInterval) {
                                if let days = Int(customInterval), days > 0 {
                                    intervalDays = days
                                }
                            }
                        Text("jours")
                    }
                }

                Section("Dernier traitement") {
                    Toggle("Déjà effectué", isOn: $hasLastDone.animation(.spring(duration: 0.3)))
                    if hasLastDone {
                        DatePicker("Date", selection: $lastDoneDate, in: ...Date.now, displayedComponents: .date)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .navigationTitle(isEditing ? "Modifier le rappel" : "Nouveau rappel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        if isEditing {
                            saveEdit()
                        } else {
                            viewModel.addReminder(
                                title: title.isEmpty ? selectedType.rawValue : title,
                                type: selectedType,
                                intervalDays: intervalDays,
                                lastDoneDate: hasLastDone ? lastDoneDate : nil,
                                dog: dog,
                                context: context
                            )
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        if let r = existingReminder {
            title = r.title
            selectedType = r.reminderType
            intervalDays = r.intervalDays
            customInterval = "\(r.intervalDays)"
            if let last = r.lastDoneDate {
                hasLastDone = true
                lastDoneDate = last
            }
        } else {
            title = selectedType.rawValue
            customInterval = "\(selectedType.defaultIntervalDays)"
            intervalDays = selectedType.defaultIntervalDays
        }
    }

    private func saveEdit() {
        guard let r = existingReminder else { return }
        r.title = title
        r.type = selectedType.rawValue
        r.intervalDays = intervalDays
        r.lastDoneDate = hasLastDone ? lastDoneDate : nil
        try? context.save()
        NotificationManager.shared.scheduleReminderNotification(r)
    }

    private var presetTitles: [String] {
        ReminderType.allCases.map { $0.rawValue }
    }

    private func presetLabel(_ days: Int) -> String {
        switch days {
        case 7: return "1 sem."
        case 14: return "2 sem."
        case 30: return "1 mois"
        case 60: return "2 mois"
        case 90: return "3 mois"
        case 180: return "6 mois"
        case 365: return "1 an"
        default: return "\(days)j"
        }
    }
}
