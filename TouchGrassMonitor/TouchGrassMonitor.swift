import DeviceActivity
import UserNotifications
import Foundation

/// DeviceActivityMonitor extension that sends notification nudges based on usage thresholds.
/// Runs in a separate process with strict ~6MB memory limit — keep logic minimal.
class TouchGrassMonitor: DeviceActivityMonitor {

    private let defaults = SharedConstants.sharedDefaults

    /// Called when the monitoring interval starts (beginning of day)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Reset daily nudge count
        defaults.set(0, forKey: SharedConstants.Keys.nudgeCount)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedConstants.Keys.lastNudgeDate)
    }

    /// Called when usage reaches a configured threshold — send the appropriate nudge
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        let level: SharedConstants.NudgeLevel
        switch event.rawValue {
        case SharedConstants.ActivityEvents.gentle:
            level = .gentle
        case SharedConstants.ActivityEvents.firm:
            level = .firm
        case SharedConstants.ActivityEvents.direct:
            level = .direct
        default:
            level = .gentle
        }

        sendNudgeNotification(level: level)
    }

    /// Called when the monitoring interval ends (end of day)
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }

    // MARK: - Notification

    /// Send a local notification with the appropriate sound and message
    private func sendNudgeNotification(level: SharedConstants.NudgeLevel) {
        let intention = defaults.string(forKey: SharedConstants.Keys.userIntention)
        let awareness = defaults.string(forKey: SharedConstants.Keys.userAwareness)

        let nudge = NudgeContent.message(for: level, intention: intention, awareness: awareness)

        let content = UNMutableNotificationContent()
        content.title = nudge.title
        content.body = nudge.body
        content.sound = UNNotificationSound(named: UNNotificationSoundName("\(nudge.sound).caf"))
        content.categoryIdentifier = SharedConstants.Notifications.categoryID
        content.interruptionLevel = .timeSensitive

        // Unique ID per level so they don't stack
        let identifier: String
        switch level {
        case .gentle: identifier = SharedConstants.Notifications.gentleNudgeID
        case .firm: identifier = SharedConstants.Notifications.firmNudgeID
        case .direct: identifier = SharedConstants.Notifications.directNudgeID
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Fire immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send nudge: \(error)")
            }
        }

        // Increment daily nudge count
        let count = defaults.integer(forKey: SharedConstants.Keys.nudgeCount)
        defaults.set(count + 1, forKey: SharedConstants.Keys.nudgeCount)
    }
}
