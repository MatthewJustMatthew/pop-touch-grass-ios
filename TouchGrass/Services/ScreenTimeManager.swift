import Foundation
import FamilyControls
import DeviceActivity

/// Manages Screen Time API integration: authorization, app selection, and monitoring.
/// Simplified: sends notification nudges instead of applying shields.
@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selectedApps = FamilyActivitySelection()

    private let center = DeviceActivityCenter()
    private let defaults = SharedConstants.sharedDefaults

    enum AuthorizationStatus {
        case notDetermined, approved, denied
    }

    // MARK: - Authorization

    /// Request FamilyControls authorization (presents system prompt)
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .approved
        } catch {
            print("FamilyControls authorization failed: \(error)")
            authorizationStatus = .denied
        }
    }

    // MARK: - App Selection

    /// Save the user's app selection and persist tokens via App Group
    func saveSelection(_ selection: FamilyActivitySelection) {
        selectedApps = selection

        // Persist selection data to App Group for extensions
        if let encoded = try? JSONEncoder().encode(selection) {
            defaults.set(encoded, forKey: SharedConstants.Keys.selectedApps)
        }

        // Restart monitoring with new selection
        if defaults.bool(forKey: SharedConstants.Keys.monitoringEnabled) {
            startMonitoring()
        }
    }

    /// Load previously saved selection
    func loadSelection() {
        guard let data = defaults.data(forKey: SharedConstants.Keys.selectedApps),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        selectedApps = selection
    }

    // MARK: - Device Activity Monitoring

    /// Start monitoring with 3 escalating threshold events
    func startMonitoring() {
        let baseInterval = defaults.object(forKey: SharedConstants.Keys.intervalSeconds) as? Int ?? 180

        // Daily schedule — monitors all day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // 3 escalating thresholds
        let gentleThreshold = DateComponents(second: baseInterval)
        let firmThreshold = DateComponents(second: baseInterval * 2)
        let directThreshold = DateComponents(second: baseInterval * 4)

        let appTokens = selectedApps.applicationTokens
        let categoryTokens = selectedApps.categoryTokens

        let gentleEvent = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            threshold: gentleThreshold
        )
        let firmEvent = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            threshold: firmThreshold
        )
        let directEvent = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            threshold: directThreshold
        )

        let activityName = DeviceActivityName("touchgrass.monitoring")

        // Stop existing monitoring before restarting
        center.stopMonitoring()

        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [
                    DeviceActivityEvent.Name(SharedConstants.ActivityEvents.gentle): gentleEvent,
                    DeviceActivityEvent.Name(SharedConstants.ActivityEvents.firm): firmEvent,
                    DeviceActivityEvent.Name(SharedConstants.ActivityEvents.direct): directEvent,
                ]
            )
            defaults.set(true, forKey: SharedConstants.Keys.monitoringEnabled)
            print("Monitoring started: gentle=\(baseInterval)s, firm=\(baseInterval * 2)s, direct=\(baseInterval * 4)s")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    /// Stop all monitoring
    func stopMonitoring() {
        center.stopMonitoring()
        defaults.set(false, forKey: SharedConstants.Keys.monitoringEnabled)
    }
}
