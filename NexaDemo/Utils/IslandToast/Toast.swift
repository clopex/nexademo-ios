//
//  Toast.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 27. 2. 2026..
//

import SwiftUI

struct Toast {
    private(set) var id: String = UUID().uuidString
    var symbol: String
    var symbolFont: Font
    var symbolForegrgoundStyle: (Color, Color)
    
    var title: String
    var message: String
    
    static var example: Toast {
        Toast(
            symbol: "checkmark.seal.fill",
            symbolFont: .system(size: 35),
            symbolForegrgoundStyle: (.white, .green),
            title: "Hello, world!",
            message: "This is a toast message."
        )
    }
    
    static var exmaple2: Toast {
        Toast(
            symbol: "xmark.seal.fill",
            symbolFont: .system(size: 35),
            symbolForegrgoundStyle: (.white, .red),
            title: "Hello, error!",
            message: "This is a toast message."
        )
    }
}
