import Foundation

struct Substance: Codable, Identifiable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case medication
        case vitamin
        case supplement

        var id: String { rawValue }

        var displayName: String {
            rawValue.capitalized
        }
    }

    var id: UUID
    var name: String
    var category: Category
    var dosage: Double
    var unit: String
    var frequency: String

    init(
        id: UUID = UUID(),
        name: String,
        category: Category,
        dosage: Double,
        unit: String,
        frequency: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.dosage = dosage
        self.unit = unit
        self.frequency = frequency
    }
}

struct BuiltInSubstance: Codable, Identifiable, Hashable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case psychedelic = "psychedelic"
        case stimulant = "stimulant"
        case depressant = "depressant"
        case entactogen = "entactogen"
        case cannabinoid = "cannabinoid"
        case opioid = "opioid"
        case benzodiazepine = "benzodiazepine"
        case medication = "medication"
        case vitamin = "vitamin"
        case supplement = "supplement"
        case mineral = "mineral"
        case herb = "herb"
        case nootropic = "nootropic"
        case dissociative = "dissociative"
        case opioidAdjacent = "opioid-adjacent"

        var id: String { rawValue }
    }

    var id: String
    var name: String
    var category: Category
    var icon: String
    var halfLife: String
    var effects: [String]
    var interactions: [String]
    var harmReduction: [String]
    var routes: [String]
    var unit: String
    var notes: String
}
