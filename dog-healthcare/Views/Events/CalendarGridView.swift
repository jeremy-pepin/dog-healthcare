import SwiftUI

// MARK: - Header collapsible (mois ↔ bande semaine)

struct CalendarHeaderView: View {
    let dog: Dog
    @Bindable var viewModel: EventsViewModel
    @Binding var isExpanded: Bool

    private var cal: Calendar { .mondayFirst }

    // Tous les jours du mois affiché avec les cases vides au début
    private var daysInMonth: [Date?] {
        let days = viewModel.selectedMonth.daysInMonth()
        guard let first = days.first else { return [] }
        let weekday = cal.component(.weekday, from: first)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: offset)
        result.append(contentsOf: days.map { Optional($0) })
        return result
    }

    // Les 7 jours de la semaine contenant selectedDate
    private var weekDays: [Date] {
        let weekday = cal.component(.weekday, from: viewModel.selectedDate)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        guard let monday = cal.date(byAdding: .day, value: -offset, to: viewModel.selectedDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private var monthDatesWithEvents: Set<Date> {
        viewModel.datesWithEvents(in: viewModel.selectedMonth, for: dog)
    }

    private var weekDatesWithEvents: Set<Date> {
        let events = viewModel.allEvents(for: dog)
        var result = Set<Date>()
        for day in weekDays {
            if events.contains(where: { $0.date.isInSameDay(as: day) }) {
                result.insert(day)
            }
        }
        return result
    }

    private let weekdayLetters = ["L", "M", "M", "J", "V", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Barre de navigation mois / titre cliquable
            HStack(spacing: 0) {
                Button {
                    if isExpanded { viewModel.previousMonth() }
                    else { viewModel.previousWeek() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedMonth.monthYearString.capitalized)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    if isExpanded { viewModel.nextMonth() }
                    else { viewModel.nextWeek() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 4)

            // Initiales des jours de la semaine
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

            if isExpanded {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                        if let day {
                            DayCell(
                                date: day,
                                isSelected: day.isInSameDay(as: viewModel.selectedDate),
                                isToday: day.isInSameDay(as: .now),
                                hasEvents: monthDatesWithEvents.contains(where: { $0.isInSameDay(as: day) })
                            ) {
                                viewModel.selectedDate = day
                            }
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(weekDays, id: \.self) { day in
                        DayCell(
                            date: day,
                            isSelected: day.isInSameDay(as: viewModel.selectedDate),
                            isToday: day.isInSameDay(as: .now),
                            hasEvents: weekDatesWithEvents.contains(where: { $0.isInSameDay(as: day) })
                        ) {
                            viewModel.selectedDate = day
                            viewModel.selectedMonth = day
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

// MARK: - Cellule jour

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 32, height: 32)

                    Text(dayNumber)
                        .font(.callout.weight(isToday || isSelected ? .semibold : .regular))
                        .foregroundStyle(labelColor)
                }

                // Point indicateur d'événements
                Circle()
                    .fill(dotColor)
                    .frame(width: 4, height: 4)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    private var circleColor: Color {
        if isSelected { return .accentColor }
        if isToday { return .red }
        return .clear
    }

    private var labelColor: Color {
        if isSelected || isToday { return .white }
        return .primary
    }

    private var dotColor: Color {
        guard hasEvents else { return .clear }
        if isSelected { return .white.opacity(0.8) }
        return .accentColor
    }
}
