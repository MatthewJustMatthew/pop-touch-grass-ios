import SwiftUI

/// Direct SwiftUI port of Android's CandleFlameView:
/// layered animated teardrop flame (glow, outer/mid/inner, blue-white core)
/// with organic sway and a fadeOut for blowing it out.
struct CandleFlameView: View {
    @Binding var brightness: Double

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard brightness > 0 else { return }
                let t = timeline.date.timeIntervalSince(startDate)
                let w = size.width
                let h = size.height
                let cx = w / 2
                let baseY = h * 0.85

                // Gentle sway — slow, organic
                let sway1 = noise(t * 1.2, seed: 0) * w * 0.025
                let sway2 = noise(t * 1.5, seed: 2) * w * 0.018
                let sway3 = noise(t * 1.0, seed: 5) * w * 0.012

                // Height flicker — subtle breathing
                let breathe = 1 + noise(t * 0.8, seed: 10) * 0.06

                // Ambient glow
                let ga = 0.2 * brightness
                context.fill(
                    Circle().path(in: CGRect(x: cx - w * 0.6, y: baseY - h * 0.25 - w * 0.6,
                                             width: w * 1.2, height: w * 1.2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 1, green: 0.59, blue: 0.12).opacity(ga * 0.7), location: 0),
                            .init(color: Color(red: 1, green: 0.31, blue: 0).opacity(ga * 0.25), location: 0.35),
                            .init(color: .clear, location: 1),
                        ]),
                        center: CGPoint(x: cx, y: baseY - h * 0.25),
                        startRadius: 0,
                        endRadius: w * 0.6
                    )
                )

                // Outer flame (deep red/orange, widest)
                let outerH = h * 0.65 * breathe
                let outerW = w * 0.30
                context.fill(
                    flamePath(cx: cx + sway1, baseY: baseY, halfW: outerW, h: outerH, tipNarrow: 0.22, t: t),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(red: 0.67, green: 0.21, blue: 0.06).opacity(0.5 * brightness), location: 0.15),
                            .init(color: Color(red: 0.80, green: 0.35, blue: 0.08).opacity(0.75 * brightness), location: 0.55),
                            .init(color: Color(red: 0.87, green: 0.47, blue: 0.13).opacity(0.65 * brightness), location: 1),
                        ]),
                        startPoint: CGPoint(x: cx, y: baseY - outerH),
                        endPoint: CGPoint(x: cx, y: baseY)
                    )
                )

                // Mid flame (orange/yellow)
                let midH = h * 0.55 * breathe
                let midW = w * 0.20
                context.fill(
                    flamePath(cx: cx + sway2, baseY: baseY, halfW: midW, h: midH, tipNarrow: 0.2, t: t),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(red: 0.80, green: 0.40, blue: 0.09).opacity(0.6 * brightness), location: 0.12),
                            .init(color: Color(red: 0.87, green: 0.63, blue: 0.19).opacity(0.85 * brightness), location: 0.5),
                            .init(color: Color(red: 0.87, green: 0.72, blue: 0.28).opacity(0.9 * brightness), location: 1),
                        ]),
                        startPoint: CGPoint(x: cx, y: baseY - midH),
                        endPoint: CGPoint(x: cx, y: baseY)
                    )
                )

                // Inner flame (bright yellow/white)
                let innerH = h * 0.4 * breathe
                let innerW = w * 0.12
                context.fill(
                    flamePath(cx: cx + sway3, baseY: baseY, halfW: innerW, h: innerH, tipNarrow: 0.18, t: t),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(red: 0.87, green: 0.72, blue: 0.28).opacity(0.7 * brightness), location: 0.1),
                            .init(color: Color(red: 0.87, green: 0.80, blue: 0.44).opacity(0.9 * brightness), location: 0.45),
                            .init(color: Color(red: 0.93, green: 0.87, blue: 0.63).opacity(0.95 * brightness), location: 1),
                        ]),
                        startPoint: CGPoint(x: cx, y: baseY - innerH),
                        endPoint: CGPoint(x: cx, y: baseY)
                    )
                )

                // Blue-white core at base
                let coreW = w * 0.06
                let coreH = h * 0.08
                let coreA = brightness * 0.78
                context.fill(
                    Ellipse().path(in: CGRect(x: cx - coreW + sway3 * 0.3, y: baseY - coreH,
                                              width: coreW * 2, height: coreH * 1.15)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 0.78, green: 0.86, blue: 1).opacity(coreA), location: 0),
                            .init(color: Color(red: 1, green: 0.94, blue: 0.78).opacity(coreA * 0.5), location: 0.4),
                            .init(color: .clear, location: 1),
                        ]),
                        center: CGPoint(x: cx + sway3 * 0.3, y: baseY - coreH * 0.4),
                        startRadius: 0,
                        endRadius: coreW * 1.5
                    )
                )
            }
        }
    }

    /// Smooth multi-octave noise — same formula as Android
    private func noise(_ t: Double, seed: Double) -> Double {
        sin(t * 1.7 + seed) * 0.5 +
        sin(t * 3.1 + seed * 2.3) * 0.3 +
        sin(t * 5.3 + seed * 0.7) * 0.2
    }

    /// Smooth teardrop flame shape — same bezier structure as Android
    private func flamePath(cx: CGFloat, baseY: CGFloat, halfW: CGFloat, h: CGFloat,
                           tipNarrow: CGFloat, t: Double) -> Path {
        let tipY = baseY - h
        let tipSway = CGFloat(noise(t * 2 + Double(cx) * 0.1, seed: 3)) * halfW * 0.3

        var path = Path()
        path.move(to: CGPoint(x: cx + tipSway, y: tipY))
        path.addCurve(
            to: CGPoint(x: cx, y: baseY),
            control1: CGPoint(x: cx + halfW * tipNarrow + tipSway * 0.5, y: tipY + h * 0.15),
            control2: CGPoint(x: cx + halfW * 1.1, y: baseY - h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: cx + tipSway, y: tipY),
            control1: CGPoint(x: cx - halfW * 1.1, y: baseY - h * 0.35),
            control2: CGPoint(x: cx - halfW * tipNarrow + tipSway * 0.5, y: tipY + h * 0.15)
        )
        path.closeSubpath()
        return path
    }
}
