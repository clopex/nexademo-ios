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
    case aiChat
    case focusSession(FocusSessionProposal)
}

enum AIRoute: Hashable {
    case scanResult(String)
    case chat(String? = nil)
}

enum PremiumRoute: Hashable {
    case transactionHistory
}

enum ConnectRoute: Hashable {
    case contactDetail(String)
    case activeCall(String)
}

enum ProfileRoute: Hashable {
    case profile
    case biometricSetup
    case voiceNotes
}

// MARK: - Sheets & Full Screen

enum AppSheet: Identifiable {
    case editProfile
    case paywall
    case revenueCatPaywall
    case imagePicker
    var id: String { String(describing: self) }
}

enum AppFullScreen: Identifiable {
    case camera(AIStudioViewModel)
    case onboarding
    case videoCall(String)
    var id: String {
        switch self {
        case .camera(let viewModel):
            return "camera-\(ObjectIdentifier(viewModel).hashValue)"
        case .onboarding:
            return "onboarding"
        case .videoCall(let channel):
            return "videoCall-\(channel)"
        }
    }
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
    @Environment(AppTabRouter.self) private var tabRouter
    @State private var nexaVisible = false

    var body: some View {
        @Bindable var tabRouter = tabRouter

        ZStack(alignment: .bottom) {
            TabView(selection: $tabRouter.selectedTab) {
                Tab("Home", systemImage: "house.fill", value: .home) {
                    HomeFlowView()
                }
                Tab("AI Studio", systemImage: "camera.viewfinder", value: .ai) {
                    AIFlowView()
                }
                Tab("Premium", systemImage: "creditcard.fill", value: .premium) {
                    PremiumFlowView()
                }
                Tab("Connect", systemImage: "phone.fill", value: .connect) {
                    ConnectFlowView()
                }
                Tab("Settings", systemImage: "gearshape.fill", value: .profile) {
                    ProfileFlowView()
                }
            }
            .tint(Color("BrandAccent"))

            // Floating Nexa button
            HStack {
                Spacer()
                NexaFloatingButton(isPresented: $nexaVisible)
                    .padding(.bottom, 76)
            }

            // Nexa overlay
            if nexaVisible {
                NexaAssistantView(isPresented: $nexaVisible)
                    .zIndex(100)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.35), value: nexaVisible)
    }
}

// MARK: - Tab Flows

struct HomeFlowView: View {
    @State private var router = HomeRouter()
    @Environment(AppTabRouter.self) private var tabRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .notifications: NotificationsView()
                    case .aiChat: AIChatView()
                    case .focusSession(let proposal):
                        FocusSessionProposalView(proposal: proposal)
                    }
                }
        }
        .environment(router)
        .task(id: tabRouter.pendingHomeRoute) {
            guard let route = tabRouter.pendingHomeRoute else { return }
            router.push(route)
            tabRouter.pendingHomeRoute = nil
        }
    }
}

struct AIFlowView: View {
    @State private var router = AIRouter()
    @Environment(AppTabRouter.self) private var tabRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            CameraStudioView()
                .navigationDestination(for: AIRoute.self) { route in
                    switch route {
                    case .scanResult(let result): ScanResultView(result: result)
                    case .chat(let message): AIChatView(initialMessage: message)
                    }
                }
        }
        .environment(router)
        .task(id: tabRouter.pendingAIRoute) {
            guard let route = tabRouter.pendingAIRoute else { return }
            router.push(route)
            tabRouter.pendingAIRoute = nil
        }
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
    @Environment(AppTabRouter.self) private var tabRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            ConnectView()
                .navigationDestination(for: ConnectRoute.self) { route in
                    switch route {
                    case .contactDetail(let id): ContactDetailView(contactId: id)
                    case .activeCall(let channel):
                        VoiceCallView(
                            channel: channel,
                            contactName: DemoContact.samples.first { $0.channelName == channel }?.name ?? "Demo Contact",
                            contactInitials: DemoContact.samples.first { $0.channelName == channel }?.initials ?? "DC"
                        )
                    }
                }
        }
        .environment(router)
        .task(id: tabRouter.pendingConnectRoute) {
            guard let route = tabRouter.pendingConnectRoute else { return }
            router.push(route)
            tabRouter.pendingConnectRoute = nil
        }
    }
}

struct ProfileFlowView: View {
    @State private var router = ProfileRouter()
    @Environment(AppTabRouter.self) private var tabRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            SettingsHomeView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .profile: UserUpdateView()
                    case .biometricSetup: BiometricSetupView()
                    case .voiceNotes: VoiceNotesView()
                    }
                }
        }
        .environment(router)
        .task(id: tabRouter.pendingProfileRoute) {
            guard let route = tabRouter.pendingProfileRoute else { return }
            router.push(route)
            tabRouter.pendingProfileRoute = nil
        }
    }
}
