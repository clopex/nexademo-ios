//
//  CameraService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 2. 3. 2026..
//

import AVFoundation
import Vision
import UIKit
import CoreML

// MARK: - Camera Error
enum CameraError: Error {
    case deviceNotAvailable
    case modelNotAvailable
}

// MARK: - Camera Session Actor
actor CameraSessionActor {
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var lastProcessedTime: TimeInterval = 0
    private let processingInterval: TimeInterval = 0.5
    private(set) var visionModel: VNCoreMLModel?

    init(visionModel: VNCoreMLModel?) {
        self.visionModel = visionModel
    }

    func configure() throws {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            session.commitConfiguration()
            throw CameraError.deviceNotAvailable
        }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        session.commitConfiguration()
    }

    func setVideoDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
    }

    func start() {
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    func shouldProcessFrame() -> Bool {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessedTime > processingInterval else { return false }
        lastProcessedTime = currentTime
        return true
    }
}

// MARK: - Camera Service
@Observable
@MainActor
final class CameraService: NSObject {

    enum CameraState: Sendable {
        case idle
        case running
        case error(String)
    }

    var state: CameraState = .idle
    var detectedObjects: [DetectedObject] = []
    var capturedImage: UIImage?

    private let sessionActor: CameraSessionActor
    private let visionQueue = DispatchQueue(label: "vision.queue", qos: .userInitiated)

    override init() {
        let config = MLModelConfiguration()
        let model = try? VNCoreMLModel(for: MobileNetV2(configuration: config).model)
        sessionActor = CameraSessionActor(visionModel: model)
        super.init()
    }

    // MARK: - Permissions
    func requestPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Session Control
    func startSession() async {
        do {
            try await sessionActor.configure()
            await sessionActor.setVideoDelegate(self, queue: visionQueue)
            await sessionActor.start()
            state = .running
        } catch {
            state = .error("Camera not available")
        }
    }

    func stopSession() async {
        await sessionActor.stop()
        state = .idle
        detectedObjects = []
    }

    // MARK: - Capture Photo
    func capturePhoto() async {
        await sessionActor.capturePhoto(delegate: self)
    }

    // MARK: - Preview Layer
    func makePreviewLayer() async -> AVCaptureVideoPreviewLayer {
        await sessionActor.makePreviewLayer()
    }

    // MARK: - Vision Processing (nonisolated — runs on visionQueue)
    private nonisolated func processFrameNonisolated(_ pixelBuffer: CVPixelBuffer, model: VNCoreMLModel) {
        let request = VNCoreMLRequest(model: model) { [weak self] request, _ in
            guard let results = request.results as? [VNClassificationObservation] else { return }

            let objects = results.prefix(3).map { observation in
                DetectedObject(
                    label: observation.identifier
                        .components(separatedBy: ",")
                        .first?
                        .trimmingCharacters(in: .whitespaces) ?? observation.identifier,
                    confidence: observation.confidence
                )
            }

            Task { @MainActor [weak self] in
                self?.detectedObjects = objects
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        try? handler.perform([request])
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task {
            guard await sessionActor.shouldProcessFrame(),
                  let model = await sessionActor.visionModel else { return }
            processFrameNonisolated(pixelBuffer, model: model)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor [weak self] in
            self?.capturedImage = image
        }
    }
}
