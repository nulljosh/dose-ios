import SwiftUI

struct LogView: View {
    @Bindable var dataStore: DataStore

    @State private var selectedSubstanceId: UUID?
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                if dataStore.substances.isEmpty {
                    Section {
                        Text("Add a substance first to log doses.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Dose") {
                        Picker("Substance", selection: $selectedSubstanceId) {
                            Text("Select").tag(nil as UUID?)
                            ForEach(dataStore.substances) { substance in
                                Text(substance.name).tag(Optional(substance.id))
                            }
                        }

                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }

                    Section {
                        Button("Save Dose") {
                            guard let selectedSubstanceId else { return }
                            dataStore.addDoseEntry(
                                DoseEntry(substanceId: selectedSubstanceId, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
                            )
                            notes = ""
                        }
                        .disabled(selectedSubstanceId == nil)
                    }
                }
            }
            .navigationTitle("Log")
        }
    }
}
