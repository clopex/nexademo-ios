//
//  PassThroughWindow.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 27. 2. 2026..
//

import SwiftUI

@Observable
class PassThroughWindow: UIWindow {
    
    var toast: Toast? = nil
    var isPresented: Bool = false
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else {
            return nil
        }
        
        if #available(iOS 26, *) {
            if rootView.layer.hitTest(point)?.name == nil {
                return rootView
            }
            return nil
        } else {
            if #unavailable(iOS 18) {
                return hitView == rootView ? nil : hitView
            } else {
                for subview in rootView.subviews.reversed() {
                    let pointIntSubView = subview.convert(point, to: rootView)
                    if subview.hitTest(pointIntSubView, with: event) != nil {
                        return hitView
                    }
                }
                
                return nil
            }
        }
    }
}
