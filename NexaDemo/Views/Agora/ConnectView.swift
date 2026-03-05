//
//  ConnectView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 5. 3. 2026..
//

import SwiftUI

struct ConnectView: View {
    @Environment(ConnectRouter.self) private var router

    let contacts = DemoContact.samples

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color("BrandAccent"))
                        Text("Connect")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Start a voice call with demo contacts")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // Contacts list
                    VStack(spacing: 12) {
                        ForEach(contacts) { contact in
                            ContactRow(contact: contact) {
                                router.push(.contactDetail(contact.id))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let contact: DemoContact
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(contact.gradientStartAsset), Color(contact.gradientEndAsset)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                    Text(contact.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(contact.role)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "phone.fill")
                    .foregroundStyle(Color("SuccessAccent"))
                    .padding(10)
                    .background(Color("SuccessAccent").opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(16)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Detail View
struct ContactDetailView: View {
    @Environment(AppSheetManager.self) private var sheetManager
    let contactId: String

    var contact: DemoContact? {
        DemoContact.samples.first { $0.id == contactId }
    }

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            if let contact {
                VStack(spacing: 32) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(contact.gradientStartAsset), Color(contact.gradientEndAsset)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                        Text(contact.initials)
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 8) {
                        Text(contact.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(contact.role)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    // Call buttons
                    HStack(spacing: 24) {
                        // Voice call
                        Button {
                            sheetManager.presentFullScreen(.videoCall(contact.channelName))
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color("SuccessAccent").opacity(0.15))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color("SuccessAccent"))
                                }
                                Text("Voice Call")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Demo Contact Model
struct DemoContact: Identifiable {
    let id: String
    let name: String
    let role: String
    let initials: String
    let channelName: String
    let gradientStartAsset: String
    let gradientEndAsset: String

    static let samples: [DemoContact] = [
        DemoContact(id: "1", name: "Alex Johnson", role: "iOS Developer", initials: "AJ",
                   channelName: "nexademo-alex", gradientStartAsset: "BrandAccent", gradientEndAsset: "PremiumGradientEnd"),
        DemoContact(id: "2", name: "Sarah Miller", role: "Product Manager", initials: "SM",
                   channelName: "nexademo-sarah", gradientStartAsset: "PremiumGradientStart", gradientEndAsset: "SuccessAccent"),
        DemoContact(id: "3", name: "David Chen", role: "Backend Engineer", initials: "DC",
                   channelName: "nexademo-david", gradientStartAsset: "PremiumGradientEnd", gradientEndAsset: "PremiumGradientStart"),
    ]
}
