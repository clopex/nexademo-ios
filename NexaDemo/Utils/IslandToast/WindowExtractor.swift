//
//  WindowExtractor.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 27. 2. 2026..
//

import SwiftUI

struct WindowExtractor: UIViewRepresentable {
    var result: (UIWindow) -> ()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let window =  view.window {
                result(window)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
