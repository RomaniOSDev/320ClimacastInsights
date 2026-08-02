import SwiftUI

struct CoverageDistributionChart: View {
    let entries: [CloudLogEntry]

    private struct Bucket: Identifiable {
        let id: String
        let label: String
        let range: ClosedRange<Double>
        var count: Int = 0
    }

    private var buckets: [Bucket] {
        var items: [Bucket] = [
            Bucket(id: "clear", label: "0-20", range: 0...20),
            Bucket(id: "light", label: "21-40", range: 21...40),
            Bucket(id: "mid", label: "41-60", range: 41...60),
            Bucket(id: "heavy", label: "61-80", range: 61...80),
            Bucket(id: "full", label: "81-100", range: 81...100)
        ]
        for entry in entries {
            if let index = items.firstIndex(where: { $0.range.contains(entry.coverage) }) {
                items[index].count += 1
            }
        }
        return items
    }

    var body: some View {
        let maxCount = max(buckets.map(\.count).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(buckets) { bucket in
                VStack(spacing: 6) {
                    Text("\(bucket.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppAccent"))
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color("AppPrimary").opacity(bucket.count == 0 ? 0.18 : 0.85))
                        .frame(height: max(8, CGFloat(bucket.count) / CGFloat(maxCount) * 120))
                        .overlay {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.5), lineWidth: 1)
                        }
                    Text(bucket.label)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160, alignment: .bottom)
    }
}

struct WeeklyActivityChart: View {
    let entries: [CloudLogEntry]

    private struct DayBar: Identifiable {
        let id: String
        let label: String
        let count: Int
    }

    private var days: [DayBar] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().compactMap { offset -> DayBar? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = entries.filter { $0.date >= day && $0.date < next }.count
            return DayBar(
                id: AppDataStore.dayKey(for: day),
                label: formatter.string(from: day).uppercased(),
                count: count
            )
        }
    }

    var body: some View {
        let maxCount = max(days.map(\.count).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    Text("\(day.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppAccent"))
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color("AppAccent").opacity(day.count == 0 ? 0.15 : 0.8))
                        .frame(height: max(8, CGFloat(day.count) / CGFloat(maxCount) * 110))
                        .overlay {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color("AppAccent").opacity(0.45), lineWidth: 1)
                        }
                    Text(day.label)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150, alignment: .bottom)
    }
}
