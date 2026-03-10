import Foundation
import Observation

@MainActor @Observable
final class DataStore {
    static let appGroupId = "group.com.heyitsmejosh.dose"

    var substances: [Substance] = [] {
        didSet { saveSubstances() }
    }

    var doseEntries: [DoseEntry] = [] {
        didSet {
            saveDoseEntries()
            syncWidgetData()
        }
    }

    var healthEntries: [HealthEntry] = [] {
        didSet { saveHealthEntries() }
    }

    var biometricEntries: [BiometricEntry] = [] {
        didSet { saveBiometricEntries() }
    }

    var lastError: String?

    private let defaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: appGroupId)
    private let substancesKey = "dose.substances"
    private let doseEntriesKey = "dose.doseEntries"
    private let healthEntriesKey = "dose.healthEntries"
    private let biometricEntriesKey = "dose.biometricEntries"
    private let calendar = Calendar.current

    var streakCount: Int {
        let entryDays = Set(doseEntries.map { calendar.startOfDay(for: $0.timestamp) })
        guard !entryDays.isEmpty else { return 0 }

        var streak = 0
        var currentDay = calendar.startOfDay(for: Date())

        while entryDays.contains(currentDay) {
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }
            currentDay = previousDay
        }

        return streak
    }

    init() {
        loadAll()
        seedIfNeeded()
    }

    func addSubstance(_ substance: Substance) {
        substances.append(substance)
    }

    func deleteSubstance(_ substance: Substance) {
        substances.removeAll { $0.id == substance.id }
        doseEntries.removeAll { $0.substanceId == substance.id }
    }

    func addDoseEntry(_ entry: DoseEntry) {
        doseEntries.append(entry)
    }

    func deleteDoseEntry(_ entry: DoseEntry) {
        doseEntries.removeAll { $0.id == entry.id }
    }

    func addHealthEntry(_ entry: HealthEntry) {
        healthEntries.append(entry)
    }

    func deleteHealthEntry(_ entry: HealthEntry) {
        healthEntries.removeAll { $0.id == entry.id }
    }

    func addBiometricEntry(_ entry: BiometricEntry) {
        biometricEntries.append(entry)
    }

    func deleteBiometricEntry(_ entry: BiometricEntry) {
        biometricEntries.removeAll { $0.id == entry.id }
    }

    func getActive() -> [DoseEntry] {
        let now = Date()
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        return doseEntries.filter { $0.timestamp >= cutoff && $0.timestamp <= now }
    }

    func substanceName(for entry: DoseEntry) -> String {
        if let bid = entry.builtInSubstanceId, let builtIn = SubstanceDatabase.find(id: bid) {
            return builtIn.name
        }
        if let substance = substances.first(where: { $0.id == entry.substanceId }) {
            return substance.name
        }
        if let builtIn = SubstanceDatabase.find(id: entry.substanceId.uuidString.lowercased()) {
            return builtIn.name
        }
        return "Unknown"
    }

    func substance(for id: UUID) -> Substance? {
        substances.first { $0.id == id }
    }

    func exportData() -> Data? {
        let export = ExportBundle(
            substances: substances,
            doseEntries: doseEntries,
            healthEntries: healthEntries,
            biometricEntries: biometricEntries
        )
        do {
            return try JSONEncoder().encode(export)
        } catch {
            lastError = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }

    func importData(_ data: Data) -> Bool {
        do {
            let bundle = try JSONDecoder().decode(ExportBundle.self, from: data)
            substances = bundle.substances
            doseEntries = bundle.doseEntries
            healthEntries = bundle.healthEntries
            biometricEntries = bundle.biometricEntries
            return true
        } catch {
            lastError = "Import failed: \(error.localizedDescription)"
            return false
        }
    }

    private func loadAll() {
        substances = load([Substance].self, forKey: substancesKey) ?? []
        doseEntries = load([DoseEntry].self, forKey: doseEntriesKey) ?? []
        healthEntries = load([HealthEntry].self, forKey: healthEntriesKey) ?? []
        biometricEntries = load([BiometricEntry].self, forKey: biometricEntriesKey) ?? []
    }

    private func seedIfNeeded() {
        guard substances.isEmpty else { return }

        substances = [
            Substance(name: "Vitamin D", category: .vitamin, dosage: 1000, unit: "IU", frequency: "Daily"),
            Substance(name: "Omega-3", category: .supplement, dosage: 1, unit: "capsule", frequency: "Daily")
        ]
    }

    private func saveSubstances() {
        save(substances, forKey: substancesKey)
    }

    private func saveDoseEntries() {
        save(doseEntries, forKey: doseEntriesKey)
    }

    private func saveHealthEntries() {
        save(healthEntries, forKey: healthEntriesKey)
    }

    private func saveBiometricEntries() {
        save(biometricEntries, forKey: biometricEntriesKey)
    }

    private func save<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            lastError = "Save failed for \(key): \(error.localizedDescription)"
        }
    }

    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            lastError = "Load failed for \(key): \(error.localizedDescription)"
            return nil
        }
    }

    private func syncWidgetData() {
        let active = getActive()
        sharedDefaults?.set(active.count, forKey: "widget.doseCount")

        if let latest = active.sorted(by: { $0.timestamp > $1.timestamp }).first {
            sharedDefaults?.set(substanceName(for: latest), forKey: "widget.lastDoseName")
        } else {
            sharedDefaults?.set("No recent dose", forKey: "widget.lastDoseName")
        }

        let grouped = Dictionary(grouping: active) { substanceName(for: $0) }
        let pills = grouped.map { WidgetPill(name: $0.key, count: $0.value.count) }
        if let data = try? JSONEncoder().encode(pills) {
            sharedDefaults?.set(data, forKey: "widget.activePills")
        }
    }
}

private struct WidgetPill: Codable {
    let name: String
    let count: Int
}

private struct ExportBundle: Codable {
    let substances: [Substance]
    let doseEntries: [DoseEntry]
    let healthEntries: [HealthEntry]
    let biometricEntries: [BiometricEntry]
}
