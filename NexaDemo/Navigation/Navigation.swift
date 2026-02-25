import SwiftUI

// MARK: - Routes

enum AuthRoute: Hashable {
    case register
    case forgotPassword
    case emailLogin
}

enum HomeRoute: Hashable {
    case profile
    case settings
    case notifications
}

enum AIRoute: Hashable {
    case scanResult(String)
    case chat
}

enum PaymentRoute: Hashable {
    case paywall
    case transactionHistory
}

enum ProfileRoute: Hashable {
    case editProfile
    case settings
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
final class PaymentRouter {
    var path = NavigationPath()
    func push(_ route: PaymentRoute) { path.append(route) }
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

// MARK: - Root View

struct RootView: View {
    @State private var authVM = AuthViewModel()
    @State private var sheetManager = AppSheetManager()

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
        .sheet(item: $sheetManager.activeSheet) { sheet in
            switch sheet {
            case .editProfile: EditProfileView()
            case .paywall: PaywallView()
            case .imagePicker: ImagePickerView()
            }
        }
        .fullScreenCover(item: $sheetManager.activeFullScreen) { screen in
            switch screen {
            case .camera: CameraView()
            case .onboarding: OnboardingView()
            }
        }
        .environment(authVM)
        .environment(sheetManager)
    }
}

// MARK: - Auth Flow

struct AuthFlowView: View {
    @State private var router = AuthRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            LoginView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView()
                    case .forgotPassword:
                        ForgotPasswordView()
                    case .emailLogin:
                        EmailLoginView()
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
                .tabItem { Label("Home", systemImage: "house") }

            AIFlowView()
                .tabItem { Label("AI Studio", systemImage: "camera.viewfinder") }

            PaymentFlowView()
                .tabItem { Label("Premium", systemImage: "creditcard") }

            ProfileFlowView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

// MARK: - Home Flow

struct HomeFlowView: View {
    @State private var router = HomeRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .profile: ProfileView()
                    case .settings: SettingsView()
                    case .notifications: NotificationsView()
                    }
                }
        }
        .environment(router)
    }
}

// MARK: - AI Flow

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

// MARK: - Payment Flow

struct PaymentFlowView: View {
    @State private var router = PaymentRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            PaymentView()
                .navigationDestination(for: PaymentRoute.self) { route in
                    switch route {
                    case .paywall: PaywallView()
                    case .transactionHistory: TransactionHistoryView()
                    }
                }
        }
        .environment(router)
    }
}

// MARK: - Profile Flow

struct ProfileFlowView: View {
    @State private var router = ProfileRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            ProfileView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .editProfile: EditProfileView()
                    case .settings: SettingsView()
                    }
                }
        }
        .environment(router)
    }
}
