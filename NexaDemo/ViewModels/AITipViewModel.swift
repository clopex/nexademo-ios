import Foundation

@Observable
final class AITipViewModel {
    private let service: TipsService
    var tip: String?
    var isLoading = false

    init(service: TipsService) {
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let response = try await service.fetchDailyTip()
            tip = response.tip
        } catch {
            tip = nil
        }

        isLoading = false
    }
}
