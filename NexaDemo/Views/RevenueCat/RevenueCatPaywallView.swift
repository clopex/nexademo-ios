//
//  RevenueCatPaywallView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 5. 3. 2026..
//

import SwiftUI
import RevenueCat

struct RevenueCatPaywallView: View {
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(AuthViewModel.self) private var authVM
    @Environment(RevenueCatService.self) private var rcService
    @State private var selectedPackage: Package?
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color("PremiumGradientStart"), Color("PremiumGradientEnd")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color("SuccessAccent"))
                    }
                    
                    Text("Upgrade to Premium")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Unlock unlimited AI scans, voice, and HD calls")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 8)
                
                // Packages
                if rcService.isLoading {
                    ProgressView()
                        .tint(Color("BrandAccent"))
                        .padding()
                } else if let offering = rcService.offerings?.current {
                    VStack(spacing: 12) {
                        ForEach(offering.availablePackages, id: \.identifier) { package in
                            PackageCard(
                                package: package,
                                isSelected: selectedPackage?.identifier == package.identifier
                            ) {
                                selectedPackage = package
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    Text("No packages available")
                        .foregroundStyle(.gray)
                }
                
                if let error = rcService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Purchase button
                Button {
                    guard let package = selectedPackage else { return }
                    Task {
                        let success = await rcService.purchase(package: package)
                        if success, await finalizePremiumActivation() {
                            showSuccess = true
                        }
                    }
                } label: {
                    HStack {
                        if rcService.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "crown.fill")
                            Text(selectedPackage != nil ? "Subscribe for \(selectedPackage!.localizedPriceString)" : "Select a plan")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        selectedPackage != nil
                        ? LinearGradient(colors: [Color("BrandAccent"), Color("PremiumGradientEnd")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(selectedPackage == nil || rcService.isLoading)
                .padding(.horizontal, 20)
                
                // Restore button
                Button {
                    Task { await rcService.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.bottom, 32)
            }
        }
        .task {
            await rcService.fetchOfferings()
            selectedPackage = rcService.offerings?.current?.monthly
        }
        .sheet(isPresented: $showSuccess) {
            PaymentSuccessSheet {
                showSuccess = false
                sheetManager.dismiss()
                return true
            }
        }
    }

    @MainActor
    private func finalizePremiumActivation() async -> Bool {
        do {
            let user = try await rcService.activatePremium()
            authVM.currentUser = user
        } catch {
            rcService.errorMessage = error.localizedDescription
            return false
        }

        await rcService.checkPremiumStatus()
        await authVM.loadCurrentUser()
        return true
    }
}

// MARK: - Package Card
struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("BrandAccent") : Color("CardBackground"))
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Text(package.localizedPriceString)
                    .font(.body.weight(.bold))
                    .foregroundStyle(isSelected ? Color("SuccessAccent") : .white)
            }
            .padding(16)
            .background(
                isSelected
                ? Color("PremiumGradientStart").opacity(0.6)
                : Color("CardBackground")
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color("BrandAccent") : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
