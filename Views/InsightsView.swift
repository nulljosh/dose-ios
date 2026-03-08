import SwiftUI

struct InsightsView: View {
    @Bindable var dataStore: DataStore

    private var last30DaysEntries: [DoseEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return dataStore.doseEntries.filter { $0.timestamp >= cutoff }
    }

    private var totalDoses: Int { last30DaysEntries.count }

    private var uniqueSubstances: Int {
        Set(last30DaysEntries.map(\.substanceId)).count
    }

    private var avgPerDay: Double {
        guard totalDoses > 0 else { return 0 }
        return Double(totalDoses) / 30.0
    }

    private var mostActiveDay: String {
        guard !last30DaysEntries.isEmpty else { return "--" }
        let calendar = Calendar.current
        let dayCounts = Dictionary(grouping: last30DaysEntries) { entry in
            calendar.component(.weekday, from: entry.timestamp)
        }.mapValues(\.count)
        let top = dayCounts.max(by: { $0.value < $1.value })?.key ?? 1
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[top - 1]
    }

    private var top5Substances: [(name: String, count: Int, color: Color)] {
        let counts = Dictionary(grouping: last30DaysEntries, by: \.substanceId)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
            .prefix(5)

        return counts.map { id, count in
            let builtIn = SubstanceDatabase.find(id: id.uuidString.lowercased())
            let name = builtIn?.name ?? dataStore.substance(for: id)?.name ?? "Unknown"
            let color = builtIn?.category.categoryColor ?? .secondary
            return (name: name, count: count, color: color)
        }
    }

    private var heatmapData: [[Int]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var grid = Array(repeating: Array(repeating: 0, count: 4), count: 7)
        for entry in last30DaysEntries {
            let entryDay = calendar.startOfDay(for: entry.timestamp)
            let daysAgo = calendar.dateComponents([.day], from: entryDay, to: today).day ?? 0
            guard daysAgo >= 0, daysAgo < 28 else { continue }
            let weekIndex = daysAgo / 7
            let weekday = (calendar.component(.weekday, from: entry.timestamp) + 5) % 7
            guard weekIndex < 4, weekday < 7 else { continue }
            grid[weekday][3 - weekIndex] += 1
        }
        return grid
    }

    private var toleranceItems: [ToleranceItem] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentEntries = dataStore.doseEntries.filter { $0.timestamp >= cutoff }
        let grouped = Dictionary(grouping: recentEntries, by: \.substanceId)

        return grouped.compactMap { id, entries in
            guard entries.count >= 3 else { return nil }
            let builtIn = SubstanceDatabase.find(id: id.uuidString.lowercased())
            let name = builtIn?.name ?? dataStore.substance(for: id)?.name ?? "Unknown"
            let category = builtIn?.category
            let washout = washoutDays(for: category)
            let lastUse = entries.map(\.timestamp).max() ?? Date()
            let daysSince = calendar.dateComponents([.day], from: lastUse, to: Date()).day ?? 0
            let progress = min(Double(daysSince) / Double(washout), 1.0)
            let color = builtIn?.category.categoryColor ?? .secondary
            return ToleranceItem(name: name, daysSince: daysSince, washoutDays: washout, progress: progress, color: color)
        }
        .sorted { $0.name < $1.name }
    }

    private func washoutDays(for category: BuiltInSubstance.Category?) -> Int {
        switch category {
        case .psychedelic: return 14
        case .stimulant: return 7
        case .entactogen: return 90
        case .benzodiazepine: return 14
        case .dissociative: return 14
        default: return 7
        }
    }

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    statsGrid
                    top5Section
                    heatmapSection
                    toleranceSection
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCard(value: "\(totalDoses)", label: "Total doses")
            statCard(value: "\(uniqueSubstances)", label: "Unique substances")
            statCard(value: String(format: "%.1f", avgPerDay), label: "Avg per day")
            statCard(value: mostActiveDay, label: "Most active day")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.quaternary))
    }

    private var top5Section: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top substances")
                .font(.headline)

            if top5Substances.isEmpty {
                Text("No data yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let maxCount = top5Substances.map(\.count).max() ?? 1
                ForEach(Array(top5Substances.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.subheadline)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                        }
                        .frame(height: 20)
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("28-day heatmap")
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { row in
                    HStack(spacing: 4) {
                        Text(dayLabels[row])
                            .font(.caption2)
                            .frame(width: 30, alignment: .trailing)
                        ForEach(0..<4, id: \.self) { col in
                            let count = heatmapData[row][col]
                            RoundedRectangle(cornerRadius: 4)
                                .fill(heatmapColor(count: count))
                                .frame(width: 40, height: 20)
                        }
                    }
                }
            }
        }
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0: return Color(.quaternarySystemFill)
        case 1...2: return .green.opacity(0.3)
        case 3...4: return .green.opacity(0.6)
        default: return .green
        }
    }

    private var toleranceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tolerance tracker")
                .font(.headline)

            if toleranceItems.isEmpty {
                Text("Use a substance 3+ times to track tolerance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(toleranceItems) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(item.daysSince)d / \(item.washoutDays)d")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.quaternarySystemFill))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.toleranceColor)
                                    .frame(width: geo.size.width * item.progress)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
    }
}

private struct ToleranceItem: Identifiable {
    let id = UUID()
    let name: String
    let daysSince: Int
    let washoutDays: Int
    let progress: Double
    let color: Color

    var toleranceColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return .orange }
        return .red
    }
}
