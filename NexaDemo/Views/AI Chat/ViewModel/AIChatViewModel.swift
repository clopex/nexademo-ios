//
//  AIChatViewModel.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 2. 3. 2026..
//

import Foundation
import Observation

@Observable
@MainActor
final class AIChatViewModel {
    var messages: [ChatMessageModel] = []
    var isLoading = false
    var errorMessage: String?
    
    
    func loadHistory() async {
        do {
            messages = try await AIChatService.shared.getChatHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessageModel(
            id: UUID().uuidString,
            role: "user",
            content: text,
            createdAt: Date()
        )
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil
        
        do {
            let reply = try await AIChatService.shared.sendChatMessage(text)
            let assistantMessage = ChatMessageModel(
                id: UUID().uuidString,
                role: "assistant",
                content: reply,
                createdAt: Date()
            )
            messages.append(assistantMessage)
        } catch {
            errorMessage = error.localizedDescription
            if messages.last?.role == "user" {
                messages.removeLast()
            }
        }
        
        isLoading = false
    }
    
    func clearHistory() async {
        do {
            try await AIChatService.shared.clearChatHistory()
            messages.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
