import SwiftUI

struct HistoryView: View {
    @Bindable var dataStore: DataStore

    private var groupedEntries: [(date: Date, entries: [DoseEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: dataStore.doseEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        return groups
            .map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if groupedEntries.isEmpty {
                    Text("No history yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(groupedEntries, id: \.date) { group in
                        Section(group.date.formatted(date: .abbreviated, time: .omitted)) {
                            ForEach(group.entries) { entry in
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
                }
            }
            .navigationTitle("History")
        }
    }
}
