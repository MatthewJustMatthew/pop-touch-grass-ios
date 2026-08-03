import SwiftUI

/// A bubble that can be popped over and over — used on the home screen so people
/// can get familiar with the pop sound outside of the ritual.
///
/// `RitualBubbleView` is intentionally one-shot (it guards against a second pop),
/// so respawning is done by giving it a fresh identity, which resets its state.
struct PracticeBubbleView: View {
    let size: CGFloat

    @State private var bubbleID = UUID()
    @State private var opacity: Double = 1

    var body: some View {
        RitualBubbleView(size: size) {
            respawn()
        }
        .id(bubbleID)
        .opacity(opacity)
    }

    private func respawn() {
        // onPopped fires 0.2s into the pop; the burst itself runs to ~0.56s, so
        // let it finish before swapping in a fresh bubble.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            opacity = 0
            bubbleID = UUID()
            // Commit the hidden state first so the new bubble fades in from zero.
            DispatchQueue.main.async {
                withAnimation(.easeIn(duration: 0.7)) {
                    opacity = 1
                }
            }
        }
    }
}
