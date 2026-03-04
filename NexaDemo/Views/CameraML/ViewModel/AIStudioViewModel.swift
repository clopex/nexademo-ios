//
//  AIStudioViewModel.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 3. 3. 2026..
//

import SwiftUI
import UIKit

@Observable
@MainActor
final class AIStudioViewModel {
    var detectedObjects: [DetectedObject] = []
    var capturedImage: UIImage?
    var hasResults: Bool { !detectedObjects.isEmpty }

    func updateResults(objects: [DetectedObject], image: UIImage?) {
        detectedObjects = objects
        capturedImage = image
    }

    func clearResults() {
        detectedObjects = []
        capturedImage = nil
    }
}
