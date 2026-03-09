//
//  AIAssistentViews.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 6. 3. 2026..
//

import SwiftUI
import SwiftData

// MARK: - Floating Button
struct NexaFloatingButton: View {
    @Binding var isPresented: Bool
    @State private var isPulsing = false
    @State private var rotation: Double = 0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isPresented = true
            }
        } label: {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("BrandAccent").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: isPulsing)

                // Inner rotating ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            colors: [Color("BrandAccent"), Color("PremiumGradientEnd"), Color.clear],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: rotation)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("CardBackground"), Color("PremiumGradientStart")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: Color("BrandAccent").opacity(0.4), radius: 12, x: 0, y: 4)

                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("BrandAccent"), Color("SuccessAccent")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            isPulsing = true
            rotation = 360
        }
    }
}

// MARK: - Nexa Overlay
struct NexaAssistantView: View {
    @Binding var isPresented: Bool
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(AppTabRouter.self) private var tabRouter
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NexaAssistantViewModel()
    @State private var bars: [CGFloat] = Array(repeating: 0.3, count: 20)

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    if case .idle = viewModel.state { dismiss() }
                    if case .error = viewModel.state { dismiss() }
                }

            VStack(spacing: 0) {
                Spacer()

                // Main content card
                VStack(spacing: 28) {

                    // State-dependent UI
                    switch viewModel.state {
                    case .idle:
                        idleContent
                    case .listening:
                        listeningContent
                    case .processing:
                        processingContent
                    case .error(let msg):
                        errorContent(msg)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color("BackgroundDark"))
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [Color("BrandAccent").opacity(0.4), Color("PremiumGradientEnd").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onAppear {
            viewModel.onCommandReceived = { command in
                executeCommand(command)
            }
        }
    }

    // MARK: - Idle
    private var idleContent: some View {
        VStack(spacing: 20) {
            nexaIcon(size: 72, iconSize: 30)

            VStack(spacing: 8) {
                Text("Hey Nexa")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Tap the mic and tell me what to do")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            // Examples
            VStack(spacing: 8) {
                exampleChip("🎤 Create a voice note")
                exampleChip("🤖 Ask AI about SwiftUI")
                exampleChip("🧠 Start a 40 minute study focus")
                exampleChip("📞 Call Alex")
            }

            micButton(action: { viewModel.startListening() })
        }
    }

    // MARK: - Listening
    private var listeningContent: some View {
        VStack(spacing: 24) {
            // Waveform visualizer
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { i in
                    WaveBar(
                        height: viewModel.audioLevel,
                        index: i,
                        isActive: true
                    )
                }
            }
            .frame(height: 60)
            .padding(.horizontal, 8)

            VStack(spacing: 8) {
                    Text("Listening...")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                if !viewModel.transcript.isEmpty {
                    Text(viewModel.transcript)
                        .font(.subheadline)
                        .foregroundStyle(Color("SuccessAccent"))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 8)
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.transcript)
                }
            }

            // Stop button
            Button {
                Task { await viewModel.stopAndProcess() }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color("BrandAccent"))
                        .frame(width: 72, height: 72)
                        .shadow(color: Color("BrandAccent").opacity(0.5), radius: 16)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Processing
    private var processingContent: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color("BrandAccent").opacity(0.3 - Double(i) * 0.08), lineWidth: 1.5)
                        .frame(width: CGFloat(60 + i * 20), height: CGFloat(60 + i * 20))
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever()
                            .delay(Double(i) * 0.3),
                            value: true
                        )
                }
                nexaIcon(size: 60, iconSize: 24)
            }

            VStack(spacing: 8) {
                Text("Processing...")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(viewModel.transcript)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Success
    private func successContent(_ command: NexaCommand) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color("SuccessAccent").opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color("SuccessAccent"))
            }

            VStack(spacing: 8) {
                Text(command.action.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(command.action.description(for: command.parameters))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("CardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                Button {
                    executeCommand(command)
                } label: {
                    Text("Execute")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("BrandAccent"))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Error
    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 30))
                    .foregroundStyle(.red)
            }

            VStack(spacing: 8) {
                Text("Couldn't understand")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }

            micButton(action: {
                viewModel.reset()
                viewModel.startListening()
            }, label: "Try Again")
        }
    }

    // MARK: - Execute Command
    private func executeCommand(_ command: NexaCommand) {
        dismiss()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))

            switch command.action {
            case .createVoiceNote:
                if let content = command.parameters.content {
                    let note = VoiceNote(text: content)
                    modelContext.insert(note)
                    try? modelContext.save()
                    tabRouter.selectedTab = .profile
                }

            case .openAIChat:
                tabRouter.selectedTab = .ai
                if let message = command.parameters.message {
                    NotificationCenter.default.post(
                        name: .nexaOpenAIChat,
                        object: message
                    )
                }

            case .startFocusSession:
                let preset = FocusPreset(rawValue: command.parameters.preset ?? "") ?? .deepWork
                let proposal = FocusSessionProposal(
                    title: command.parameters.title ?? preset.title,
                    durationMinutes: command.parameters.durationMinutes ?? 25,
                    preset: preset,
                    suggestedCategories: preset.suggestedBlocks,
                    shouldSuggestEndReminder: true
                )
                tabRouter.openHome(.focusSession(proposal))

            case .startScan:
                tabRouter.selectedTab = .ai

            case .makeCall:
                if let contactName = command.parameters.contact {
                    let contact = DemoContact.samples.first {
                        $0.name.lowercased().contains(contactName.lowercased())
                    }
                    if let contact {
                        tabRouter.selectedTab = .connect
                        sheetManager.presentFullScreen(.videoCall(contact.channelName))
                    }
                }

            case .navigate:
                if let tab = command.parameters.tab {
                    switch tab {
                    case "home": tabRouter.selectedTab = .home
                    case "ai": tabRouter.selectedTab = .ai
                    case "premium": tabRouter.selectedTab = .premium
                    case "connect": tabRouter.selectedTab = .connect
                    case "profile": tabRouter.selectedTab = .profile
                    default: break
                    }
                }

            case .unknown:
                break
            }
        }
    }

    // MARK: - Helpers
    private func dismiss() {
        withAnimation(.spring(response: 0.3)) {
            isPresented = false
        }
        viewModel.reset()
    }

    private func nexaIcon(size: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("BrandAccent"), Color("PremiumGradientEnd")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color("BrandAccent").opacity(0.4), radius: 12)

            Image(systemName: "sparkles")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func micButton(action: @escaping () -> Void, label: String = "Tap to Speak") -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color("BrandAccent"))
                        .frame(width: 72, height: 72)
                        .shadow(color: Color("BrandAccent").opacity(0.5), radius: 16)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(.plain)
    }

    private func exampleChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color("CardBackground"))
            .clipShape(Capsule())
    }
}

// MARK: - Wave Bar
struct WaveBar: View {
    let height: CGFloat
    let index: Int
    let isActive: Bool

    @State private var animatedHeight: CGFloat = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [Color("BrandAccent"), Color("PremiumGradientEnd")],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: max(8, animatedHeight * 50))
            .animation(
                .easeInOut(duration: Double.random(in: 0.15...0.35))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.04),
                value: animatedHeight
            )
            .onAppear {
                animatedHeight = CGFloat.random(in: 0.3...1.0)
            }
            .onChange(of: height) { _, newValue in
                animatedHeight = newValue + CGFloat.random(in: -0.2...0.2)
            }
    }
}

// MARK: - NexaAction extensions
extension NexaAction {
    var displayName: String {
        switch self {
        case .createVoiceNote: return "Creating Voice Note"
        case .openAIChat: return "Opening AI Chat"
        case .startFocusSession: return "Preparing Focus Session"
        case .startScan: return "Starting AI Scanner"
        case .makeCall: return "Making a Call"
        case .navigate: return "Navigating"
        case .unknown: return "Unknown Command"
        }
    }

    func description(for params: NexaParameters) -> String {
        switch self {
        case .createVoiceNote: return params.content ?? "New note"
        case .openAIChat: return params.message ?? "Open chat"
        case .startFocusSession:
            let title = params.title ?? "Focus Session"
            let duration = params.durationMinutes ?? 25
            return "\(title) for \(duration) minutes"
        case .startScan: return "Opening AI camera"
        case .makeCall: return "Calling \(params.contact ?? "contact")"
        case .navigate: return "Go to \(params.tab ?? "tab")"
        case .unknown: return "Couldn't parse command"
        }
    }
}

extension Notification.Name {
    static let nexaOpenAIChat = Notification.Name("nexaOpenAIChat")
}
