import SwiftUI

struct UpdateProfileBottomButtonView: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button("Update", action: action)
            .font(.headline)
            .bold()
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black.opacity(isDisabled ? 0.35 : 1))
            .clipShape(.rect(cornerRadius: 28))
            .disabled(isDisabled)
    }
}
