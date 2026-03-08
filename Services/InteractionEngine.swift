import Foundation
import SwiftUI

enum Severity: Int, Comparable {
    case minor = 0
    case moderate = 1
    case major = 2

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var color: Color {
        switch self {
        case .minor: return .gray
        case .moderate: return .orange
        case .major: return .red
        }
    }

    var label: String {
        switch self {
        case .minor: return "Minor"
        case .moderate: return "Moderate"
        case .major: return "Major"
        }
    }
}

struct InteractionResult: Identifiable {
    let id = UUID()
    let description: String
    let severity: Severity
}

struct InteractionEngine {
    private static let majorKeywords = [
        "fatal", "dangerous", "avoid", "seizure",
        "serotonin syndrome", "death", "contraindicated"
    ]
    private static let moderateKeywords = [
        "potentiates", "reduces", "increases",
        "inhibits", "enhances", "worsens"
    ]

    static func classify(_ text: String) -> Severity {
        let lower = text.lowercased()
        if majorKeywords.contains(where: { lower.contains($0) }) { return .major }
        if moderateKeywords.contains(where: { lower.contains($0) }) { return .moderate }
        return .minor
    }

    static func check(_ a: BuiltInSubstance, _ b: BuiltInSubstance) -> [InteractionResult] {
        var results: [InteractionResult] = []
        var seen = Set<String>()

        for interaction in a.interactions {
            if interaction.localizedCaseInsensitiveContains(b.name) ||
               interaction.localizedCaseInsensitiveContains(b.category.rawValue) {
                let key = interaction.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    results.append(InteractionResult(
                        description: "\(a.name): \(interaction)",
                        severity: classify(interaction)
                    ))
                }
            }
        }

        for interaction in b.interactions {
            if interaction.localizedCaseInsensitiveContains(a.name) ||
               interaction.localizedCaseInsensitiveContains(a.category.rawValue) {
                let key = interaction.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    results.append(InteractionResult(
                        description: "\(b.name): \(interaction)",
                        severity: classify(interaction)
                    ))
                }
            }
        }

        return results.sorted { $0.severity > $1.severity }
    }
}
