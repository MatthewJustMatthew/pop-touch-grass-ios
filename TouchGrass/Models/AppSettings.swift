import Foundation
import SwiftUI

/// Observable model for app settings, backed by App Group UserDefaults.
@MainActor
class AppSettings: ObservableObject {
    private let defaults = SharedConstants.sharedDefaults

    @Published var ritualCompleted: Bool {
        didSet { defaults.set(ritualCompleted, forKey: SharedConstants.Keys.ritualCompleted) }
    }

    @Published var userIntention: String {
        didSet { defaults.set(userIntention, forKey: SharedConstants.Keys.userIntention) }
    }

    @Published var userAwareness: String {
        didSet { defaults.set(userAwareness, forKey: SharedConstants.Keys.userAwareness) }
    }

    @Published var intervalSeconds: Int {
        didSet { defaults.set(intervalSeconds, forKey: SharedConstants.Keys.intervalSeconds) }
    }

    @Published var monitoringEnabled: Bool {
        didSet { defaults.set(monitoringEnabled, forKey: SharedConstants.Keys.monitoringEnabled) }
    }

    /// Available interval options (seconds)
    static let intervalSteps = [15, 30, 45, 60, 120, 180, 240, 300, 600]

    init() {
        self.ritualCompleted = defaults.bool(forKey: SharedConstants.Keys.ritualCompleted)
        self.userIntention = defaults.string(forKey: SharedConstants.Keys.userIntention) ?? ""
        self.userAwareness = defaults.string(forKey: SharedConstants.Keys.userAwareness) ?? ""
        self.intervalSeconds = defaults.object(forKey: SharedConstants.Keys.intervalSeconds) as? Int ?? 180
        self.monitoringEnabled = defaults.bool(forKey: SharedConstants.Keys.monitoringEnabled)
    }

    /// Formatted interval string
    var intervalLabel: String {
        if intervalSeconds < 60 { return "\(intervalSeconds)s" }
        return "\(intervalSeconds / 60) min"
    }

    /// Index into intervalSteps for the current value
    var intervalStepIndex: Int {
        get {
            Self.intervalSteps.firstIndex(of: intervalSeconds) ?? 3
        }
        set {
            let clamped = min(max(newValue, 0), Self.intervalSteps.count - 1)
            intervalSeconds = Self.intervalSteps[clamped]
        }
    }
}
