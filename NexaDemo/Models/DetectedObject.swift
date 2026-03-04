//
//  DetectedObject.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 2. 3. 2026..
//

import Foundation

struct DetectedObject: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    
    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
    
    var emoji: String {
        // Basic emoji mapping
        let lower = label.lowercased()
        if lower.contains("dog") { return "🐕" }
        if lower.contains("cat") { return "🐈" }
        if lower.contains("car") || lower.contains("vehicle") { return "🚗" }
        if lower.contains("food") || lower.contains("pizza") || lower.contains("burger") { return "🍕" }
        if lower.contains("phone") { return "📱" }
        if lower.contains("laptop") || lower.contains("computer") { return "💻" }
        if lower.contains("book") { return "📚" }
        if lower.contains("bottle") { return "🍶" }
        if lower.contains("chair") { return "🪑" }
        if lower.contains("person") || lower.contains("human") { return "👤" }
        return "🔍"
    }
}
