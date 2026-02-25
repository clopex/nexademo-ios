import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppSheetManager.self) private var sheetManager

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
        .sheet(item: sheetBinding) { sheet in
            switch sheet {
            case .editProfile: EditProfileView()
            case .paywall: PaywallView()
            case .imagePicker: ImagePickerView()
            }
        }
        .fullScreenCover(item: fullScreenBinding) { screen in
            switch screen {
            case .camera: CameraView()
            case .onboarding: OnboardingView()
            case .videoCall(let channel): VideoCallView(channel: channel)
            }
        }
    }

    private var sheetBinding: Binding<AppSheet?> {
        Binding(
            get: { sheetManager.activeSheet },
            set: { sheetManager.activeSheet = $0 }
        )
    }

    private var fullScreenBinding: Binding<AppFullScreen?> {
        Binding(
            get: { sheetManager.activeFullScreen },
            set: { sheetManager.activeFullScreen = $0 }
        )
    }
}
