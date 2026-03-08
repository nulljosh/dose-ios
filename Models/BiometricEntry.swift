import Foundation

struct BiometricEntry: Codable, Identifiable {
    var id: UUID
    var date: Date
    var weight: Double?
    var bpSystolic: Int?
    var bpDiastolic: Int?
    var heartRate: Int?
    var sleepHours: Double?
    var steps: Int?
    var notes: String
    var respiratoryRate: Double?
    var bloodOxygen: Double?
    var hrv: Double?
    var activeEnergy: Double?
    var distance: Double?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weight: Double? = nil,
        bpSystolic: Int? = nil,
        bpDiastolic: Int? = nil,
        heartRate: Int? = nil,
        sleepHours: Double? = nil,
        steps: Int? = nil,
        notes: String = "",
        respiratoryRate: Double? = nil,
        bloodOxygen: Double? = nil,
        hrv: Double? = nil,
        activeEnergy: Double? = nil,
        distance: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bpSystolic = bpSystolic
        self.bpDiastolic = bpDiastolic
        self.heartRate = heartRate
        self.sleepHours = sleepHours
        self.steps = steps
        self.notes = notes
        self.respiratoryRate = respiratoryRate
        self.bloodOxygen = bloodOxygen
        self.hrv = hrv
        self.activeEnergy = activeEnergy
        self.distance = distance
    }
}
