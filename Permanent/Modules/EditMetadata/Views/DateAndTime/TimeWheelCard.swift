//
//  TimeWheelCard.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The floating card behind the clock icon: three native wheels for the hour, minute and second. Every turn writes
/// the three values into the time fields; the hour wheel follows the pill, 1 to 12 or 0 to 23.
struct TimeWheelCard: View {
    @Binding var entry: DateTimeEntry
    @State private var hour: Int
    @State private var minute: Int
    @State private var second: Int

    static let width: CGFloat = 192
    static let height: CGFloat = 172

    init(entry: Binding<DateTimeEntry>) {
        _entry = entry
        let value = entry.wrappedValue
        _hour = State(initialValue: Int(value.hour) ?? (value.format == .h24 ? 0 : 12))
        _minute = State(initialValue: Int(value.minute) ?? 0)
        _second = State(initialValue: Int(value.second) ?? 0)
    }

    private var hours: [Int] {
        entry.format == .h24 ? Array(0...23) : Array(1...12)
    }

    var body: some View {
        HStack(spacing: 0) {
            wheel($hour, values: hours, label: DateTimeEntry.Field.hour.label, padded: entry.format == .h24)
            wheel($minute, values: Array(0...59), label: DateTimeEntry.Field.minute.label, padded: true)
            wheel($second, values: Array(0...59), label: DateTimeEntry.Field.second.label, padded: true)
        }
        .frame(width: Self.width, height: Self.height)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.darkBlue.opacity(0.16), radius: 16, y: 4)
        )
        .onChange(of: hour) { _ in write() }
        .onChange(of: minute) { _ in write() }
        .onChange(of: second) { _ in write() }
    }

    private func wheel(_ selection: Binding<Int>, values: [Int], label: String, padded: Bool) -> some View {
        Picker(label, selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(padded ? String(format: "%02d", value) : String(value))
                    .font(DateTimeDigitsField.font)
                    .foregroundColor(.darkBlue)
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: Self.width / 3)
        .clipped()
        .accessibilityLabel(label)
    }

    private func write() {
        entry.set(hour: hour, minute: minute, second: second)
    }
}
