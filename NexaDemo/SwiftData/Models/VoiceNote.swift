//
//  VoiceNote.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 28. 2. 2026..
//

import Foundation
import SwiftData

@Model
final class VoiceNote {
    var id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
