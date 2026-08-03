import Foundation

/// Manages the pool of rotating notification messages for nudges.
/// Pulls from user intention, awareness answer, nature prompts, and usage stats.
struct NudgeContent {

    /// Generate a nudge message for the given level
    static func message(
        for level: SharedConstants.NudgeLevel,
        intention: String?,
        awareness: String?
    ) -> (title: String, body: String, sound: String) {
        switch level {
        case .gentle:
            let body = gentleMessages.randomElement() ?? "Take a breath."
            return (
                title: "Touch Grass 🌿",
                body: body,
                sound: SharedConstants.Sounds.bubblePop
            )

        case .firm:
            var pool = firmMessages
            if let awareness = awareness, !awareness.isEmpty {
                pool.append("Remember: \"\(awareness)\"")
            }
            let body = pool.randomElement() ?? "Step outside?"
            return (
                title: "Hey 👋",
                body: body,
                sound: SharedConstants.Sounds.bubblePop
            )

        case .direct:
            var body: String
            if let intention = intention, !intention.isEmpty {
                body = "Your intention: \"\(intention)\""
            } else {
                body = directMessages.randomElement() ?? "Time to go."
            }
            return (
                title: "You've been scrolling a while",
                body: body,
                sound: SharedConstants.Sounds.bubblePop
            )
        }
    }

    // MARK: - Message Pools

    private static let gentleMessages = [
        "Take a breath 🌿",
        "Look up from the screen.",
        "How are you feeling right now?",
        "Notice your breathing.",
        "A gentle nudge to be present.",
        "What do you see around you?",
        "Take a moment. Just one.",
        "Your body is here. Are you?",
    ]

    private static let firmMessages = [
        "Still scrolling? Step outside for a minute.",
        "Your future self will thank you for stopping.",
        "What were you going to do instead?",
        "The algorithm wants you to stay. Do you?",
        "30 seconds of fresh air. That's all.",
        "Is this what you wanted to be doing?",
        "Look up. What do you see?",
    ]

    private static let directMessages = [
        "It's been a while. Time to go touch some grass.",
        "You've been here long enough. Go do that thing.",
        "Close the app. Open the door.",
        "The screen will be here later. Life won't.",
        "You know what to do. Go do it.",
    ]
}
