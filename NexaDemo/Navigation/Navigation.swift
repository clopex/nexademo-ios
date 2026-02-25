import SwiftUI

// MARK: - Routes

enum AuthRoute: Hashable {
    case register
    case forgotPassword
    case emailLogin
    case login
}

enum HomeRoute: Hashable {
    case notifications
}

enum AIRoute: Hashable {
    case scanResult(String)
    case chat
}

enum PremiumRoute: Hashable {
    case transactionHistory
}

enum ConnectRoute: Hashable {
    case contactDetail(String)
    case activeCall(String)
}

enum ProfileRoute: Hashable {
    case editProfile
    case settings
    case voiceNotes
}

// MARK: - Sheets & Full Screen

enum AppSheet: Identifiable {
    case editProfile
    case paywall
    case imagePicker
    var id: String { String(describing: self) }
}

enum AppFullScreen: Identifiable {
    case camera
    case onboarding
    case videoCall(String)
    var id: String { String(describing: self) }
}

// MARK: - Routers

@MainActor
@Observable
final class AuthRouter {
    var path = NavigationPath()
    func push(_ route: AuthRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

@MainActor
@Observable
final class HomeRouter {
    var path = NavigationPath()
    func push(_ route: HomeRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

@MainActor
@Observable
final class AIRouter {
    var path = NavigationPath()
    func push(_ route: AIRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

@MainActor
@Observable
final class PremiumRouter {
    var path = NavigationPath()
    func push(_ route: PremiumRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

@MainActor
@Observable
final class ConnectRouter {
    var path = NavigationPath()
    func push(_ route: ConnectRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

@MainActor
@Observable
final class ProfileRouter {
    var path = NavigationPath()
    func push(_ route: ProfileRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

// MARK: - Sheet Manager

@MainActor
@Observable
final class AppSheetManager {
    var activeSheet: AppSheet?
    var activeFullScreen: AppFullScreen?

    func present(_ sheet: AppSheet) { activeSheet = sheet }
    func presentFullScreen(_ screen: AppFullScreen) { activeFullScreen = screen }
    func dismiss() { activeSheet = nil }
    func dismissFullScreen() { activeFullScreen = nil }
}


// MARK: - Auth Flow

struct AuthFlowView: View {
    @State private var router = AuthRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            RegisterLandingView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register: RegisterView()
                    case .forgotPassword: ForgotPasswordView()
                    case .emailLogin: EmailLoginView()
                    case .login: LoginView()
                    }
                }
        }
        .environment(router)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeFlowView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            AIFlowView()
                .tabItem { Label("AI Studio", systemImage: "camera.viewfinder") }

            PremiumFlowView()
                .tabItem { Label("Premium", systemImage: "creditcard.fill") }

            ConnectFlowView()
                .tabItem { Label("Connect", systemImage: "phone.fill") }

            ProfileFlowView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}

// MARK: - Tab Flows

struct HomeFlowView: View {
    @State private var router = HomeRouter()
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .notifications: NotificationsView()
                    }
                }
        }
        .environment(router)
    }
}

struct AIFlowView: View {
    @State private var router = AIRouter()
    var body: some View {
        NavigationStack(path: $router.path) {
            AIStudioView()
                .navigationDestination(for: AIRoute.self) { route in
                    switch route {
                    case .scanResult(let result): ScanResultView(result: result)
                    case .chat: AIChatView()
                    }
                }
        }
        .environment(router)
    }
}

struct PremiumFlowView: View {
    @State private var router = PremiumRouter()
    var body: some View {
        NavigationStack(path: $router.path) {
            PremiumView()
                .navigationDestination(for: PremiumRoute.self) { route in
                    switch route {
                    case .transactionHistory: TransactionHistoryView()
                    }
                }
        }
        .environment(router)
    }
}

struct ConnectFlowView: View {
    @State private var router = ConnectRouter()
    var body: some View {
        NavigationStack(path: $router.path) {
            ConnectView()
                .navigationDestination(for: ConnectRoute.self) { route in
                    switch route {
                    case .contactDetail(let id): ContactDetailView(contactId: id)
                    case .activeCall(let channel): VoiceCallView(channel: channel)
                    }
                }
        }
        .environment(router)
    }
}

struct ProfileFlowView: View {
    @State private var router = ProfileRouter()
    var body: some View {
        NavigationStack(path: $router.path) {
            ProfileView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .editProfile: EditProfileView()
                    case .settings: SettingsView()
                    case .voiceNotes: VoiceNotesView()
                    }
                }
        }
        .environment(router)
    }
}
