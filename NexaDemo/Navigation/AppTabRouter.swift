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
    var pendingHomeRoute: HomeRoute?
    var pendingAIRoute: AIRoute?
    var pendingConnectRoute: ConnectRoute?
    var pendingProfileRoute: ProfileRoute?

    func openHome(_ route: HomeRoute? = nil) {
        selectedTab = .home
        pendingHomeRoute = route
    }

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

    func reset() {
        selectedTab = .home
        pendingHomeRoute = nil
        pendingAIRoute = nil
        pendingConnectRoute = nil
        pendingProfileRoute = nil
    }
}
