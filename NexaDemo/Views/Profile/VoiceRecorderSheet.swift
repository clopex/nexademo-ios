import SwiftUI

struct VoiceRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var speechService: SpeechService
    let onSave: (String, TimeInterval) -> Void

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

                if speechService.isRecording {
                    VoiceAmplitudeView(
                        isRecording: speechService.isRecording,
                        level: speechService.audioLevel
                    )
                    .transition(
                        .asymmetric(
                            insertion: .modifier(
                                active: AmplitudeTransitionEffect(opacity: 0, scale: 0.92, y: 10, blur: 8),
                                identity: AmplitudeTransitionEffect(opacity: 1, scale: 1, y: 0, blur: 0)
                            ),
                            removal: .modifier(
                                active: AmplitudeTransitionEffect(opacity: 0, scale: 0.98, y: -6, blur: 4),
                                identity: AmplitudeTransitionEffect(opacity: 1, scale: 1, y: 0, blur: 0)
                            )
                        )
                    )
                }

                VoiceRecorderActionButton(isRecording: speechService.isRecording) {
                    Task {
                        if !hasPermission {
                            hasPermission = await speechService.requestPermissions()
                            guard hasPermission else { return }
                            await speechService.prepareForRecording()
                        }
                        await speechService.toggle()
                    }
                }

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

                Button {
                    let capturedDuration = speechService.effectiveRecordingDuration
                    onSave(editedText, capturedDuration)
                    speechService.stopRecording()
                    dismiss()
                } label: {
                    Text("Save Note")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("BrandAccent").opacity(editedText.isEmpty ? 0.3 : 1))
                        .clipShape(.rect(cornerRadius: 28))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(editedText.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.84, blendDuration: 0.16), value: speechService.isRecording)
        .task {
            hasPermission = await speechService.requestPermissions()
            if hasPermission {
                await speechService.prepareForRecording()
            }
        }
    }
}

#Preview {
    VoiceRecorderSheet(speechService: previewSpeechService) { _, _ in }
}

@MainActor
private let previewSpeechService = SpeechService()

private struct AmplitudeTransitionEffect: ViewModifier {
    let opacity: Double
    let scale: CGFloat
    let y: CGFloat
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: y)
            .blur(radius: blur)
    }
}
