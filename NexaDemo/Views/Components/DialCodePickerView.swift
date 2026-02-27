import SwiftUI

struct DialCodePickerView: View {
    let dialCodes: [DialCodeOption]
    let onSelect: (DialCodeOption) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filteredDialCodes) { option in
                Button {
                    onSelect(option)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(option.countryName)
                            .foregroundStyle(.black)
                        Text(option.dialCode)
                            .font(.footnote)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Select Code")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var filteredDialCodes: [DialCodeOption] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dialCodes
        }
        return dialCodes.filter {
            $0.countryName.localizedStandardContains(searchText) || $0.dialCode.localizedStandardContains(searchText)
        }
    }
}
