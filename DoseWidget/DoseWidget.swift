import SwiftUI
import WidgetKit

struct ActivePill: Codable, Identifiable {
    let name: String
    let count: Int

    var id: String { name }
}

struct DoseWidgetEntry: TimelineEntry {
    let date: Date
    let doseCount: Int
    let lastDoseName: String
    let activePills: [ActivePill]
}

struct DoseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoseWidgetEntry {
        DoseWidgetEntry(
            date: Date(),
            doseCount: 0,
            lastDoseName: "No recent dose",
            activePills: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DoseWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoseWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> DoseWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.heyitsmejosh.dose")

        let doseCount = defaults?.integer(forKey: "widget.doseCount") ?? 0
        let lastDoseName = defaults?.string(forKey: "widget.lastDoseName") ?? "No recent dose"

        var activePills: [ActivePill] = []
        if let data = defaults?.data(forKey: "widget.activePills"),
           let decoded = try? JSONDecoder().decode([ActivePill].self, from: data) {
            activePills = decoded
        }

        return DoseWidgetEntry(
            date: Date(),
            doseCount: doseCount,
            lastDoseName: lastDoseName,
            activePills: activePills
        )
    }
}

struct DoseWidgetView: View {
    var entry: DoseWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Doses Today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(entry.doseCount)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(entry.lastDoseName)
                .font(.footnote)
                .lineLimit(2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(entry.doseCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Last: \(entry.lastDoseName)")
                    .font(.footnote)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Active Pills")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if entry.activePills.isEmpty {
                    Text("None")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.activePills.prefix(5)) { pill in
                        HStack {
                            Text(pill.name)
                                .font(.footnote)
                                .lineLimit(1)
                            Spacer()
                            Text("\(pill.count)")
                                .font(.footnote.weight(.semibold))
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct DoseWidget: Widget {
    let kind: String = "DoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoseWidgetProvider()) { entry in
            DoseWidgetView(entry: entry)
        }
        .configurationDisplayName("Dose Summary")
        .description("See your dose count, last dose, and active pills.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
