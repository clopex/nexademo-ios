//
//  VoiceCallView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 5. 3. 2026..
//

import SwiftUI

struct VoiceCallView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    let channel: String
    let contactName: String
    let contactInitials: String

    @State private var agoraService = AgoraService()
    @State private var didRecordActivity = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("PremiumGradientStart"), Color("BackgroundDark")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Contact avatar
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color("PremiumGradientEnd"), Color("PremiumGradientStart")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)

                        Text(contactInitials)
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white)

                        // Pulse animation when connected
                        if case .connected = agoraService.callState {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 140, height: 140)
                                .scaleEffect(agoraService.remoteUserJoined ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(), value: agoraService.remoteUserJoined)
                        }
                    }

                    Text(contactName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    // Call status
                    Group {
                        switch agoraService.callState {
                        case .idle:
                            Text("Initializing...")
                        case .connecting:
                            Text("Connecting...")
                        case .connected:
                            Text(agoraService.remoteUserJoined ? agoraService.formattedDuration : "Waiting for other party...")
                        case .error(let message):
                            Text(message)
                                .foregroundStyle(Color("BrandAccent"))
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Controls
                VStack(spacing: 32) {
                    HStack(spacing: 40) {
                        // Mute button
                        CallControlButton(
                            icon: agoraService.isMuted ? "mic.slash.fill" : "mic.fill",
                            label: agoraService.isMuted ? "Unmute" : "Mute",
                            isActive: agoraService.isMuted,
                            activeColor: Color("BrandAccent")
                        ) {
                            agoraService.toggleMute()
                        }

                        // End call button
                        Button {
                            agoraService.leaveChannel()
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color("BrandAccent"))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                        }

                        // Speaker button
                        CallControlButton(
                            icon: agoraService.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.slash.fill",
                            label: agoraService.isSpeakerOn ? "Speaker" : "Earpiece",
                            isActive: agoraService.isSpeakerOn,
                            activeColor: Color("SuccessAccent")
                        ) {
                            agoraService.toggleSpeaker()
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .task {
            if didRecordActivity == false, let userID = authVM.currentUser?.id {
                didRecordActivity = true
                RecentActivityStore.shared.recordCallStarted(
                    userID: userID,
                    contactName: contactName
                )
            }
            await agoraService.joinChannel(channel)
        }
        .onDisappear {
            agoraService.leaveChannel()
        }
    }
}

// MARK: - Call Control Button
struct CallControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? activeColor.opacity(0.2) : Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isActive ? activeColor : .white)
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}
