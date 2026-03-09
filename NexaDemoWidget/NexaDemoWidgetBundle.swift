//
//  NexaDemoWidgetBundle.swift
//  NexaDemoWidget
//
//  Created by Adis Mulabdic on 3. 3. 2026..
//

import WidgetKit
import SwiftUI

@main
struct NexaDemoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NexaDemoWidget()
        NexaDemoWidgetControl()
        NexaDemoWidgetLiveActivity()
        NexaDemoFocusSessionLiveActivity()
    }
}
