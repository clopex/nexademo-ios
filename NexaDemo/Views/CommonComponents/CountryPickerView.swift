import SwiftUI

struct CountryPickerView: View {
    let countries: [CountryEntry]
    let onSelect: (CountryEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    onSelect(country)
                    dismiss()
                } label: {
                    Text(country.name)
                        .foregroundStyle(.black)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Select Country")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var filteredCountries: [CountryEntry] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return countries
        }
        return countries.filter { $0.name.localizedStandardContains(searchText) }
    }
}
