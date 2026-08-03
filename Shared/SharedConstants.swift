import Foundation

/// Constants shared across the main app and all extensions via App Group.
enum SharedConstants {
    /// App Group identifier — must match in all targets' entitlements
    static let appGroupID = "group.pop.touchgrass.2026.app"

    /// URL scheme for deep linking
    static let urlScheme = "touchgrass"

    /// UserDefaults keys (stored in App Group container)
    enum Keys {
        static let ritualCompleted = "ritual_completed"
        static let userIntention = "user_intention"
        static let userAwareness = "user_awareness"
        static let intervalSeconds = "interval_seconds"
        static let selectedApps = "selected_apps_data"
        static let monitoringEnabled = "monitoring_enabled"
        static let nudgeCount = "nudge_count_today"
        static let lastNudgeDate = "last_nudge_date"
    }

    /// Notification identifiers
    enum Notifications {
        static let gentleNudgeID = "touchgrass.nudge.gentle"
        static let firmNudgeID = "touchgrass.nudge.firm"
        static let directNudgeID = "touchgrass.nudge.direct"
        static let categoryID = "touchgrass.nudge.category"
        static let actionOpenApp = "OPEN_APP"
        static let actionDismiss = "DISMISS"
        /// Prefix for the ladder of interval-scheduled nudges.
        static let scheduledPrefix = "touchgrass.nudge.scheduled."
    }

    /// DeviceActivity event names
    enum ActivityEvents {
        static let gentle = "touchgrass.threshold.gentle"
        static let firm = "touchgrass.threshold.firm"
        static let direct = "touchgrass.threshold.direct"
    }

    /// Nudge escalation levels
    enum NudgeLevel: String, Codable {
        case gentle
        case firm
        case direct
    }

    /// Notification sound file names, including extension.
    /// Must be PCM (wav/aiff/caf) and live in the app bundle — mp3 is not a valid
    /// notification sound format, and a missing file silently falls back to the
    /// default iOS alert tone.
    enum Sounds {
        static let bubblePop = "pop_nudge.wav"
    }

    /// Shared UserDefaults suite using the App Group
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
