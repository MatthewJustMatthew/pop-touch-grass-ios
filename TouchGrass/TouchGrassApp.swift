import SwiftUI
import UserNotifications
import UIKit

@main
struct TouchGrassApp: App {
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if !settings.ritualCompleted {
                    OnboardingView()
                } else {
                    HomeView()
                }
            }
            .environmentObject(settings)
            .onAppear {
                requestNotificationPermission()
                registerNotificationCategory()
                UNUserNotificationCenter.current().delegate = NudgeNotificationDelegate.shared
            }
            .onChange(of: scenePhase) { phase in
                // The scheduled ladder is finite, so top it back up every time the
                // app is opened rather than letting nudges quietly run out.
                guard phase == .active, settings.monitoringEnabled else { return }
                NudgeScheduler.shared.reschedule(
                    intervalSeconds: settings.intervalSeconds,
                    intention: settings.userIntention,
                    awareness: settings.userAwareness
                )
            }
        }
    }

    /// Request notification permission for nudge banners
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// Register notification actions ("Open Touch Grass" / "Dismiss")
    private func registerNotificationCategory() {
        let openAction = UNNotificationAction(
            identifier: SharedConstants.Notifications.actionOpenApp,
            title: "Open Touch Grass 🌿",
            options: .foreground
        )
        let dismissAction = UNNotificationAction(
            identifier: SharedConstants.Notifications.actionDismiss,
            title: "Dismiss",
            options: .destructive
        )
        let category = UNNotificationCategory(
            identifier: SharedConstants.Notifications.categoryID,
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

/// Presents nudges even while the app is open, and buzzes when one lands.
final class NudgeNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NudgeNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
