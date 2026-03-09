import Foundation
import SwiftUI

enum HealthRank: String, CaseIterable {
    case excellent
    case healthy
    case watch
    case atRisk

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .healthy: return "Healthy"
        case .watch: return "Watch"
        case .atRisk: return "At Risk"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .healthy: return .blue
        case .watch: return .orange
        case .atRisk: return .red
        }
    }
}

struct ScoreBreakdown {
    let total: Int
    let confidence: Int
    let parts: [String: Int?]
}

struct SupplementAdherenceItem: Identifiable {
    let id = UUID()
    let name: String
    let taken: Int
    let total: Int
    let rate: Int
}

struct HealthScoreResult {
    let breakdown: ScoreBreakdown
    let rank: HealthRank
    let anomalies: [String]
    let adherence: [SupplementAdherenceItem]
}

extension HealthScoreResult {
    static let empty = HealthScoreResult(
        breakdown: ScoreBreakdown(total: 0, confidence: 0, parts: [:]),
        rank: .watch,
        anomalies: [],
        adherence: []
    )
}

struct HealthScoringService {

    // MARK: - Metric configs (reweighted to 100 for 5 available metrics)

    private struct MetricConfig {
        let weight: Int
        var optimal: (Double, Double)? = nil
        var acceptable: (Double, Double)? = nil
        var thresholds: (Double, Double, Double)? = nil
        var scale: Double? = nil
        var inverse: Bool = false
    }

    private static let metrics: [String: MetricConfig] = [
        "sleepHours": MetricConfig(weight: 30, optimal: (7, 9), acceptable: (6, 10)),
        "steps": MetricConfig(weight: 22, thresholds: (10000, 7000, 4000)),
        "heartRate": MetricConfig(weight: 22, optimal: (55, 80), acceptable: (50, 90)),
        "bloodPressureSys": MetricConfig(weight: 13, optimal: (90, 120), acceptable: (85, 140)),
        "moodScore": MetricConfig(weight: 13, scale: 10),
    ]

    // MARK: - Score a single metric

    static func scoreMetric(key: String, value: Double) -> Int? {
        guard let config = metrics[key], value.isFinite else { return nil }

        let maxPts = config.weight

        if let (optLow, optHigh) = config.optimal {
            if value >= optLow && value <= optHigh { return maxPts }
            if let (accLow, accHigh) = config.acceptable {
                if value >= accLow && value <= accHigh { return Int(round(Double(maxPts) * 0.65)) }
            }
            return Int(round(Double(maxPts) * 0.3))
        }

        if let scale = config.scale {
            let ratio: Double
            if config.inverse {
                ratio = (scale - value + 1) / scale
            } else {
                ratio = value / scale
            }
            return Int(round(Double(maxPts) * max(0, min(1, ratio))))
        }

        if let (high, mid, low) = config.thresholds {
            if config.inverse {
                if value <= high { return maxPts }
                if value <= mid { return Int(round(Double(maxPts) * 0.65)) }
                if value <= low { return Int(round(Double(maxPts) * 0.3)) }
                return 0
            }
            if value >= high { return maxPts }
            if value >= mid { return Int(round(Double(maxPts) * 0.7)) }
            if value >= low { return Int(round(Double(maxPts) * 0.35)) }
            return Int(round(Double(maxPts) * 0.15))
        }

        return nil
    }

    // MARK: - Score breakdown

    static func scoreBreakdown(metrics input: [String: Double]) -> ScoreBreakdown {
        var parts: [String: Int?] = [:]
        var earned = 0
        var possible = 0
        var filled = 0
        let totalFields = metrics.count

        for (key, config) in metrics {
            if let value = input[key] {
                let score = scoreMetric(key: key, value: value)
                parts[key] = score
                if let score {
                    earned += score
                    possible += config.weight
                    filled += 1
                }
            } else {
                parts[key] = nil
            }
        }

        let total = possible > 0 ? Int(round(Double(earned) / Double(possible) * 100)) : 0
        let confidence = Int(round(Double(filled) / Double(totalFields) * 100))

        return ScoreBreakdown(total: total, confidence: confidence, parts: parts)
    }

    // MARK: - Rank

    static func healthRank(score: Int) -> HealthRank {
        if score >= 86 { return .excellent }
        if score >= 72 { return .healthy }
        if score >= 58 { return .watch }
        return .atRisk
    }

    // MARK: - Anomaly detection

    static func metricAnomalies(last7Avg: [String: Double], latest: [String: Double]) -> [String] {
        var flags: [String] = []

        if let avgSleep = last7Avg["sleepHours"], let curSleep = latest["sleepHours"],
           curSleep < avgSleep - 1.5 {
            flags.append("Sleep dipped sharply vs weekly baseline")
        }

        if let avgSteps = last7Avg["steps"], let curSteps = latest["steps"],
           curSteps < avgSteps * 0.6 {
            flags.append("Step count dropped materially today")
        }

        if let hr = latest["heartRate"], hr > 95 {
            flags.append("Heart rate is elevated")
        }

        if let mood7 = last7Avg["moodScore"], let mood = latest["moodScore"],
           mood < mood7 - 2 {
            flags.append("Mood dropped significantly vs baseline")
        }

        if let bp = latest["bloodPressureSys"], bp > 140 {
            flags.append("Blood pressure systolic above 140 mmHg")
        }

        return flags
    }

    // MARK: - Supplement adherence

    static func supplementAdherence(doseEntries: [DoseEntry], days: Int = 14) -> [SupplementAdherenceItem] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = doseEntries.filter { $0.timestamp >= cutoff }

        let supplementCategories: Set<BuiltInSubstance.Category> = [.supplement, .vitamin]
        let supplementIDs = Set(
            SubstanceDatabase.allSubstances
                .filter { supplementCategories.contains($0.category) }
                .map { $0.id }
        )

        var substanceDays: [String: Set<String>] = [:]

        for entry in recent {
            guard let builtInId = entry.builtInSubstanceId,
                  supplementIDs.contains(builtInId) else { continue }
            let name = SubstanceDatabase.find(id: builtInId)?.name ?? "Unknown"
            let dayKey = calendar.startOfDay(for: entry.timestamp).description
            substanceDays[name, default: []].insert(dayKey)
        }

        return substanceDays.map { name, daySet in
            let taken = daySet.count
            return SupplementAdherenceItem(name: name, taken: taken, total: days, rate: Int(round(Double(taken) / Double(days) * 100)))
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Flatten today's data

    @MainActor
    static func flattenToday(
        biometricEntries: [BiometricEntry],
        healthEntries: [HealthEntry],
        healthKit: HealthKitService?
    ) -> [String: Double] {
        var result: [String: Double] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayBio = biometricEntries
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date > $1.date }
            .first

        let todayHealth = healthEntries
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date > $1.date }
            .first

        // Sleep: prefer HealthKit > biometric > health entry
        if let hk = healthKit?.sleepHours {
            result["sleepHours"] = hk
        } else if let bio = todayBio?.sleepHours {
            result["sleepHours"] = bio
        } else if let he = todayHealth?.sleepHours {
            result["sleepHours"] = he
        }

        // Steps: prefer HealthKit > biometric
        if let hk = healthKit?.steps {
            result["steps"] = Double(hk)
        } else if let bio = todayBio?.steps {
            result["steps"] = Double(bio)
        }

        // Heart rate: prefer HealthKit > biometric
        if let hk = healthKit?.heartRate {
            result["heartRate"] = hk
        } else if let bio = todayBio?.heartRate {
            result["heartRate"] = Double(bio)
        }

        // Blood pressure systolic: prefer HealthKit > biometric
        if let hk = healthKit?.systolicBP {
            result["bloodPressureSys"] = Double(hk)
        } else if let bio = todayBio?.bpSystolic {
            result["bloodPressureSys"] = Double(bio)
        }

        // Mood: from health entry, scale 1-5 to 1-10
        if let mood = todayHealth?.mood {
            result["moodScore"] = Double(mood) * 2.0
        }

        return result
    }

    // MARK: - Last 7 day averages

    static func last7DayAverages(
        biometricEntries: [BiometricEntry],
        healthEntries: [HealthEntry]
    ) -> [String: Double] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let recentBio = biometricEntries.filter { $0.date >= cutoff }
        let recentHealth = healthEntries.filter { $0.date >= cutoff }

        var result: [String: Double] = [:]

        let sleepValues = recentBio.compactMap(\.sleepHours) + recentHealth.map(\.sleepHours)
        if !sleepValues.isEmpty {
            result["sleepHours"] = sleepValues.reduce(0, +) / Double(sleepValues.count)
        }

        let stepValues = recentBio.compactMap(\.steps).map(Double.init)
        if !stepValues.isEmpty {
            result["steps"] = stepValues.reduce(0, +) / Double(stepValues.count)
        }

        let hrValues = recentBio.compactMap(\.heartRate).map(Double.init)
        if !hrValues.isEmpty {
            result["heartRate"] = hrValues.reduce(0, +) / Double(hrValues.count)
        }

        let moodValues = recentHealth.map { Double($0.mood) * 2.0 }
        if !moodValues.isEmpty {
            result["moodScore"] = moodValues.reduce(0, +) / Double(moodValues.count)
        }

        return result
    }

    // MARK: - Full score computation

    @MainActor
    static func computeFullScore(
        dataStore: DataStore,
        healthKit: HealthKitService?
    ) -> HealthScoreResult {
        let todayMetrics = flattenToday(
            biometricEntries: dataStore.biometricEntries,
            healthEntries: dataStore.healthEntries,
            healthKit: healthKit
        )

        let breakdown = scoreBreakdown(metrics: todayMetrics)
        let rank = healthRank(score: breakdown.total)

        let avg7 = last7DayAverages(
            biometricEntries: dataStore.biometricEntries,
            healthEntries: dataStore.healthEntries
        )
        let anomalies = metricAnomalies(last7Avg: avg7, latest: todayMetrics)

        let adherence = supplementAdherence(doseEntries: dataStore.doseEntries)

        return HealthScoreResult(
            breakdown: breakdown,
            rank: rank,
            anomalies: anomalies,
            adherence: adherence
        )
    }
}
