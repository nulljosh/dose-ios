import Foundation

struct DoseEntry: Codable, Identifiable {
    var id: UUID
    var substanceId: UUID
    var builtInSubstanceId: String?
    var timestamp: Date
    var notes: String
    var dose: Double?
    var unit: String?
    var route: String?
    var rating: Int?

    init(
        id: UUID = UUID(),
        substanceId: UUID = UUID(),
        builtInSubstanceId: String? = nil,
        timestamp: Date = Date(),
        notes: String = "",
        dose: Double? = nil,
        unit: String? = nil,
        route: String? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.substanceId = substanceId
        self.builtInSubstanceId = builtInSubstanceId
        self.timestamp = timestamp
        self.notes = notes
        self.dose = dose
        self.unit = unit
        self.route = route
        self.rating = rating
    }
}
