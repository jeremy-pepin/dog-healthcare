import SwiftUI
import UIKit

// MARK: - DatePicker avec intervalle de minutes configurable

struct DatePickerWithInterval: UIViewRepresentable {
    @Binding var selection: Date
    var minuteInterval: Int = 5

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.minuteInterval = minuteInterval
        picker.locale = Locale(identifier: "fr_FR")
picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        if picker.date != selection {
            picker.date = selection
        }
        picker.minuteInterval = minuteInterval
    }

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    class Coordinator: NSObject {
        var selection: Binding<Date>
        init(selection: Binding<Date>) { self.selection = selection }

        @objc func dateChanged(_ picker: UIDatePicker) {
            selection.wrappedValue = picker.date
        }
    }
}

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 20
    var solidBackground: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background {
                if let solid = solidBackground {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(solid)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.08))
                        }
                }
            }
    }
}
