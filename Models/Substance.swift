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
