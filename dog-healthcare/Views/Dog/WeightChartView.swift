import SwiftUI
import Charts

struct WeightChartView: View {
    let entries: [WeightEntry]

    @State private var selectedEntry: WeightEntry?

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
            VStack(alignment: .leading, spacing: 4) {
                // Indicateur au-dessus du graphique
                Group {
                    if let entry = selectedEntry {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.2f kg", entry.value))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            Text(entry.date.fullDateWithYearFR)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 44, alignment: .leading)
                .animation(.easeInOut(duration: 0.15), value: selectedEntry?.id)

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
                    .symbolSize(selectedEntry?.id == entry.id ? 80 : 40)

                    if let selected = selectedEntry, selected.id == entry.id {
                        RuleMark(x: .value("Date", selected.date))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    }
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
                .chartXAxis(.hidden)
                .frame(height: 180)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else { return }
                                    let plotOrigin = geo[plotFrame].origin
                                        let xInPlot = value.location.x - plotOrigin.x
                                        if let date: Date = proxy.value(atX: xInPlot) {
                                            selectedEntry = sorted.min(by: {
                                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                            })
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            selectedEntry = nil
                                        }
                                    }
                            )
                    }
                }
            }
        }
    }
}
