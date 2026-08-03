import UserNotifications
import UIKit

/// Schedules recurring nudge notifications at the user's chosen interval.
///
/// Screen-Time-driven nudges only fire once the Family Controls entitlement is granted,
/// so these are clock-based: a ladder of one-shot notifications is queued ahead of time
/// and re-armed whenever the app comes to the foreground.
///
/// Why a ladder instead of one repeating trigger: a repeating
/// `UNTimeIntervalNotificationTrigger` requires an interval of at least 60 seconds,
/// but the app offers 15/30/45s options. Individual one-shot triggers have no such
/// floor, and they also let each nudge escalate gentle → firm → direct.
final class NudgeScheduler {
    static let shared = NudgeScheduler()

    /// iOS keeps at most 64 pending local notifications per app; stay under that so
    /// nothing scheduled elsewhere gets silently dropped.
    private let maxScheduled = 56

    private init() {}

    /// Cancel any queued nudges and schedule a fresh ladder at the given interval.
    func reschedule(intervalSeconds: Int, intention: String?, awareness: String?) {
        cancelAll()

        guard intervalSeconds > 0 else { return }

        let center = UNUserNotificationCenter.current()
        let levels: [SharedConstants.NudgeLevel] = [.gentle, .gentle, .firm, .direct]

        for step in 1...maxScheduled {
            let fireAfter = TimeInterval(intervalSeconds * step)
            let level = levels[(step - 1) % levels.count]
            let nudge = NudgeContent.message(for: level, intention: intention, awareness: awareness)

            let content = UNMutableNotificationContent()
            content.title = nudge.title
            content.body = nudge.body
            content.sound = UNNotificationSound(named: UNNotificationSoundName(nudge.sound))
            content.categoryIdentifier = SharedConstants.Notifications.categoryID
            // Time sensitive so it can break through Focus modes where allowed.
            content.interruptionLevel = .timeSensitive

            let request = UNNotificationRequest(
                identifier: "\(SharedConstants.Notifications.scheduledPrefix)\(step)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: fireAfter, repeats: false)
            )
            center.add(request) { error in
                if let error = error {
                    print("NudgeScheduler: failed to schedule step \(step): \(error)")
                }
            }
        }
    }

    /// Remove every queued nudge (both pending and already delivered).
    func cancelAll() {
        let ids = (1...maxScheduled).map { "\(SharedConstants.Notifications.scheduledPrefix)\($0)" }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// How long the currently queued ladder covers, for display in the UI.
    func coverageLabel(intervalSeconds: Int) -> String {
        let totalMinutes = intervalSeconds * maxScheduled / 60
        if totalMinutes < 60 { return "next \(totalMinutes) min" }
        let hours = Double(totalMinutes) / 60
        return String(format: "next %.1f hrs", hours)
    }
}
