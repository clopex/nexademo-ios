import SwiftUI
import UIKit

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.gray)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    ZStack {
        Color("BackgroundDark").ignoresSafeArea()

        AuthTextField(
            placeholder: "Email",
            text: $text,
            icon: "envelope",
            isSecure: false,
            keyboardType: .emailAddress,
            autocapitalization: .never
        )
        .padding()
    }
}
