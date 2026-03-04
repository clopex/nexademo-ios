import Foundation

struct CountryService: Sendable {
    static let shared = CountryService()

    func fetchCountries() async throws -> [CountryEntry] {
        let url = URL(string: "https://restcountries.com/v3.1/all?fields=name,idd,cca2")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkClientError.invalidResponse
        }

        let decoded = try JSONDecoder().decode([CountryResponse].self, from: data)
        let countries = decoded.compactMap { item -> CountryEntry? in
            guard let code = item.cca2 else { return nil }
            let name = item.name.common
            let root = item.idd?.root ?? ""
            let suffixes = item.idd?.suffixes ?? []
            let dialCodes: [String]
            if !suffixes.isEmpty {
                dialCodes = suffixes.map { "\(root)\($0)" }
            } else if !root.isEmpty {
                dialCodes = [root]
            } else {
                dialCodes = []
            }
            return CountryEntry(name: name, code: code, dialCodes: dialCodes)
        }
        return countries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private struct CountryResponse: Decodable {
    struct CountryName: Decodable {
        let common: String
    }

    struct CountryIDD: Decodable {
        let root: String?
        let suffixes: [String]?
    }

    let name: CountryName
    let cca2: String?
    let idd: CountryIDD?
}
