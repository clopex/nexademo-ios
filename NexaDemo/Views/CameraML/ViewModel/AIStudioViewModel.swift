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
    var aiScansToday = AIScanAttemptStore.shared.todayCount()
    let freeScanLimit = 5
    var hasResults: Bool { !detectedObjects.isEmpty }

    func updateResults(objects: [DetectedObject], image: UIImage?, userID: String?) {
        let newCount = AIScanAttemptStore.shared.registerScanAttempt()
        detectedObjects = objects
        capturedImage = image
        aiScansToday = newCount
        WidgetDataService.shared.updateAIScanUsage(todayCount: newCount, freeLimit: freeScanLimit)
        if let userID {
            RecentActivityStore.shared.recordAIScan(userID: userID, objects: objects)
        }
    }

    func clearResults() {
        detectedObjects = []
        capturedImage = nil
    }

    func refreshDailyUsage() {
        aiScansToday = AIScanAttemptStore.shared.todayCount()
    }
}
