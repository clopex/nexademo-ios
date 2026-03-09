//
//  NexaAssistantService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 6. 3. 2026..
//

import Foundation

struct NexaCommand: Codable {
    let action: NexaAction
    let parameters: NexaParameters
}

enum NexaAction: String, Codable {
    case createVoiceNote = "create_voice_note"
    case openAIChat = "open_ai_chat"
    case startFocusSession = "start_focus_session"
    case startScan = "start_scan"
    case makeCall = "make_call"
    case navigate = "navigate"
    case unknown
}

struct NexaParameters: Codable {
    var content: String?
    var message: String?
    var contact: String?
    var tab: String?
    var title: String?
    var durationMinutes: Int?
    var preset: String?
}

struct NexaAssistantService: Sendable {
    static let shared = NexaAssistantService()

    private let groqURL = "https://api.groq.com/openai/v1/chat/completions"
    private let apiKey = "tvoj_groq_api_key"

    private let systemPrompt = """
    You are Nexa, a voice assistant inside NexaDemo app.
    Parse user voice commands and return ONLY valid JSON, no explanation, no markdown.

    Supported actions:
    - create_voice_note: { "action": "create_voice_note", "parameters": { "content": "note text" } }
    - open_ai_chat: { "action": "open_ai_chat", "parameters": { "message": "initial message" } }
    - start_focus_session: { "action": "start_focus_session", "parameters": { "title": "Study Focus", "durationMinutes": 40, "preset": "study" } }
    - start_scan: { "action": "start_scan", "parameters": {} }
    - make_call: { "action": "make_call", "parameters": { "contact": "contact name" } }
    - navigate: { "action": "navigate", "parameters": { "tab": "home|ai|premium|connect|profile" } }
    - unknown: { "action": "unknown", "parameters": {} }

    Examples:
    "Create a voice note reminder to call doctor tomorrow" -> { "action": "create_voice_note", "parameters": { "content": "Reminder to call doctor tomorrow" } }
    "Open AI chat and ask about SwiftUI" -> { "action": "open_ai_chat", "parameters": { "message": "Tell me about SwiftUI" } }
    "I need to study for 40 minutes" -> { "action": "start_focus_session", "parameters": { "title": "Study Focus", "durationMinutes": 40, "preset": "study" } }
    "Scan something" -> { "action": "start_scan", "parameters": {} }
    "Call Alex" -> { "action": "make_call", "parameters": { "contact": "Alex" } }
    "Go to profile" -> { "action": "navigate", "parameters": { "tab": "profile" } }
    """

    func parseCommand(_ transcript: String) async throws -> NexaCommand {
        if let proposal = FocusAIParserService().proposal(for: transcript) {
            return NexaCommand(
                action: .startFocusSession,
                parameters: NexaParameters(
                    title: proposal.title,
                    durationMinutes: proposal.durationMinutes,
                    preset: proposal.preset.rawValue
                )
            )
        }

        var request = URLRequest(url: URL(string: "https:// nexademo-backend-production.up.railway.app/api/nexa/parse")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NexaError.missingToken
        }

        request.httpBody = try JSONEncoder().encode(["transcript": transcript])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NexaError.serverError
        }

        print("Nexa response: \(String(data: data, encoding: .utf8) ?? "nil")")
        return try JSONDecoder().decode(NexaCommand.self, from: data)
    }
}

enum NexaError: LocalizedError {
    case emptyResponse
    case invalidJSON
    case missingToken
    case serverError

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "Nexa didn't respond"
        case .invalidJSON: return "Couldn't understand the command"
        case .missingToken: return "Not authenticated"
        case .serverError: return "Server error"
        }
    }
}

private struct GroqResponse: Decodable {
    let choices: [GroqChoice]
}

private struct GroqChoice: Decodable {
    let message: GroqMessage
}

private struct GroqMessage: Decodable {
    let content: String?
}
