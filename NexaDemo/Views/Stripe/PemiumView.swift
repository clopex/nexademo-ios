//
//  PemiumView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 4. 3. 2026..
//

import SwiftUI
import StripePaymentSheet

struct PremiumView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var stripeService = StripeService()
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color("PremiumGradientStart"), Color("PremiumGradientEnd")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color("SuccessAccent"))
                        }
                        .padding(.top, 32)

                        Text("Upgrade to Premium")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)

                        Text("Unlock all features and get unlimited access")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Plan comparison
                    VStack(spacing: 12) {
                        planCard(
                            title: "Free Plan",
                            subtitle: "Current plan",
                            features: [
                                ("camera.viewfinder", "5 AI Scans / day"),
                                ("bubble.left", "20 AI Chat messages / day"),
                                ("mic", "1 min Voice / day"),
                                ("phone.fill", "No calls"),
                            ],
                            isPremium: false,
                            isCurrent: !(authVM.currentUser?.isPremium ?? false)
                        )

                        planCard(
                            title: "Premium",
                            subtitle: "$4.99 / month",
                            features: [
                                ("camera.viewfinder", "Unlimited AI Scans"),
                                ("bubble.left", "Unlimited AI Chat"),
                                ("mic", "Unlimited Voice"),
                                ("phone.fill", "HD Video Calls"),
                            ],
                            isPremium: true,
                            isCurrent: authVM.currentUser?.isPremium ?? false
                        )
                    }
                    .padding(.horizontal, 20)

                    // Error
                    if let error = stripeService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // CTA Button
                    if !(authVM.currentUser?.isPremium ?? false) {
                        PaymentButton(stripeService: stripeService) {
                            await handlePaymentResult()
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Already premium
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color("SuccessAccent"))
                            Text("You are on Premium plan")
                                .font(.headline)
                                .foregroundStyle(Color("SuccessAccent"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("SuccessAccent").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSuccess) {
            PaymentSuccessSheet()
        }
    }

    // MARK: - Plan Card
    private func planCard(
        title: String,
        subtitle: String,
        features: [(String, String)],
        isPremium: Bool,
        isCurrent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(isPremium ? Color("SuccessAccent") : .gray)
                }
                Spacer()
                if isCurrent {
                    Text("Current")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isPremium ? Color("SuccessAccent") : Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            VStack(spacing: 10) {
                ForEach(features, id: \.0) { icon, text in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(isPremium ? Color("BrandAccent") : .gray)
                            .frame(width: 20)
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(isPremium ? .white : Color.white.opacity(0.6))
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            isPremium
            ? LinearGradient(
                colors: [Color("PremiumGradientStart").opacity(0.8), Color("PremiumGradientEnd").opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [Color("CardBackground"), Color("CardBackground")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isPremium ? Color("PremiumGradientEnd").opacity(0.6) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Payment Handler
    private func handlePaymentResult() async {
        switch stripeService.paymentResult {
        case .completed:
            do {
                try await stripeService.confirmCompletedPayment()
                showSuccess = true
                await authVM.loadCurrentUser()
            } catch {
                stripeService.errorMessage = error.localizedDescription
            }
        case .failed(let error):
            stripeService.errorMessage = error.localizedDescription
        case .canceled:
            break
        case .none:
            break
        }
    }
}

// MARK: - Payment Button (UIViewControllerRepresentable)
struct PaymentButton: View {
    let stripeService: StripeService
    let onComplete: () async -> Void

    var body: some View {
        Button {
            Task {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let viewController = windowScene.windows.first?.rootViewController else { return }
                await stripeService.startPayment(from: viewController)
                await onComplete()
            }
        } label: {
            HStack {
                if stripeService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium — $4.99")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color("BrandAccent"), Color("PremiumGradientEnd")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .disabled(stripeService.isLoading)
    }
}

// MARK: - Payment Success Sheet
struct PaymentSuccessSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color("SuccessAccent").opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color("SuccessAccent"))
                }

                Text("Welcome to Premium!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("You now have unlimited access to all NexaDemo features.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Start Exploring")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("SuccessAccent"))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}
