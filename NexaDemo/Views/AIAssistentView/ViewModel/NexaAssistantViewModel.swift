//
//  NexaAssistantViewModel.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 6. 3. 2026..
//

// NexaAssistantViewModel.swift
import Foundation
import Observation
import SwiftData
import CoreGraphics

enum NexaState {
    case idle
    case listening
    case processing
    case error(String)
}

@Observable
@MainActor
final class NexaAssistantViewModel {
    var state: NexaState = .idle
    var transcript: String = ""
    var isVisible = false
    var audioLevel: CGFloat = 0
    var onCommandReceived: ((NexaCommand) -> Void)?

    private let speechService = SpeechService()
    private var audioLevelTask: Task<Void, Never>?
    private var lastTranscriptLength = 0
    private var lastDetectedSpeechAt: Date?
    private var isStoppingOrProcessing = false
    private let silenceLevelThreshold = 0.08
    private let autoStopSilenceDuration: TimeInterval = 1.4

    var isListening: Bool {
        if case .listening = state { return true }
        return false
    }

    func startListening() {
        transcript = ""
        lastTranscriptLength = 0
        lastDetectedSpeechAt = nil
        isStoppingOrProcessing = false
        state = .listening
        Task {
            let hasPermission = await speechService.requestPermissions()
            guard hasPermission else {
                state = .error("Microphone or speech recognition permission denied.")
                return
            }
            do {
                try await speechService.startRecording()
                startAudioLevelSimulation()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func stopAndProcess() async {
        guard !isStoppingOrProcessing else { return }
        guard case .listening = state else { return }

        isStoppingOrProcessing = true
        audioLevelTask?.cancel()
        audioLevelTask = nil
        speechService.stopRecording()
        audioLevel = 0
        transcript = await settledTranscript()

        guard !transcript.isEmpty else {
            isStoppingOrProcessing = false
            state = .idle
            return
        }

        state = .processing

        do {
            let command = try await NexaAssistantService.shared.parseCommand(transcript)
            onCommandReceived?(command)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }

        isStoppingOrProcessing = false
    }

    func reset() {
        audioLevelTask?.cancel()
        audioLevelTask = nil
        state = .idle
        transcript = ""
        audioLevel = 0
        lastTranscriptLength = 0
        lastDetectedSpeechAt = nil
        isStoppingOrProcessing = false
    }

    private func startAudioLevelSimulation() {
        audioLevelTask?.cancel()
        audioLevelTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard case .listening = state else { return }

                let current = speechService.transcript
                let currentAudioLevel = speechService.audioLevel

                transcript = current
                audioLevel = CGFloat(max(0.12, currentAudioLevel))

                if current.count > lastTranscriptLength {
                    lastTranscriptLength = current.count
                    lastDetectedSpeechAt = .now
                } else if currentAudioLevel > silenceLevelThreshold {
                    lastDetectedSpeechAt = .now
                }

                if !current.isEmpty,
                   let lastDetectedSpeechAt,
                   Date().timeIntervalSince(lastDetectedSpeechAt) >= autoStopSilenceDuration {
                    if !Task.isCancelled && !isStoppingOrProcessing {
                        Task { @MainActor [weak self] in
                            await self?.stopAndProcess()
                        }
                        return
                    }
                }
            }
        }
    }

    private func settledTranscript() async -> String {
        var latestTranscript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        var stablePasses = 0

        for _ in 0..<10 {
            try? await Task.sleep(for: .milliseconds(150))

            let currentTranscript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)

            if currentTranscript.localizedStandardContains(latestTranscript) && currentTranscript != latestTranscript {
                latestTranscript = currentTranscript
                stablePasses = 0
                continue
            }

            if currentTranscript == latestTranscript {
                stablePasses += 1
            } else {
                latestTranscript = currentTranscript
                stablePasses = 0
            }

            if stablePasses >= 2, speechService.state != .recording {
                break
            }
        }

        return latestTranscript
    }
}
