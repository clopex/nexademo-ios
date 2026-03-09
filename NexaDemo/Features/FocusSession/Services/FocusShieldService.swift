import FamilyControls
import Foundation
import ManagedSettings

struct FocusShieldService: Sendable {
    private let store = ManagedSettingsStore(named: .init("FocusSession"))

    func apply(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    func clear() {
        store.clearAllSettings()
    }
}
