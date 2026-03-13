//
//  AIChatView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 2. 3. 2026..
//

import SwiftUI

struct AIChatView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppTabRouter.self) private var tabRouter
    @State private var viewModel = AIChatViewModel()
    @State private var speechService = SpeechService()
    @State private var messageText = ""
    @State private var didSendInitialMessage = false
    @State private var ignoresSpeechUpdates = false
    @State private var showToast = false
    @State private var toast = Toast.example
    @FocusState private var isInputFocused: Bool
    let initialMessage: String?
    
    init(initialMessage: String? = nil) {
            self.initialMessage = initialMessage
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            TypingIndicator()
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isLoading) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isInputFocused) { _, focused in
                    guard focused else { return }
                    Task {
                        try? await Task.sleep(for: .milliseconds(140))
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: messageText) { _, _ in
                    guard isInputFocused else { return }
                    scrollToBottom(proxy: proxy)
                }
                .safeAreaInset(edge: .bottom) {
                    inputBar
                }
            }
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .dynamicIslandToasts(isPresented: $showToast, value: toast)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.clearHistory() }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color("BrandAccent"))
                }
            }
        }
        .task {
            await viewModel.loadHistory()
            syncFreePlanUsage()
            guard didSendInitialMessage == false,
                  let message = initialMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
                  message.isEmpty == false else {
                return
            }

            didSendInitialMessage = true
            guard canSendAIMessage else {
                presentUpgradePaywall()
                return
            }

            let didSend = await viewModel.sendMessage(message)
            if didSend, let userID = authVM.currentUser?.id {
                FreePlanUsageStore.registerAIChatMessageSent(for: userID)
                RecentActivityStore.shared.recordAIChatMessage(userID: userID, message: message)
            }
        }
        .onChange(of: authVM.currentUser?.id) { _, _ in
            syncFreePlanUsage()
        }
        .onChange(of: speechService.transcript) { _, newValue in
            if ignoresSpeechUpdates {
                return
            }

            if !newValue.isEmpty {
                messageText = newValue
            }
        }
        .onChange(of: speechService.isRecording) { _, isRecording in
            if isRecording {
                ignoresSpeechUpdates = false
            }

            if ignoresSpeechUpdates {
                return
            }

            if !isRecording && !speechService.transcript.isEmpty {
                messageText = speechService.transcript
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            guard let message = newValue, message.isEmpty == false else { return }
            toast = Toast(
                symbol: "xmark.seal.fill",
                symbolFont: .system(size: 28),
                symbolForegrgoundStyle: (.white, .red),
                title: "AI Chat error",
                message: message
            )
            showToast = true
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField(
                    "",
                    text: $messageText,
                    prompt: Text("Message...").foregroundStyle(.white.opacity(0.7)),
                    axis: .vertical
                )
                    .lineLimit(1...4)
                    .foregroundStyle(.white)
                    .focused($isInputFocused)

                // Mic button
                Button {
                    Task { await speechService.toggle() }
                } label: {
                    Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(speechService.isRecording ? Color("BrandAccent") : .gray)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(speechService.isRecording ? Color("BrandAccent").opacity(0.15) : Color.clear)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color("CardBackground"))
            .clipShape(.rect(cornerRadius: 24))

            // Send button
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color("BrandAccent"))
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("BackgroundDark"))
    }

    // MARK: - Helpers
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard canSendAIMessage else {
            presentUpgradePaywall()
            return
        }
        let shouldSuppressSpeechUpdates = speechService.isRecording || !speechService.transcript.isEmpty
        if shouldSuppressSpeechUpdates {
            ignoresSpeechUpdates = true
        }
        speechService.stopRecording()
        speechService.transcript = ""
        messageText = ""
        isInputFocused = false
        Task {
            let didSend = await viewModel.sendMessage(text)
            if didSend, let userID = authVM.currentUser?.id {
                FreePlanUsageStore.registerAIChatMessageSent(for: userID)
                RecentActivityStore.shared.recordAIChatMessage(userID: userID, message: text)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private var isPremium: Bool {
        authVM.currentUser?.isPremium ?? false
    }

    private var canSendAIMessage: Bool {
        guard let userID = authVM.currentUser?.id else { return true }
        return FreePlanUsageStore.canSendAIChatMessage(for: userID, isPremium: isPremium)
    }

    private func syncFreePlanUsage() {
        guard let userID = authVM.currentUser?.id else { return }
        let sentMessagesCount = viewModel.messages.filter { $0.role == "user" }.count
        FreePlanUsageStore.syncAIChatMessagesSent(atLeast: sentMessagesCount, for: userID)
    }

    private func presentUpgradePaywall() {
        speechService.stopRecording()
        speechService.transcript = ""
        isInputFocused = false
        tabRouter.selectedTab = .premium
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessageModel

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(Color("PremiumGradientStart"))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("BrandAccent"))
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color("BrandAccent") : Color("CardBackground"))
                    .clipShape(.rect(cornerRadius: 18))

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color("PremiumGradientStart"))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("BrandAccent"))
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(y: animate ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color("CardBackground"))
            .clipShape(.rect(cornerRadius: 18))

            Spacer(minLength: 60)
        }
        .onAppear { animate = true }
    }
}

#Preview("Chat Screen") {
    NavigationStack {
        AIChatView()
    }
}

#Preview("Message Bubble") {
    ZStack {
        Color("BackgroundDark").ignoresSafeArea()
        MessageBubble(
            message: ChatMessageModel(
                id: UUID().uuidString,
                role: "assistant",
                content: "Hey! I am ready to help.",
                createdAt: Date()
            )
        )
        .padding()
    }
}
