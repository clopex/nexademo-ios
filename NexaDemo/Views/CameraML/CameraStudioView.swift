//
//  CameraStudioView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 3. 3. 2026..
//

import SwiftUI

struct CameraStudioView: View {
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(AIRouter.self) private var router
    @State private var viewModel = AIStudioViewModel()

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("BrandAccent"))
                        Text("AI Studio")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Point your camera at any object to identify it instantly")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 32)

                    // Scan button
                    Button {
                        sheetManager.presentFullScreen(.camera(viewModel))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Start Scan")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("BrandAccent"))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(.horizontal, 20)

                    // Last Scan Results
                    if viewModel.hasResults {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Last Scan")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Button {
                                    viewModel.clearResults()
                                } label: {
                                    Text("Clear")
                                        .font(.subheadline)
                                        .foregroundStyle(Color("BrandAccent"))
                                }
                            }
                            .padding(.horizontal, 20)

                            // Captured image
                            if let image = viewModel.capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal, 20)
                            }

                            // Detected objects
                            VStack(spacing: 10) {
                                ForEach(viewModel.detectedObjects) { object in
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

                            // Ask AI button
                            Button {
                                let topObject = viewModel.detectedObjects.first
                                let message = "I just scanned an object with AI camera. The top result is: \(topObject?.label.capitalized ?? "unknown object") with \(topObject?.confidencePercentage ?? "0%") confidence. Can you tell me more about it?"
                                router.push(.chat(message))
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Ask AI About This")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color("PremiumGradientEnd"))
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                            }
                            .padding(.horizontal, 20)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(duration: 0.4), value: viewModel.hasResults)
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("AI Studio")
        .navigationBarTitleDisplayMode(.inline)
    }
}
