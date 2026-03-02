import SwiftUI

struct VoiceRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var speechService: SpeechService
    let onSave: (String) -> Void

    @State private var hasPermission = false
    @State private var editedText = ""

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 32) {
                Color.gray.opacity(0.4)
                    .frame(width: 40, height: 4)
                    .clipShape(.rect(cornerRadius: 3))
                    .padding(.top, 12)

                Text("Voice Note")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.black)

                ZStack(alignment: .topLeading) {
                    Color("CardBackground")
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(.rect(cornerRadius: 16))

                    if editedText.isEmpty && !speechService.isRecording {
                        Text("Tap the mic to start recording...")
                            .foregroundStyle(.gray)
                            .padding(16)
                    }

                    TextEditor(text: $editedText)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(height: 180)
                }
                .padding(.horizontal, 24)
                .onChange(of: speechService.transcript) { _, newValue in
                    editedText = newValue
                }

                Button(
                    speechService.isRecording ? "Stop recording" : "Start recording",
                    systemImage: speechService.isRecording ? "stop.fill" : "mic.fill"
                ) {
                    Task {
                        if !hasPermission {
                            hasPermission = await speechService.requestPermissions()
                            guard hasPermission else { return }
                        }
                        await speechService.toggle()
                    }
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 100, height: 100)
                .background {
                    ZStack {
                        if speechService.isRecording {
                            Color("BrandAccent")
                                .opacity(0.3)
                                .frame(width: 100, height: 100)
                                .clipShape(.circle)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: speechService.isRecording)
                        }

                        Color(speechService.isRecording ? "BrandAccent" : "CardBackground")
                            .frame(width: 80, height: 80)
                            .clipShape(.circle)
                    }
                }
                .buttonStyle(.plain)

                if !hasPermission {
                    Text("Microphone permission is required to record.")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                } else {
                    Text(speechService.isRecording ? "Recording... tap to stop" : "Tap to record")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                if case .error(let message) = speechService.state {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                Button("Save Note") {
                    onSave(editedText)
                    speechService.stopRecording()
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(.rect)
                .background(Color("BrandAccent").opacity(editedText.isEmpty ? 0.3 : 1))
                .clipShape(.rect(cornerRadius: 28))
                .buttonStyle(.plain)
                .disabled(editedText.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            hasPermission = await speechService.requestPermissions()
        }
    }
}

#Preview {
    VoiceRecorderSheet(speechService: previewSpeechService) { _ in }
}

@MainActor
private let previewSpeechService = SpeechService()
