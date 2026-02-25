import SwiftUI

@main
struct NexaDemoApp: App {
    @State private var authVM = AuthViewModel()
    @State private var authRouter = AuthRouter()

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoggedIn {
                    HomeView()
                        .environment(authRouter)
                } else {
                    NavigationStack(path: $authRouter.path) {
                        LoginView()
                            .navigationDestination(for: AuthRoute.self) { route in
                                switch route {
                                case .register: RegisterView()
                                case .forgotPassword: ForgotPasswordView()
                                case .emailLogin: EmailLoginView()
                                }
                            }
                    }
                    .environment(authRouter)
                }
            }
            .environment(authVM)
        }
    }
}
