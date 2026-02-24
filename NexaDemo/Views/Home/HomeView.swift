import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dobrodošao,")
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        Text(authVM.currentUser?.fullName ?? "Korisnik")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .bold))
                    }

                    Spacer()

                    Button { authVM.logout() } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1A2E"))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Text("✅ Backend Connected")
                                .foregroundColor(.green)
                                .font(.headline)
                            Text(authVM.currentUser?.email ?? "")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    )
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}
