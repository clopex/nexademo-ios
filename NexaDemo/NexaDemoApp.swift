import SwiftUI
import SwiftData

@main
struct NexaDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var authVM = AuthViewModel()
    @State private var sheetManager = AppSheetManager()
    @State private var tabRouter = AppTabRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .environment(sheetManager)
                .environment(tabRouter)
                .modelContainer(for: VoiceNote.self)
        }
    }
}
