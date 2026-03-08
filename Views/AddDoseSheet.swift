import SwiftUI

struct AddDoseSheet: View {
    @Bindable var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedSubstance: BuiltInSubstance? = nil
    @State private var doseAmount = ""
    @State private var selectedRoute = ""
    @State private var rating = 0
    @State private var notes = ""

    private var filteredSubstances: [BuiltInSubstance] {
        if searchText.isEmpty { return Array(SubstanceDatabase.allSubstances.prefix(20)) }
        return SubstanceDatabase.allSubstances.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var activeInteractions: [(String, String)] {
        guard let selected = selectedSubstance else { return [] }
        var results: [(String, String)] = []
        for entry in dataStore.getActive() {
            guard let bid = entry.builtInSubstanceId,
                  let active = SubstanceDatabase.find(id: bid) else { continue }
            for interaction in active.interactions {
                if interaction.localizedCaseInsensitiveContains(selected.name) {
                    results.append((active.name, interaction))
                }
            }
            for interaction in selected.interactions {
                if interaction.localizedCaseInsensitiveContains(active.name) {
                    results.append((selected.name, interaction))
                }
            }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Substance") {
                    if let substance = selectedSubstance {
                        HStack {
                            Text(substance.name)
                                .font(.body.weight(.semibold))
                            Text(substance.category.rawValue.capitalized)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(substance.category.categoryColor)
                                .clipShape(Capsule())
                            Spacer()
                            Button("Change") {
                                selectedSubstance = nil
                                searchText = ""
                            }
                            .font(.subheadline)
                        }
                    } else {
                        TextField("Search substances...", text: $searchText)
                        ForEach(filteredSubstances) { substance in
                            Button {
                                selectedSubstance = substance
                                selectedRoute = substance.routes.first ?? ""
                                doseAmount = ""
                            } label: {
                                HStack {
                                    Text(substance.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(substance.category.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(substance.category.categoryColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                if let substance = selectedSubstance {
                    Section("Dose") {
                        HStack {
                            TextField("Amount", text: $doseAmount)
                                .keyboardType(.decimalPad)
                            Text(substance.unit)
                                .foregroundStyle(.secondary)
                        }
                        Picker("Route", selection: $selectedRoute) {
                            ForEach(substance.routes, id: \.self) { route in
                                Text(route).tag(route)
                            }
                        }
                    }

                    Section("Rating") {
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = rating == star ? 0 : star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(.yellow)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if !activeInteractions.isEmpty {
                    Section("Interaction Warnings") {
                        ForEach(Array(activeInteractions.enumerated()), id: \.offset) { _, item in
                            Label {
                                Text("\(item.0): \(item.1)")
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Quick Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedSubstance == nil)
                }
            }
        }
    }

    private func save() {
        let entry = DoseEntry(
            builtInSubstanceId: selectedSubstance?.id,
            notes: notes,
            dose: Double(doseAmount),
            unit: selectedSubstance?.unit,
            route: selectedRoute.isEmpty ? nil : selectedRoute,
            rating: rating > 0 ? rating : nil
        )
        dataStore.addDoseEntry(entry)
        dismiss()
    }
}
