import Foundation

struct HealthEntry: Codable, Identifiable {
    var id: UUID
    var date: Date
    var mood: Int
    var energy: Int
    var sleepHours: Double
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Int,
        energy: Int,
        sleepHours: Double,
        notes: String
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energy = energy
        self.sleepHours = sleepHours
        self.notes = notes
    }
}
