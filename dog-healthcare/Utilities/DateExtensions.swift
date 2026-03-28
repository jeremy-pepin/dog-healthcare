import Foundation

extension Date {
    func ageString() -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: self, to: .now)
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years > 0 {
            if months > 0 {
                return "\(years) an\(years > 1 ? "s" : "") et \(months) mois"
            }
            return "\(years) an\(years > 1 ? "s" : "")"
        }
        if months > 0 { return "\(months) mois" }
        let days = Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0
        return "\(days) jour\(days > 1 ? "s" : "")"
    }

    func isInSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func startOfMonth() -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    func endOfMonth() -> Date {
        guard let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)),
              let end = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: start)
        else { return self }
        return end
    }

    func daysInMonth() -> [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: self),
              let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))
        else { return [] }
        return range.compactMap { Calendar.current.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private static let french = Locale(identifier: "fr_FR")

    var monthYearString: String {
        formatted(.dateTime.month(.wide).year().locale(Self.french))
    }

    var shortDayString: String {
        formatted(.dateTime.day().month(.abbreviated).locale(Self.french))
    }

    var timeString: String {
        formatted(.dateTime.hour().minute().locale(Self.french))
    }

    var abbreviatedDateFR: String {
        formatted(.dateTime.day().month(.abbreviated).locale(Self.french))
    }

    var abbreviatedDateTimeFR: String {
        formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Self.french))
    }

    var longDateFR: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Self.french))
    }
}

extension Calendar {
    static var mondayFirst: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }
}
