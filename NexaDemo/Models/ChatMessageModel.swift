//
//  ChatMessageModel.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 2. 3. 2026..
//

import Foundation

struct ChatMessageModel: Identifiable, Codable, Sendable {
    let id: String
    let role: String
    let content: String
    let createdAt: Date
}

struct ChatHistoryResponse: Codable, Sendable {
    let messages: [ChatMessageModel]
}

struct ChatResponse: Codable, Sendable {
    let reply: String
}
