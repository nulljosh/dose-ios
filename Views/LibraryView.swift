import SwiftUI

struct LibraryView: View {
    @Bindable var dataStore: DataStore
    @State private var searchText = ""
    @State private var selectedCategory: BuiltInSubstance.Category? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredSubstances: [BuiltInSubstance] {
        SubstanceDatabase.allSubstances.filter { substance in
            let matchesSearch = searchText.isEmpty || substance.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || substance.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SubstanceDatabase.categories) { category in
                                let isSelected = selectedCategory == category

                                Button {
                                    selectedCategory = isSelected ? nil : category
                                } label: {
                                    Text(category.rawValue.capitalized)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(isSelected ? Color.white : category.categoryColor)
                                        .background {
                                            Capsule()
                                                .fill(isSelected ? category.categoryColor : Color.clear)
                                        }
                                        .overlay {
                                            Capsule()
                                                .stroke(category.categoryColor, lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredSubstances) { substance in
                            NavigationLink {
                                SubstanceDetailView(substance: substance)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Rectangle()
                                        .fill(substance.category.categoryColor)
                                        .frame(height: 6)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    Text(substance.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)

                                    Text(substance.category.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                                .padding(12)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.quaternary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        InteractionCheckerView()
                    } label: {
                        Image(systemName: "arrow.triangle.merge")
                    }
                }
            }
        }
    }
}
