import SwiftUI

struct HistoryView: View {
    @Bindable var dataStore: DataStore
    @State private var searchText = ""

    private var filteredEntries: [DoseEntry] {
        if searchText.isEmpty {
            return dataStore.doseEntries
        }
        return dataStore.doseEntries.filter { entry in
            let name = dataStore.substanceName(for: entry)
            return name.localizedCaseInsensitiveContains(searchText) ||
                   entry.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedEntries: [(date: Date, entries: [DoseEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredEntries) { entry in
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
                    Text(searchText.isEmpty ? "No history yet." : "No results.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(groupedEntries, id: \.date) { group in
                        Section(group.date.formatted(date: .abbreviated, time: .omitted)) {
                            ForEach(group.entries) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dataStore.substanceName(for: entry))
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
                            .onDelete { offsets in
                                let toDelete = offsets.map { group.entries[$0] }
                                for entry in toDelete {
                                    dataStore.deleteDoseEntry(entry)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search doses...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !dataStore.doseEntries.isEmpty {
                        ShareLink(
                            item: csvExportURL,
                            preview: SharePreview("Dose Export", image: Image(systemName: "doc.text"))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    private var csvExportURL: URL {
        switch CSVExporter.export(entries: dataStore.doseEntries, dataStore: dataStore) {
        case .success(let url):
            return url
        case .failure:
            return FileManager.default.temporaryDirectory.appendingPathComponent("dose-export.csv")
        }
    }
}
