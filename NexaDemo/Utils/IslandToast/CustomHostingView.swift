//
//  CustomHostingView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 27. 2. 2026..
//

import SwiftUI


class CustomHostingView: UIHostingController<ToastView> {
    var isStatusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
}
