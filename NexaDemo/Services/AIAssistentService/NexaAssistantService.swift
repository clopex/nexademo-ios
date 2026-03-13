//
//  NexaAssistantService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 6. 3. 2026..
//

import Foundation

struct NexaCommand: Codable, Sendable {
    let action: NexaAction
    let parameters: NexaParameters
}

enum NexaAction: String, Codable, Sendable {
    case createVoiceNote = "create_voice_note"
    case openAIChat = "open_ai_chat"
    case startFocusSession = "start_focus_session"
    case startScan = "start_scan"
    case makeCall = "make_call"
    case navigate = "navigate"
    case unknown
}

struct NexaParameters: Codable, Sendable {
    var content: String?
    var message: String?
    var contact: String?
    var tab: String?
    var title: String?
    var durationMinutes: Int?
    var preset: String?

    init(
        content: String? = nil,
        message: String? = nil,
        contact: String? = nil,
        tab: String? = nil,
        title: String? = nil,
        durationMinutes: Int? = nil,
        preset: String? = nil
    ) {
        self.content = content
        self.message = message
        self.contact = contact
        self.tab = tab
        self.title = title
        self.durationMinutes = durationMinutes
        self.preset = preset
    }
}

struct NexaAssistantService: Sendable {
    static let shared = NexaAssistantService()
    private let client = NetworkClient.shared

    func parseCommand(_ transcript: String) async throws -> NexaCommand {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

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

        if let localIntent = localIntentCommand(for: trimmedTranscript) {
            return localIntent
        }

        var request = URLRequest(url: client.url(for: "nexa/parse"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NexaError.missingToken
        }

        request.httpBody = try JSONEncoder().encode(["transcript": transcript])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let fallback = fallbackCommand(for: trimmedTranscript) {
                    return fallback
                }
                throw NexaError.serverError
            }

            print("Nexa response: \(String(data: data, encoding: .utf8) ?? "nil")")
            let command = try JSONDecoder().decode(NexaCommand.self, from: data)
            return resolvedCommand(command, transcript: trimmedTranscript)
        } catch {
            if let fallback = fallbackCommand(for: trimmedTranscript) {
                return fallback
            }
            throw error
        }
    }

    private func resolvedCommand(_ command: NexaCommand, transcript: String) -> NexaCommand {
        switch command.action {
        case .createVoiceNote:
            let content = normalized(command.parameters.content) ?? extractedVoiceNoteContent(from: transcript)
            return NexaCommand(action: .createVoiceNote, parameters: NexaParameters(content: content))
        case .openAIChat:
            let message = normalized(command.parameters.message) ?? transcript
            return NexaCommand(action: .openAIChat, parameters: NexaParameters(message: message))
        case .makeCall:
            let contact = normalized(command.parameters.contact) ?? extractedContactName(from: transcript)
            return NexaCommand(action: .makeCall, parameters: NexaParameters(contact: contact))
        case .navigate:
            if let fallback = fallbackCommand(for: transcript) {
                return fallback
            }
            return command
        case .unknown:
            return fallbackCommand(for: transcript) ?? command
        case .startFocusSession, .startScan:
            return command
        }
    }

    private func fallbackCommand(for transcript: String) -> NexaCommand? {
        localIntentCommand(for: transcript)
    }

    private func localIntentCommand(for transcript: String) -> NexaCommand? {
        if let content = extractedVoiceNoteContent(from: transcript) {
            return NexaCommand(
                action: .createVoiceNote,
                parameters: NexaParameters(content: content)
            )
        }

        if let contact = extractedContactName(from: transcript) {
            return NexaCommand(
                action: .makeCall,
                parameters: NexaParameters(contact: contact)
            )
        }

        if shouldOpenAIChat(for: transcript) {
            return NexaCommand(
                action: .openAIChat,
                parameters: NexaParameters(message: transcript)
            )
        }

        return nil
    }

    private func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmed.isEmpty == false else {
            return nil
        }
        return trimmed
    }

    private func extractedVoiceNoteContent(from transcript: String) -> String? {
        let prefixes = [
            "create a voice note",
            "create voice note",
            "make a voice note",
            "make voice note",
            "record a voice note",
            "record voice note",
            "take a voice note",
            "take voice note"
        ]

        return extractedSuffix(from: transcript, prefixes: prefixes)
    }

    private func extractedContactName(from transcript: String) -> String? {
        let prefixes = [
            "call to",
            "call"
        ]

        return extractedSuffix(from: transcript, prefixes: prefixes)
    }

    private func extractedSuffix(from transcript: String, prefixes: [String]) -> String? {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let loweredTranscript = trimmedTranscript.lowercased()

        for prefix in prefixes {
            guard loweredTranscript.hasPrefix(prefix) else { continue }
            let offset = prefix.count
            let startIndex = trimmedTranscript.index(trimmedTranscript.startIndex, offsetBy: offset)
            let suffix = trimmedTranscript[startIndex...]
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

            if suffix.isEmpty == false {
                return suffix
            }
        }

        return nil
    }

    private func shouldOpenAIChat(for transcript: String) -> Bool {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let loweredTranscript = trimmedTranscript.lowercased()

        if trimmedTranscript.hasSuffix("?") {
            return true
        }

        let informativePrefixes = [
            "can you tell me",
            "can you tell me more",
            "can you tell me more about",
            "tell me",
            "tell me about",
            "tell me more",
            "tell me more about",
            "what is",
            "what are",
            "how do",
            "how does",
            "how can",
            "why is",
            "why are",
            "who is",
            "when is",
            "where is",
            "explain",
            "help me understand",
            "can you explain",
            "ask ai"
        ]

        return informativePrefixes.contains { loweredTranscript.hasPrefix($0) }
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
