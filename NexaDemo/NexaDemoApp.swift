import SwiftUI

@main
struct NexaDemoApp: App {
    @State private var authVM = AuthViewModel()
    @State private var sheetManager = AppSheetManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .environment(sheetManager)
        }
    }
}
