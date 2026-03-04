import Foundation
import Observation

@MainActor
@Observable
final class CountryLookupStore {
    var countries: [CountryEntry] = []
    var dialCodes: [DialCodeOption] = []
    var isLoading = false
    var errorMessage: String?

    func loadIfNeeded() async {
        guard countries.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await CountryService.shared.fetchCountries()
            countries = fetched
            dialCodes = fetched.flatMap { country in
                country.dialCodes.map { dial in
                    DialCodeOption(
                        countryName: country.name,
                        countryCode: country.code,
                        dialCode: dial
                    )
                }
            }
            .sorted { $0.countryName.localizedCaseInsensitiveCompare($1.countryName) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
