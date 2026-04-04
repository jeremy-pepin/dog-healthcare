import SwiftUI
import SwiftData

struct EventsView: View {
    let dog: Dog
    @State private var viewModel = EventsViewModel()
    @State private var showAddVet = false
    @State private var showAddCustom = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            AgendaListView(dog: dog, viewModel: viewModel, searchText: $searchText)
                .navigationTitle("Agenda")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, prompt: "Rechercher un événement")
                .toolbar {
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
