import SwiftUI

struct DashboardView: View {
    @Bindable var dataStore: DataStore

    private var todaysEntries: [DoseEntry] {
        let calendar = Calendar.current
        return dataStore.doseEntries
            .filter { calendar.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var streakCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(dataStore.doseEntries.map { calendar.startOfDay(for: $0.timestamp) })
        var streak = 0
        var day = calendar.startOfDay(for: Date())

        while uniqueDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    if todaysEntries.isEmpty {
                        Text("No doses logged yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todaysEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dataStore.substance(for: entry.substanceId)?.name ?? "Unknown")
                                    .font(.headline)
                                if !entry.notes.isEmpty {
                                    Text(entry.notes)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section("Stats") {
                    HStack {
                        Text("Current streak")
                        Spacer()
                        Text("\(streakCount) day\(streakCount == 1 ? "" : "s")")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}
