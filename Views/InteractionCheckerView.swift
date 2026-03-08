import SwiftUI

struct InteractionCheckerView: View {
    @State private var substanceA: BuiltInSubstance? = nil
    @State private var substanceB: BuiltInSubstance? = nil
    @State private var showingPickerA = false
    @State private var showingPickerB = false

    private var results: [InteractionResult] {
        guard let a = substanceA, let b = substanceB else { return [] }
        return InteractionEngine.check(a, b)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    substanceCard(label: "Substance A", substance: substanceA) {
                        showingPickerA = true
                    }

                    Button {
                        let temp = substanceA
                        substanceA = substanceB
                        substanceB = temp
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(substanceA == nil && substanceB == nil)

                    substanceCard(label: "Substance B", substance: substanceB) {
                        showingPickerB = true
                    }
                }

                if substanceA != nil && substanceB != nil {
                    if results.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("No known interactions found")
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.green.opacity(0.1)))
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interactions")
                                .font(.headline)

                            ForEach(results) { result in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(result.severity.color)
                                        .frame(width: 10, height: 10)
                                        .padding(.top, 5)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.severity.label)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(result.severity.color)
                                        Text(result.description)
                                            .font(.subheadline)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.quaternary))
                            }
                        }
                    }
                } else {
                    Text("Select two substances to check interactions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle("Interaction Checker")
        .sheet(isPresented: $showingPickerA) {
            SubstancePickerSheet(selection: $substanceA)
        }
        .sheet(isPresented: $showingPickerB) {
            SubstancePickerSheet(selection: $substanceB)
        }
    }

    private func substanceCard(label: String, substance: BuiltInSubstance?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let substance {
                    Text(substance.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text(substance.category.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(substance.category.categoryColor)
                        .clipShape(Capsule())
                } else {
                    Text("Select...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.quaternary))
        }
        .buttonStyle(.plain)
    }
}

private struct SubstancePickerSheet: View {
    @Binding var selection: BuiltInSubstance?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    private var filtered: [BuiltInSubstance] {
        if searchText.isEmpty { return SubstanceDatabase.allSubstances }
        return SubstanceDatabase.allSubstances.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { substance in
                Button {
                    selection = substance
                    dismiss()
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
            .navigationTitle("Select Substance")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
