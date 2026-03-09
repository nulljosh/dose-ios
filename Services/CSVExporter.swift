import Foundation

enum CSVExportError: LocalizedError {
    case writeFailure(String)

    var errorDescription: String? {
        switch self {
        case .writeFailure(let msg): return msg
        }
    }
}

struct CSVExporter {
    @MainActor static func export(entries: [DoseEntry], dataStore: DataStore) -> Result<URL, Error> {
        let header = "date,time,substance,dose,unit,route,rating,notes"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var lines = [header]
        let sorted = entries.sorted { $0.timestamp > $1.timestamp }

        for entry in sorted {
            let date = dateFormatter.string(from: entry.timestamp)
            let time = timeFormatter.string(from: entry.timestamp)
            let substance = dataStore.substanceName(for: entry)
            let dose = entry.dose.map { String($0) } ?? ""
            let unit = entry.unit ?? ""
            let route = entry.route ?? ""
            let rating = entry.rating.map { String($0) } ?? ""
            let notes = csvEscape(entry.notes)
            lines.append("\(date),\(time),\(csvEscape(substance)),\(dose),\(unit),\(route),\(rating),\(notes)")
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dose-export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return .success(url)
        } catch {
            return .failure(CSVExportError.writeFailure(error.localizedDescription))
        }
    }

    static func cleanup() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dose-export.csv")
        try? FileManager.default.removeItem(at: url)
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            return "\"\(escaped)\""
        }
        return value
    }
}
