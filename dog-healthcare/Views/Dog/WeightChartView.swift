import SwiftUI
import Charts

struct WeightChartView: View {
    let entries: [WeightEntry]

    private var sorted: [WeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    private var yDomain: ClosedRange<Double> {
        let values = sorted.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else { return 0...10 }
        let padding = (maxVal - minVal) * 0.2 + 0.5
        let lower = minVal - padding < 0 ? 0.0 : minVal - padding
        return lower...(maxVal + padding)
    }

    var body: some View {
        if sorted.isEmpty {
            ContentUnavailableView(
                "Aucune donnée",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Ajoutez le premier poids pour voir l'évolution.")
            )
            .frame(height: 160)
        } else {
            Chart(sorted) { entry in
                AreaMark(
                    x: .value("Date", entry.date),
                    yStart: .value("Base", yDomain.lowerBound),
                    yEnd: .value("Poids", entry.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Poids", entry.value)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Poids", entry.value)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(40)
            }
            .chartYScale(domain: yDomain)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(v, specifier: "%.1f") kg")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 180)
        }
    }
}
