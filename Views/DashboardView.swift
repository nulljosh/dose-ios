import SwiftUI

struct DashboardView: View {
    @Bindable var dataStore: DataStore
    @Bindable var notificationService: NotificationService
    @State private var showAddDose = false
    @State private var showReminders = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if (5...11).contains(hour) {
            return "Good morning"
        }
        if (12...16).contains(hour) {
            return "Good afternoon"
        }
        return "Good evening"
    }

    private var activePills: [ActivePill] {
        let grouped = Dictionary(grouping: dataStore.getActive()) { dataStore.substanceName(for: $0) }

        return grouped.compactMap { name, entries in
            let first = entries.first
            let builtIn = first.flatMap { SubstanceDatabase.find(id: $0.substanceId.uuidString.lowercased()) }
            let color = builtIn?.category.categoryColor ?? Color.secondary
            let latest = entries.map(\.timestamp).max() ?? .distantPast
            return ActivePill(name: name, color: color, count: entries.count, latestTimestamp: latest)
        }
        .sorted { $0.latestTimestamp > $1.latestTimestamp }
    }

    private var recentEntries: [DoseEntry] {
        dataStore.doseEntries
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Active stack")
                                .font(.headline)

                            Spacer()

                            Button("Quick log") {
                                showAddDose = true
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if activePills.isEmpty {
                            Text("No active substances in the last 24 hours.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(activePills) { pill in
                                        Text(pill.count > 1 ? "\(pill.name) x\(pill.count)" : pill.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(pill.color)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent entries")
                            .font(.headline)

                        if recentEntries.isEmpty {
                            Text("No doses logged yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(recentEntries) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dataStore.substanceName(for: entry))
                                        .font(.body.weight(.semibold))

                                    if let dose = entry.dose {
                                        let unit = (entry.unit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        Text(unit.isEmpty ? "\(dose.formatted())" : "\(dose.formatted()) \(unit)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(entry.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReminders = true
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
            .sheet(isPresented: $showAddDose) {
                AddDoseSheet(dataStore: dataStore)
            }
            .sheet(isPresented: $showReminders) {
                RemindersView(notificationService: notificationService)
            }
        }
    }
}

private struct ActivePill: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let count: Int
    let latestTimestamp: Date
}
