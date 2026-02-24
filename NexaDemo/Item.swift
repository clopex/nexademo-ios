//
//  Item.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 24. 2. 2026..
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
