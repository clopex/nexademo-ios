//
//  SpeechService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 28. 2. 2026..
//

import Foundation
import Speech
import AVFoundation

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
    
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isStopping = false
    private var hasGrantedPermissions = false
    private var isPrepared = false
    
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
        state = .idle
        isStopping = false
    }
}
