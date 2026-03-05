//
//  AgoreService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 5. 3. 2026..
//

import Foundation
import AgoraRtcKit

@Observable
@MainActor
final class AgoraService: NSObject {

    enum CallState {
        case idle
        case connecting
        case connected
        case error(String)
    }

    var callState: CallState = .idle
    var isMuted = false
    var isSpeakerOn = true
    var remoteUserJoined = false
    var callDuration: TimeInterval = 0

    private var agoraKit: AgoraRtcEngineKit?
    private var callTimer: Timer?
    private let client = NetworkClient.shared
    private let appId = "f04d6ebe9bc243ecb896c2caf0c69591"

    override init() {
        super.init()
        setupAgora()
    }

    private func setupAgora() {
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit?.setChannelProfile(.communication)
    }

    // MARK: - Token
    func fetchToken(channelName: String) async throws -> (String, String) {
        let url = client.url(for: "agora/token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw AgoraServiceError.missingToken
        }

        request.httpBody = try JSONEncoder().encode(AgoraTokenRequest(channelName: channelName, uid: 0))

        let response: AgoraTokenResponse = try await client.performRequest(request)
        return (response.token, response.appId)
    }

    // MARK: - Join Channel
    func joinChannel(_ channelName: String) async {
        callState = .connecting
        do {
            let (token, _) = try await fetchToken(channelName: channelName)
            agoraKit?.enableAudio()
            let option = AgoraRtcChannelMediaOptions()
            option.clientRoleType = .broadcaster
            option.channelProfile = .communication
            agoraKit?.joinChannel(byToken: token, channelId: channelName, uid: 0, mediaOptions: option)
        } catch {
            callState = .error(error.localizedDescription)
        }
    }

    // MARK: - Leave Channel
    func leaveChannel() {
        agoraKit?.leaveChannel()
        stopTimer()
        callState = .idle
        remoteUserJoined = false
        callDuration = 0
        isMuted = false
    }

    // MARK: - Controls
    func toggleMute() {
        isMuted.toggle()
        agoraKit?.muteLocalAudioStream(isMuted)
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        agoraKit?.setEnableSpeakerphone(isSpeakerOn)
    }

    // MARK: - Timer
    private func startTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.callDuration += 1
            }
        }
    }

    private func stopTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }

    var formattedDuration: String {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Agora Delegate
extension AgoraService: AgoraRtcEngineDelegate {
    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        Task { @MainActor [weak self] in
            self?.callState = .connected
            self?.startTimer()
        }
    }

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Task { @MainActor [weak self] in
            self?.remoteUserJoined = true
        }
    }

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        Task { @MainActor [weak self] in
            self?.remoteUserJoined = false
        }
    }

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Task { @MainActor [weak self] in
            self?.callState = .error("Error: \(errorCode.rawValue)")
        }
    }
}

// MARK: - Models
struct AgoraTokenResponse: Decodable {
    let token: String
    let channelName: String
    let uid: Int
    let appId: String
}

enum AgoraServiceError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        "Missing auth token"
    }
}

struct AgoraTokenRequest: Encodable {
    let channelName: String
    let uid: Int
}
