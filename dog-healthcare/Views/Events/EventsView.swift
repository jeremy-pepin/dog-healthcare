import SwiftUI
import SwiftData

struct EventsView: View {
    let dog: Dog
    @State private var viewModel = EventsViewModel()
    @State private var showAddVet = false
    @State private var showAddCustom = false
    @State private var displayMode: DisplayMode = .agenda

    enum DisplayMode { case agenda, calendar }

    var body: some View {
        NavigationStack {
            TabView(selection: $displayMode) {
                AgendaListView(dog: dog, viewModel: viewModel)
                    .tag(DisplayMode.agenda)
                CalendarGridView(dog: dog, viewModel: viewModel)
                    .tag(DisplayMode.calendar)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: displayMode)
            .navigationTitle("Agenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Vue", selection: $displayMode) {
                        Text("Liste").tag(DisplayMode.agenda)
                        Text("Calendrier").tag(DisplayMode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddVet = true
                        } label: {
                            Label("RDV vétérinaire", systemImage: "stethoscope")
                        }
                        Button {
                            showAddCustom = true
                        } label: {
                            Label("Autre événement", systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddVet) {
                AddVetEventView(dog: dog, viewModel: viewModel)
            }
            .sheet(isPresented: $showAddCustom) {
                AddCustomEventView(dog: dog, viewModel: viewModel)
            }
        }
    }
}
