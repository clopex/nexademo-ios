import FamilyControls
import Foundation
import Observation

@MainActor
@Observable
final class FocusSessionStore {
    var activeSession: FocusSession?

    private(set) var persistedSelection = FamilyActivitySelection()

    private let authorizationService = FocusAuthorizationService()
    private let monitoringService = FocusMonitoringService()
    private let notificationService = FocusNotificationService()
    private let shieldService = FocusShieldService()
    private let liveActivityService = FocusSessionLiveActivityService.shared
    private let defaults = UserDefaults(suiteName: "group.com.codify.nexademo") ?? .standard
    private let storageKey = "focus_session_state"
    private var sessionTask: Task<Void, Never>?

    init() {
        restorePersistedSession()
    }

    var hasActiveSession: Bool {
        activeSession != nil
    }

    func reconcileSessionState() async {
        let persistedData = defaults.data(forKey: storageKey)

        if persistedData == nil, activeSession != nil {
            await endSession()
            return
        }

        if activeSession == nil {
            restorePersistedSession()
        }

        guard let activeSession else { return }

        guard activeSession.endsAt > .now else {
            await endSession()
            return
        }

        shieldService.apply(selection: persistedSelection)
        if activeSession.showsLiveActivity {
            await liveActivityService.update(for: activeSession)
        }
        _ = try? monitoringService.startMonitoring(session: activeSession)
        scheduleSessionTask(for: activeSession)
    }

    func requestAuthorizationIfNeeded() async throws {
        try await authorizationService.requestAuthorizationIfNeeded()
    }

    func startSession(
        proposal: FocusSessionProposal,
        selection: FamilyActivitySelection,
        shouldNotifyAtEnd: Bool,
        showsLiveActivity: Bool
    ) async throws {
        try await requestAuthorizationIfNeeded()

        guard proposal.durationMinutes > 0 else {
            throw FocusSessionError.invalidDuration
        }

        guard selectionHasTargets(selection) else {
            throw FocusSessionError.missingSelection
        }

        await endSession()

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(TimeInterval(proposal.durationMinutes * 60))
        let session = FocusSession(
            title: proposal.title,
            startedAt: startDate,
            endsAt: endDate,
            durationMinutes: proposal.durationMinutes,
            preset: proposal.preset,
            blockedItemsCount: blockedItemCount(for: selection),
            shouldNotifyAtEnd: shouldNotifyAtEnd,
            showsLiveActivity: showsLiveActivity
        )

        shieldService.apply(selection: selection)
        activeSession = session
        persistedSelection = selection
        persist(session: session, selection: selection)
        scheduleSessionTask(for: session)

        do {
            _ = try monitoringService.startMonitoring(session: session)
        } catch {
            await endSession()
            throw error
        }

        if shouldNotifyAtEnd {
            await notificationService.scheduleEndNotification(for: session)
        }

        if showsLiveActivity {
            var updatedSession = session
            updatedSession.liveActivityID = await liveActivityService.start(for: updatedSession)
            activeSession = updatedSession
            persist(session: updatedSession, selection: selection)
        }
    }

    func endSession() async {
        if let activeSession {
            await notificationService.cancelEndNotification(for: activeSession.id)
            if activeSession.showsLiveActivity {
                await liveActivityService.end(for: activeSession)
            }
        }
        sessionTask?.cancel()
        sessionTask = nil
        monitoringService.stopMonitoring()
        shieldService.clear()
        activeSession = nil
        persistedSelection = FamilyActivitySelection()
        defaults.removeObject(forKey: storageKey)
    }

    private func restorePersistedSession() {
        guard let data = defaults.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedFocusSession.self, from: data) else {
            return
        }

        guard state.session.endsAt > .now else {
            defaults.removeObject(forKey: storageKey)
            shieldService.clear()
            return
        }

        activeSession = state.session
        persistedSelection = state.selection
        shieldService.apply(selection: state.selection)
        if state.session.showsLiveActivity {
            Task { @MainActor in
                await liveActivityService.update(for: state.session)
            }
        }
        _ = try? monitoringService.startMonitoring(session: state.session)
        scheduleSessionTask(for: state.session)
    }

    private func persist(session: FocusSession, selection: FamilyActivitySelection) {
        let state = PersistedFocusSession(session: session, selection: selection)
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func scheduleSessionTask(for session: FocusSession) {
        sessionTask?.cancel()
        sessionTask = Task { [weak self] in
            let remainingInterval = max(0, session.endsAt.timeIntervalSinceNow)
            try? await Task.sleep(for: .seconds(remainingInterval))
            guard !Task.isCancelled else { return }
            await self?.endSession()
        }
    }

    private func blockedItemCount(for selection: FamilyActivitySelection) -> Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    private func selectionHasTargets(_ selection: FamilyActivitySelection) -> Bool {
        blockedItemCount(for: selection) > 0
    }
}

private struct PersistedFocusSession: Codable {
    let session: FocusSession
    let selection: FamilyActivitySelection
}
