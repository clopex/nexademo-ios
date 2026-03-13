import Foundation
import Observation

@Observable
@MainActor
final class NexaPlacesCoordinator {
    var isVisible = false
    var pendingQuery: String?
    var queryVersion = 0

    func submit(query: String?) {
        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedQuery, trimmedQuery.isEmpty == false else { return }

        pendingQuery = trimmedQuery
        queryVersion += 1
    }

    func consumePendingQuery() -> String? {
        defer { pendingQuery = nil }
        return pendingQuery
    }
}
