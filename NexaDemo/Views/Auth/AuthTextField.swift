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
                .foregroundColor(.gray)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
        .background(Color(hex: "1A1A2E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
