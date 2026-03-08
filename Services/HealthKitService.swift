import Foundation
import HealthKit
import Observation

@Observable
@MainActor
final class HealthKitService {
    var heartRate: Double?
    var restingHeartRate: Double?
    var hrv: Double?
    var respiratoryRate: Double?
    var bloodOxygen: Double?
    var steps: Int?
    var activeEnergy: Double?
    var bodyMass: Double?
    var sleepHours: Double?
    var walkingDistance: Double?
    var systolicBP: Int?
    var diastolicBP: Int?
    var isAuthorized = false
    var lastError: String?

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
            .respiratoryRate, .oxygenSaturation,
            .stepCount, .activeEnergyBurned, .bodyMass, .distanceWalkingRunning,
            .bloodPressureSystolic, .bloodPressureDiastolic
        ]
        var types = Set<HKObjectType>(quantityTypes.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    func requestAuthorization() async {
        guard Self.isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchAll()
        } catch {
            isAuthorized = false
            lastError = "HealthKit authorization failed: \(error.localizedDescription)"
        }
    }

    func fetchAll() async {
        async let hr = fetchLatestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let rhr = fetchLatestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrvVal = fetchLatestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let rr = fetchLatestQuantity(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let spo2 = fetchLatestQuantity(.oxygenSaturation, unit: .percent())
        async let mass = fetchLatestQuantity(.bodyMass, unit: .pound())
        async let sysBP = fetchLatestQuantity(.bloodPressureSystolic, unit: .millimeterOfMercury())
        async let diaBP = fetchLatestQuantity(.bloodPressureDiastolic, unit: .millimeterOfMercury())
        async let stepsVal = fetchCumulativeSum(.stepCount, unit: .count())
        async let energy = fetchCumulativeSum(.activeEnergyBurned, unit: .kilocalorie())
        async let distance = fetchCumulativeSum(.distanceWalkingRunning, unit: .mile())
        async let sleep = fetchSleepHours()

        heartRate = await hr
        restingHeartRate = await rhr
        hrv = await hrvVal
        respiratoryRate = await rr
        bloodOxygen = await spo2.map { $0 * 100 }
        bodyMass = await mass
        systolicBP = await sysBP.map { Int($0) }
        diastolicBP = await diaBP.map { Int($0) }
        steps = await stepsVal.map { Int($0) }
        activeEnergy = await energy
        walkingDistance = await distance
        sleepHours = await sleep
    }

    // MARK: - Private

    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchCumulativeSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchSleepHours() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let now = Date()
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let lastNight = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: yesterday) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: lastNight, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleepSeconds = samples
                    .filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let hours = asleepSeconds / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            store.execute(query)
        }
    }
}
