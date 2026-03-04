//
//  SpeechService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 28. 2. 2026..
//

import Foundation
import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechService {
    
    enum RecognitionState: Equatable {
        case idle
        case recording
        case processing
        case error(String)
    }
    
    var transcript = ""
    var state: RecognitionState = .idle
    var isRecording: Bool { state == .recording }
    var audioLevel: Double = 0
    var recordingDuration: TimeInterval = 0
    var effectiveRecordingDuration: TimeInterval {
        if let recordingStartedAt, isRecording {
            return Date().timeIntervalSince(recordingStartedAt)
        }
        return recordingDuration
    }
    
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isStopping = false
    private var hasGrantedPermissions = false
    private var isPrepared = false
    private var recordingStartedAt: Date?
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    // MARK: - Permissions
    func requestPermissions() async -> Bool {
        if hasGrantedPermissions {
            return true
        }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            state = .error("Speech recognition permission denied.")
            return false
        }

        let microphoneGranted = await AVAudioApplication.requestRecordPermission()

        if !microphoneGranted {
            state = .error("Microphone permission denied.")
        }

        hasGrantedPermissions = microphoneGranted
        return microphoneGranted
    }

    func prepareForRecording() async {
        guard hasGrantedPermissions, !isPrepared else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            isPrepared = true
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Start Recording
    func startRecording() async throws {
        guard let recognizer, recognizer.isAvailable else {
            state = .error("Speech recognizer not available")
            return
        }
        
        transcript = ""
        state = .recording
        audioLevel = 0
        recordingDuration = 0
        recordingStartedAt = Date()
        isStopping = false
        await Task.yield()
        
        let session = AVAudioSession.sharedInstance()
        if !isPrepared {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            isPrepared = true
        }
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            guard let channelData = buffer.floatChannelData?[0] else { return }

            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }

            var sum: Float = 0
            for index in 0..<frameCount {
                let sample = channelData[index]
                sum += sample * sample
            }

            let rms = sqrt(sum / Float(frameCount))
            let db = 20 * log10(max(rms, 0.000_01))
            let mapped = (Double(db) + 50.0) / 50.0
            let normalized = min(1.0, max(0, mapped))
            let gated = normalized < 0.08 ? 0 : normalized

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioLevel = (self.audioLevel * 0.55) + (gated * 0.45)
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.finishRecognition()
                }
            }
        }
    }
    
    // MARK: - Stop Recording
    func stopRecording() {
        guard audioEngine.isRunning else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        if let recordingStartedAt {
            recordingDuration = Date().timeIntervalSince(recordingStartedAt)
        }
        self.recordingStartedAt = nil
        audioLevel = 0
        state = .processing
        isStopping = true
    }
    
    // MARK: - Toggle
    func toggle() async {
        if isRecording {
            stopRecording()
        } else {
            do {
                try await startRecording()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func finishRecognition() {
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        recordingStartedAt = nil
        audioLevel = 0
        state = .idle
        isStopping = false
    }
}
