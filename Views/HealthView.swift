import SwiftUI

struct HealthView: View {
    @Bindable var dataStore: DataStore

    @State private var mood = 3.0
    @State private var energy = 3.0
    @State private var sleepHours = 8.0
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Check-In") {
                    VStack(alignment: .leading) {
                        Text("Mood: \(Int(mood))")
                        Slider(value: $mood, in: 1...5, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("Energy: \(Int(energy))")
                        Slider(value: $energy, in: 1...5, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("Sleep: \(sleepHours, specifier: "%.1f") hrs")
                        Slider(value: $sleepHours, in: 0...12, step: 0.5)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    Button("Save Health Entry") {
                        dataStore.addHealthEntry(
                            HealthEntry(
                                mood: Int(mood),
                                energy: Int(energy),
                                sleepHours: sleepHours,
                                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        notes = ""
                    }
                }
            }
            .navigationTitle("Health")
        }
    }
}
