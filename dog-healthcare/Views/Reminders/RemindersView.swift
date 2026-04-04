import SwiftUI
import SwiftData

struct RemindersView: View {
    let dog: Dog
    @Environment(\.modelContext) private var context
    @State private var viewModel = RemindersViewModel()
    @State private var showAdd = false
    @State private var reminderToEdit: Reminder?

    var body: some View {
        NavigationStack {
            Group {
                let reminders = viewModel.sortedReminders(for: dog)
                if reminders.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun rappel", systemImage: "bell.slash")
                    } description: {
                        Text("Ajoutez des rappels pour le vermifuge,\nl'antiparasitaire ou tout autre soin.")
                    } actions: {
                        Button("Ajouter un rappel") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        let overdue = reminders.filter { $0.isOverdue }
                        let upcoming = reminders.filter { !$0.isOverdue }

                        if !overdue.isEmpty {
                            Section {
                                ForEach(overdue) { reminder in
                                    ReminderRowView(reminder: reminder) {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        withAnimation(.spring(duration: 0.3)) {
                                            viewModel.markAsDone(reminder, context: context)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { reminderToEdit = reminder }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation(.spring(duration: 0.3)) {
                                                viewModel.deleteReminder(reminder, dog: dog, context: context)
                                            }
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            reminderToEdit = reminder
                                        } label: {
                                            Label("Modifier", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: {
                                Label("En retard", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                        if !upcoming.isEmpty {
                            Section("À venir") {
                                ForEach(upcoming) { reminder in
                                    ReminderRowView(reminder: reminder) {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        withAnimation(.spring(duration: 0.3)) {
                                            viewModel.markAsDone(reminder, context: context)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { reminderToEdit = reminder }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation(.spring(duration: 0.3)) {
                                                viewModel.deleteReminder(reminder, dog: dog, context: context)
                                            }
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            reminderToEdit = reminder
                                        } label: {
                                            Label("Modifier", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Rappels")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddReminderView(dog: dog)
            }
            .sheet(item: $reminderToEdit) { reminder in
                AddReminderView(dog: dog, existingReminder: reminder)
            }
        }
    }
}
