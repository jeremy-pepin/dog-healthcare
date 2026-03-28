import SwiftUI

struct CalendarGridView: View {
    let dog: Dog
    @Bindable var viewModel: EventsViewModel

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Lundi
        return cal
    }

    private var daysInMonth: [Date?] {
        let days = viewModel.selectedMonth.daysInMonth()
        guard let first = days.first else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: offset)
        result.append(contentsOf: days.map { Optional($0) })
        return result
    }

    private var datesWithEvents: Set<Date> {
        viewModel.datesWithEvents(in: viewModel.selectedMonth, for: dog)
    }

    private var dayEvents: [any AppEvent] {
        viewModel.events(on: viewModel.selectedDate, for: dog)
    }

    private let weekdaySymbols = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Navigation mois
                HStack {
                    Button {
                        viewModel.previousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .padding(10)
                            .background(.regularMaterial, in: Circle())
                    }

                    Spacer()

                    Text(viewModel.selectedMonth.monthYearString.capitalized)
                        .font(.headline)

                    Spacer()

                    Button {
                        viewModel.nextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .padding(10)
                            .background(.regularMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                // En-têtes jours
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Grille
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                        if let day {
                            DayCell(
                                date: day,
                                isSelected: day.isInSameDay(as: viewModel.selectedDate),
                                isToday: day.isInSameDay(as: .now),
                                hasEvents: datesWithEvents.contains(where: { $0.isInSameDay(as: day) })
                            ) {
                                viewModel.selectedDate = day
                            }
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()

                // Événements du jour sélectionné
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.selectedDate.longDateFR.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if dayEvents.isEmpty {
                        Text("Aucun événement")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(dayEvents, id: \.notificationID) { event in
                                EventRowView(event: event)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                if event.notificationID != dayEvents.last?.notificationID {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    private var day: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 34, height: 34)
                    } else if isToday {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 34, height: 34)
                    }

                    Text(day)
                        .font(.callout.weight(isToday || isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
                }

                Circle()
                    .fill(hasEvents ? Color.accentColor : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}
