import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppSheetManager.self) private var sheetManager

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
            case .videoCall(let channel): VideoCallView(channel: channel)
            }
        }
    }
}
