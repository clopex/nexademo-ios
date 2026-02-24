import SwiftUI

@main
struct NexaDemoApp: App {
    @State private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoggedIn {
                    HomeView()
                } else {
                    LoginView()
                }
            }
            .environment(authVM)
        }
    }
}
