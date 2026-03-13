//
//  Untitled.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 2. 3. 2026..
//

import SwiftUI
import AVFoundation

struct CameraMLView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppSheetManager.self) private var sheetManager
    let viewModel: AIStudioViewModel  // ← prima izvana
    @State private var cameraService = CameraService()
    @State private var hasPermission = false

    var body: some View {
        ZStack {
            if hasPermission {
                CameraPreviewView(cameraService: cameraService)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                // Top bar
                HStack {
                    Button {
                        Task { await cameraService.stopSession() }
                        sheetManager.dismissFullScreen()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("AI Scanner")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Live detection overlay
                if !cameraService.detectedObjects.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(cameraService.detectedObjects) { object in
                            HStack {
                                Text(object.emoji)
                                Text(object.label.capitalized)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(object.confidencePercentage)
                                    .font(.subheadline)
                                    .foregroundStyle(Color("SuccessAccent"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                // Scan button
                Button {
                    Task {
                        await cameraService.capturePhoto()
                        // Upiši rezultate u viewmodel i zatvori
                        viewModel.updateResults(
                            objects: cameraService.detectedObjects,
                            image: cameraService.capturedImage,
                            userID: authVM.currentUser?.id
                        )
                        await cameraService.stopSession()
                        sheetManager.dismissFullScreen()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 4)
                            .frame(width: 88, height: 88)
                        Image(systemName: "viewfinder")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color("BackgroundDark"))
                    }
                }
                .padding(.bottom, 48)
                .padding(.top, 24)
            }

            // No permission
            if !hasPermission {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color("BrandAccent"))
                    Text("Camera Access Required")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Please allow camera access in Settings to use AI Scanner.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color("BrandAccent"))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                }
            }
        }
        .task {
            hasPermission = await cameraService.requestPermission()
            if hasPermission {
                await cameraService.startSession()
            }
        }
        .onDisappear {
            Task { await cameraService.stopSession() }
        }
    }
}


// MARK: - Camera Preview (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        Task { @MainActor in
            let layer = await cameraService.makePreviewLayer()
            view.setPreviewLayer(layer)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

final class PreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = layer
        self.layer.insertSublayer(layer, at: 0)
        layer.frame = bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - Scan Result Sheet
struct ScanResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSheetManager.self) private var sheetManager
    let objects: [DetectedObject]
    let image: UIImage?

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Captured image
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                }

                // Results
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detected Objects")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    ForEach(objects) { object in
                        HStack(spacing: 12) {
                            Text(object.emoji)
                                .font(.title2)
                                .frame(width: 48, height: 48)
                                .background(Color("CardBackground"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(object.label.capitalized)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                // Confidence bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color("SuccessAccent"))
                                            .frame(width: geo.size.width * CGFloat(object.confidence), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }

                            Text(object.confidencePercentage)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("SuccessAccent"))
                                .frame(width: 48, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()

                // Ask AI button
                Button {
                    dismiss()
                    sheetManager.dismissFullScreen()
                    // TODO: navigate to AI Chat with context
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Ask AI About This")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("BrandAccent"))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}
