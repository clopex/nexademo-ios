import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(RevenueCatService.self) private var rcService
    
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
            if isLoggedIn, let user = authVM.currentUser {
                rcService.configure(userId: user.id)
                Task { await rcService.checkPremiumStatus() }
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
