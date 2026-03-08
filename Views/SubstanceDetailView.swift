import SwiftUI

struct SubstanceDetailView: View {
    let substance: BuiltInSubstance

    private var hasNotes: Bool {
        !substance.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        List {
            Section("Overview") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(substance.category.rawValue.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(substance.category.categoryColor)
                        }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Half-life:")
                            .font(.subheadline.weight(.semibold))
                        Text(substance.halfLife)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Unit:")
                            .font(.subheadline.weight(.semibold))
                        Text(substance.unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Routes")
                            .font(.subheadline.weight(.semibold))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(substance.routes, id: \.self) { route in
                                    Text(route)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background {
                                            Capsule()
                                                .fill(.quaternary)
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Effects") {
                ForEach(substance.effects, id: \.self) { effect in
                    Text("• \(effect)")
                }
            }

            Section("Interactions") {
                ForEach(substance.interactions, id: \.self) { interaction in
                    Text(interaction)
                        .foregroundStyle(.orange)
                }
            }

            Section("Harm Reduction") {
                ForEach(substance.harmReduction, id: \.self) { tip in
                    Text(tip)
                }
            }

            if hasNotes {
                Section("Notes") {
                    Text(substance.notes)
                        .font(.body)
                }
            }
        }
        .navigationTitle(substance.name)
    }
}

#Preview {
    NavigationStack {
        SubstanceDetailView(substance: SubstanceDatabase.allSubstances[0])
    }
}
