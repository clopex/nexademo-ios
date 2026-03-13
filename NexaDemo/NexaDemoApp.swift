import SwiftUI
import SwiftData

@main
struct NexaDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var authVM = AuthViewModel()
    @State private var sheetManager = AppSheetManager()
    @State private var tabRouter = AppTabRouter()
    @State private var alarmLaunchRouter = AlarmLaunchRouter()
    @State private var rcService = RevenueCatService()
    @State private var focusSessionStore = FocusSessionStore()
    @State private var nexaPlacesCoordinator = NexaPlacesCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .environment(sheetManager)
                .environment(tabRouter)
                .environment(alarmLaunchRouter)
                .environment(rcService)
                .environment(focusSessionStore)
                .environment(nexaPlacesCoordinator)
                .modelContainer(for: [VoiceNote.self, VoiceNoteReminder.self])
        }
    }
}
