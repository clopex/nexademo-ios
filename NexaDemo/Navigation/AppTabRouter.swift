import SwiftUI

@MainActor
@Observable
final class AppTabRouter {
    enum Tab: Hashable {
        case home
        case ai
        case premium
        case connect
        case profile
    }

    var selectedTab: Tab = .home
    var pendingAIRoute: AIRoute?
    var pendingConnectRoute: ConnectRoute?
    var pendingProfileRoute: ProfileRoute?

    func openAI(_ route: AIRoute? = nil) {
        selectedTab = .ai
        pendingAIRoute = route
    }

    func openConnect(_ route: ConnectRoute? = nil) {
        selectedTab = .connect
        pendingConnectRoute = route
    }

    func openProfile(_ route: ProfileRoute? = nil) {
        selectedTab = .profile
        pendingProfileRoute = route
    }
}
