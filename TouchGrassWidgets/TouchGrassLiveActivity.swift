import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity attributes for the Dynamic Island timer
struct TouchGrassAttributes: ActivityAttributes {
    /// Dynamic content that updates
    struct ContentState: Codable, Hashable {
        var elapsedMinutes: Int
        var intention: String
    }

    /// Static content set at start
    var appName: String
}

/// Widget bundle containing the Live Activity
@main
struct TouchGrassWidgetBundle: WidgetBundle {
    var body: some Widget {
        TouchGrassLiveActivity()
    }
}

/// Live Activity widget for Dynamic Island — shows scrolling timer
struct TouchGrassLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TouchGrassAttributes.self) { context in
            // Lock Screen / StandBy banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.elapsedMinutes) min")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.intention.isEmpty {
                        Text("\"\(context.state.intention)\"")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Scrolling...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            } compactLeading: {
                // Compact pill — left side
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.caption2)
            } compactTrailing: {
                // Compact pill — right side
                Text("\(context.state.elapsedMinutes)m")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
            } minimal: {
                // Minimal (when competing with other activities)
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.caption2)
            }
        }
    }

    /// Lock Screen / StandBy banner view
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<TouchGrassAttributes>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .foregroundColor(.green)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Scrolling for \(context.state.elapsedMinutes) min")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if !context.state.intention.isEmpty {
                    Text(context.state.intention)
                        .font(.system(size: 13, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("\(context.state.elapsedMinutes)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
        }
        .padding(16)
        .background(Color(red: 0.06, green: 0.03, blue: 0.10))
    }
}
