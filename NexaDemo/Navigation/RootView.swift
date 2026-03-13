import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(AppTabRouter.self) private var tabRouter
    @Environment(AlarmLaunchRouter.self) private var alarmLaunchRouter
    @Environment(RevenueCatService.self) private var rcService
    @Environment(FocusSessionStore.self) private var focusSessionStore
    
    var body: some View {
        @Bindable var sheetManager = sheetManager
        
        Group {
            if authVM.isBootstrapping {
                AuthBootstrapView()
            } else if authVM.isLoggedIn, authVM.needsProfileSetup {
                NavigationStack {
                    UserUpdateView()
                }
            } else if authVM.isLoggedIn {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
        .onChange(of: authVM.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                tabRouter.reset()

                if let user = authVM.currentUser {
                    rcService.configure(userId: user.id)
                    Task { await rcService.checkPremiumStatus() }
                }
            } else {
                tabRouter.reset()
            }
        }
        .task {
            await AlarmLiveActivityService.shared.endExpiredActivities()
            await FocusSessionLiveActivityService.shared.consumePendingCleanup()
            await FocusSessionLiveActivityService.shared.endExpiredActivities()
            await focusSessionStore.reconcileSessionState()
            if alarmLaunchRouter.consumePendingLaunch(tabRouter: tabRouter) {
                await AlarmLiveActivityService.shared.endAllActivities()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await AlarmLiveActivityService.shared.endExpiredActivities()
                await FocusSessionLiveActivityService.shared.consumePendingCleanup()
                await FocusSessionLiveActivityService.shared.endExpiredActivities()
                await focusSessionStore.reconcileSessionState()
            }
            if alarmLaunchRouter.consumePendingLaunch(tabRouter: tabRouter) {
                Task { await AlarmLiveActivityService.shared.endAllActivities() }
            }
        }
        .onOpenURL { url in
            let openedFromAlarm = alarmLaunchRouter.handle(url, tabRouter: tabRouter)
            if openedFromAlarm {
                Task { await AlarmLiveActivityService.shared.endAllActivities() }
            }
        }
        .sheet(item: $sheetManager.activeSheet) { sheet in
            switch sheet {
            case .editProfile: EditProfileView()
            case .paywall: PaywallView()
            case .revenueCatPaywall: RevenueCatPaywallView()
            case .imagePicker: ImagePickerView()
            }
        }
        .fullScreenCover(item: $sheetManager.activeFullScreen) { screen in
            switch screen {
            case .camera(let viewModel): CameraMLView(viewModel: viewModel)
            case .onboarding: OnboardingView()
            case .videoCall(let channel): VideoCallView(channel: channel)
            }
        }
    }
}
