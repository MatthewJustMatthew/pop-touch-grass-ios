import SwiftUI
import UserNotifications

@main
struct TouchGrassApp: App {
    @StateObject private var settings = AppSettings()

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
