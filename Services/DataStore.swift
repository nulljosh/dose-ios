import Foundation
import Observation

@Observable
final class DataStore {
    var substances: [Substance] = [] {
        didSet { saveSubstances() }
    }

    var doseEntries: [DoseEntry] = [] {
        didSet { saveDoseEntries() }
    }

    var healthEntries: [HealthEntry] = [] {
        didSet { saveHealthEntries() }
    }

    var biometricEntries: [BiometricEntry] = [] {
        didSet { saveBiometricEntries() }
    }

    private let defaults = UserDefaults.standard
    private let substancesKey = "dose.substances"
    private let doseEntriesKey = "dose.doseEntries"
    private let healthEntriesKey = "dose.healthEntries"
    private let biometricEntriesKey = "dose.biometricEntries"

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
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
