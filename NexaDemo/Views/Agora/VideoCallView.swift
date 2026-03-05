//
//  VideoCallView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 5. 3. 2026..
//

import SwiftUI

struct VideoCallView: View {
    let channel: String

    var contact: DemoContact? {
        DemoContact.samples.first { $0.channelName == channel }
    }

    var body: some View {
        VoiceCallView(
            channel: channel,
            contactName: contact?.name ?? "Demo Contact",
            contactInitials: contact?.initials ?? "DC"
        )
    }
}
