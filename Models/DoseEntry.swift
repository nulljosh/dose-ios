import Foundation

struct DoseEntry: Codable, Identifiable {
    var id: UUID
    var substanceId: UUID
    var timestamp: Date
    var notes: String

    init(
        id: UUID = UUID(),
        substanceId: UUID,
        timestamp: Date = Date(),
        notes: String
    ) {
        self.id = id
        self.substanceId = substanceId
        self.timestamp = timestamp
        self.notes = notes
    }
}
