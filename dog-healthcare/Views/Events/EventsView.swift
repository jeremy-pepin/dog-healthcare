import SwiftUI
import SwiftData

struct EventsView: View {
    let dog: Dog
    @State private var viewModel = EventsViewModel()
    @State private var showAddVet = false
    @State private var showAddCustom = false
    @State private var isCalendarExpanded = true

    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarHeaderView(dog: dog, viewModel: viewModel, isExpanded: $isCalendarExpanded)
                Divider()
                AgendaScrollView(dog: dog, viewModel: viewModel)
            }
            .navigationTitle(viewModel.selectedMonth.monthYearString.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Aujourd'hui") {
                        viewModel.selectedDate = .now
                        viewModel.selectedMonth = .now
                    }
                    .disabled(isToday)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showAddVet = true } label: {
                            Label("RDV vétérinaire", systemImage: "stethoscope")
                        }
                        Button { showAddCustom = true } label: {
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
