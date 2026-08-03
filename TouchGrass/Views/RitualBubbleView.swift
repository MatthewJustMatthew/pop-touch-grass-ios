import SwiftUI

/// Direct SwiftUI port of Android's BubbleView:
/// organic wobble, iridescent soap film, drifting highlights, and a full pop effect
/// (flash, subliminal 🌿, expanding rings, droplets with gravity, lingering mist).
struct RitualBubbleView: View {
    let size: CGFloat
    let onPopped: () -> Void

    @State private var startDate = Date()
    @State private var popDate: Date?
    @State private var popped = false
    @State private var droplets: [Droplet] = []
    @State private var mist: [Mist] = []

    // Animation periods from Android (seconds per revolution)
    private let wobblePeriod: Double = 2.8
    private let wobble2Period: Double = 3.7
    private let shimmerPeriod: Double = 4.0
    private let breathePeriod: Double = 3.2
    private let highlightPeriod: Double = 6.0

    private struct Droplet {
        var x: CGFloat; var y: CGFloat
        let vx: CGFloat; let vy: CGFloat
        var radius: CGFloat
        let color: Color
        let gravity: CGFloat
    }

    private struct Mist {
        let x: CGFloat; let y: CGFloat
        let vx: CGFloat; let vy: CGFloat
        var alpha: Double
        let size: CGFloat
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let t = timeline.date.timeIntervalSince(startDate)
                let cx = canvasSize.width / 2
                let cy = canvasSize.height / 2
                let baseRadius = min(canvasSize.width, canvasSize.height) / 2 - 20

                if let popDate {
                    let elapsed = timeline.date.timeIntervalSince(popDate)
                    if elapsed < 0.06 {
                        // Swell before pop
                        drawBubble(context: context, cx: cx, cy: cy, baseRadius: baseRadius,
                                   t: t, scale: 1 + 0.12 * (elapsed / 0.06))
                    } else {
                        let p = min((elapsed - 0.06) / 0.5, 1.0)
                        drawPopEffect(context: context, cx: cx, cy: cy, baseRadius: baseRadius, p: p)
                    }
                } else {
                    drawBubble(context: context, cx: cx, cy: cy, baseRadius: baseRadius, t: t, scale: 1)
                }
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onTapGesture { pop() }
    }

    // MARK: - Pop trigger

    private func pop() {
        guard !popped else { return }
        popped = true
        spawnParticles()
        RitualSoundPlayer.shared.playPop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        popDate = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onPopped()
        }
    }

    private func spawnParticles() {
        let cx = size / 2, cy = size / 2
        let baseRadius = size / 2 - 20
        let dropletColors: [Color] = [
            Color(red: 1, green: 0.71, blue: 0.76).opacity(0.73),
            Color(red: 0.53, green: 0.81, blue: 0.98).opacity(0.73),
            Color(red: 0.60, green: 0.98, blue: 0.60).opacity(0.73),
            Color(red: 0.87, green: 0.63, blue: 0.87).opacity(0.73),
            Color(red: 1, green: 0.84, blue: 0).opacity(0.73),
            Color.white.opacity(0.73),
            Color(red: 0.53, green: 0.87, blue: 1).opacity(0.73),
            Color(red: 1, green: 0.67, blue: 0.81).opacity(0.73),
            Color(red: 0.68, green: 0.85, blue: 0.90).opacity(0.73),
            Color(red: 0.78, green: 0.64, blue: 0.78).opacity(0.73),
        ]
        for i in 0..<20 {
            let angle = Double(i) * 18 + Double.random(in: 0..<12)
            let speed = 3.5 + CGFloat.random(in: 0..<8)
            let rad = angle * .pi / 180
            droplets.append(Droplet(
                x: cx + (CGFloat.random(in: 0..<1) - 0.5) * baseRadius * 0.4,
                y: cy + (CGFloat.random(in: 0..<1) - 0.5) * baseRadius * 0.4,
                vx: CGFloat(cos(rad)) * speed,
                vy: CGFloat(sin(rad)) * speed,
                radius: 2 + CGFloat.random(in: 0..<7),
                color: dropletColors[i % dropletColors.count],
                gravity: 0.12 + CGFloat.random(in: 0..<0.3)
            ))
        }
        for _ in 0..<15 {
            let angle = Double.random(in: 0..<360) * .pi / 180
            let speed = 0.5 + CGFloat.random(in: 0..<2)
            mist.append(Mist(
                x: cx + (CGFloat.random(in: 0..<1) - 0.5) * baseRadius * 0.6,
                y: cy + (CGFloat.random(in: 0..<1) - 0.5) * baseRadius * 0.6,
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed,
                alpha: Double(Int.random(in: 120...200)) / 255,
                size: 1 + CGFloat.random(in: 0..<1.5)
            ))
        }
    }

    // MARK: - Bubble drawing

    private func wobblePath(cx: CGFloat, cy: CGFloat, baseRadius: CGFloat, t: Double) -> Path {
        let wobblePhase = t / wobblePeriod * 2 * .pi
        let wobblePhase2 = t / wobble2Period * 2 * .pi
        var path = Path()
        let segments = 64
        for i in 0...segments {
            let angle = Double(i) / Double(segments) * 2 * .pi
            let w1 = sin(angle * 3 + wobblePhase) * 0.018
            let w2 = sin(angle * 5 + wobblePhase2 * 0.7) * 0.010
            let w3 = cos(angle * 2 + wobblePhase * 1.3) * 0.014
            let r = baseRadius * CGFloat(1 + w1 + w2 + w3)
            let px = cx + CGFloat(cos(angle)) * r
            let py = cy + CGFloat(sin(angle)) * r
            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
            else { path.addLine(to: CGPoint(x: px, y: py)) }
        }
        path.closeSubpath()
        return path
    }

    private func drawBubble(context: GraphicsContext, cx: CGFloat, cy: CGFloat,
                            baseRadius: CGFloat, t: Double, scale: Double) {
        let breatheScale = 1 + 0.02 * sin(t / breathePeriod * 2 * .pi)
        let totalScale = breatheScale * scale
        let shimmerPhase = t / shimmerPeriod * 360
        let highlightDrift = t / highlightPeriod * 2 * .pi
        let wobblePhase = t / wobblePeriod * 2 * .pi

        var ctx = context
        ctx.translateBy(x: cx, y: cy)
        ctx.scaleBy(x: totalScale, y: totalScale)
        ctx.translateBy(x: -cx, y: -cy)

        let path = wobblePath(cx: cx, cy: cy, baseRadius: baseRadius, t: t)

        // Layer 0: subtle glow underneath
        ctx.fill(
            Circle().path(in: CGRect(x: cx - baseRadius * 1.3, y: cy - baseRadius * 1.3,
                                     width: baseRadius * 2.6, height: baseRadius * 2.6)),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.09), Color(red: 0.67, green: 0.87, blue: 1).opacity(0.03), .clear]),
                center: CGPoint(x: cx, y: cy + baseRadius * 0.05),
                startRadius: baseRadius * 1.3 * 0.4,
                endRadius: baseRadius * 1.3
            )
        )

        let iridescent: [Color] = [
            Color(red: 1, green: 0.42, blue: 0.54).opacity(0.53),
            Color(red: 1, green: 0.62, blue: 0.26).opacity(0.56),
            Color(red: 1, green: 0.85, blue: 0.24).opacity(0.53),
            Color(red: 0.34, green: 0.89, blue: 0.62).opacity(0.53),
            Color(red: 0.27, green: 0.72, blue: 0.82).opacity(0.56),
            Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.53),
            Color(red: 0.88, green: 0.25, blue: 0.98).opacity(0.53),
            Color(red: 1, green: 0.42, blue: 0.54).opacity(0.53),
        ]

        // Layer 1: soap film — iridescent sweep, rotated by shimmer
        ctx.drawLayer { layer in
            layer.fill(
                path,
                with: .conicGradient(
                    Gradient(colors: iridescent),
                    center: CGPoint(x: cx, y: cy),
                    angle: .degrees(shimmerPhase)
                )
            )
            layer.blendMode = .multiply
            layer.fill(
                path,
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.13), Color.white.opacity(0.27),
                                      Color.white.opacity(0.53), Color.white.opacity(0.33)]),
                    center: CGPoint(x: cx, y: cy - baseRadius * 0.3),
                    startRadius: 0,
                    endRadius: baseRadius * 1.4
                )
            )
        }

        // Layer 2: second rainbow pass for depth
        ctx.drawLayer { layer in
            layer.fill(
                path,
                with: .conicGradient(
                    Gradient(colors: iridescent),
                    center: CGPoint(x: cx, y: cy),
                    angle: .degrees(shimmerPhase * -0.7 + 120)
                )
            )
            layer.blendMode = .multiply
            layer.fill(
                path,
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.19),
                                      Color.white.opacity(0.33), Color.white.opacity(0.13)]),
                    center: CGPoint(x: cx, y: cy + baseRadius * 0.2),
                    startRadius: 0,
                    endRadius: baseRadius * 1.2
                )
            )
        }

        // Layer 3: rim — bright edge
        ctx.stroke(
            path,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.88),
                    .init(color: Color.white.opacity(0.6), location: 0.96),
                    .init(color: Color.white.opacity(0.33), location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: baseRadius
            ),
            lineWidth: baseRadius * 0.07
        )

        // Layer 4: primary highlight — drifts slowly
        let hlDriftX = CGFloat(sin(highlightDrift)) * baseRadius * 0.08
        let hlDriftY = CGFloat(cos(highlightDrift * 0.7)) * baseRadius * 0.06
        let hlWobX = 2 * CGFloat(sin(wobblePhase * 0.5))
        let hlWobY = 2 * CGFloat(cos(wobblePhase * 0.7))
        let hlX = cx - baseRadius * 0.28 + hlDriftX + hlWobX
        let hlY = cy - baseRadius * 0.32 + hlDriftY + hlWobY
        let hlRadiusX = baseRadius * 0.38
        let hlRadiusY = baseRadius * 0.28

        ctx.drawLayer { layer in
            layer.translateBy(x: hlX, y: hlY)
            layer.rotate(by: .degrees(-25))
            layer.translateBy(x: -hlX, y: -hlY)
            layer.fill(
                Ellipse().path(in: CGRect(x: hlX - hlRadiusX, y: hlY - hlRadiusY,
                                          width: hlRadiusX * 2, height: hlRadiusY * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(0.87), location: 0),
                        .init(color: Color.white.opacity(0.33), location: 0.35),
                        .init(color: .clear, location: 1),
                    ]),
                    center: CGPoint(x: hlX, y: hlY),
                    startRadius: 0,
                    endRadius: hlRadiusX
                )
            )
        }

        // Layer 5: secondary highlight (bottom-right)
        let hl2X = cx + baseRadius * 0.22 - hlDriftX * 0.5
        let hl2Y = cy + baseRadius * 0.25 - hlDriftY * 0.5
        let hl2Radius = baseRadius * 0.12
        ctx.fill(
            Circle().path(in: CGRect(x: hl2X - hl2Radius, y: hl2Y - hl2Radius,
                                     width: hl2Radius * 2, height: hl2Radius * 2)),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.47), .clear]),
                center: CGPoint(x: hl2X, y: hl2Y),
                startRadius: 0,
                endRadius: hl2Radius
            )
        )

        // Layer 6: sparkle dot with pulse
        let sparkleX = cx - baseRadius * 0.15 + hlDriftX * 0.3
        let sparkleY = cy - baseRadius * 0.42 + hlDriftY * 0.3
        let sparkleAlpha = (180 + 75 * sin(t / shimmerPeriod * 2 * .pi * 3)) / 255
        ctx.fill(
            Circle().path(in: CGRect(x: sparkleX - baseRadius * 0.04, y: sparkleY - baseRadius * 0.04,
                                     width: baseRadius * 0.08, height: baseRadius * 0.08)),
            with: .color(Color.white.opacity(max(0, min(1, sparkleAlpha))))
        )
    }

    // MARK: - Pop effect

    private func drawPopEffect(context: GraphicsContext, cx: CGFloat, cy: CGFloat,
                               baseRadius: CGFloat, p: Double) {
        // White flash on first 15%
        if p < 0.15 {
            let flashAlpha = 180 * (1 - p / 0.15) / 255
            context.fill(
                Circle().path(in: CGRect(x: cx - baseRadius * 1.1, y: cy - baseRadius * 1.1,
                                         width: baseRadius * 2.2, height: baseRadius * 2.2)),
                with: .color(Color.white.opacity(flashAlpha))
            )
        }

        // Subliminal prime — brief 🌿 flash between 15-35%
        if p >= 0.15 && p <= 0.35 {
            let localP = (p - 0.15) / 0.20
            let fade = localP < 0.5 ? localP * 2 : 2 - localP * 2
            let alpha = 200 * fade / 255
            let resolved = context.resolve(
                Text("🌿").font(.system(size: baseRadius * 0.8))
                    .foregroundColor(Color.white.opacity(alpha))
            )
            context.draw(resolved, at: CGPoint(x: cx, y: cy))
        }

        // Expanding rings
        if p < 1 {
            let ringRadius = baseRadius + baseRadius * 1.2 * p
            let ringAlpha = 200 * (1 - p) / 255
            var ringPath = Path()
            for i in 0...48 {
                let angle = Double(i) / 48 * 2 * .pi
                let wobble = 1 + sin(angle * 4) * 0.03 * (1 - p)
                let r = ringRadius * CGFloat(wobble)
                let px = cx + CGFloat(cos(angle)) * r
                let py = cy + CGFloat(sin(angle)) * r
                if i == 0 { ringPath.move(to: CGPoint(x: px, y: py)) }
                else { ringPath.addLine(to: CGPoint(x: px, y: py)) }
            }
            ringPath.closeSubpath()
            context.stroke(ringPath, with: .color(Color.white.opacity(ringAlpha)),
                           lineWidth: max(5 * CGFloat(1 - p), 0.5))
            context.stroke(
                Circle().path(in: CGRect(x: cx - ringRadius * 0.65, y: cy - ringRadius * 0.65,
                                         width: ringRadius * 1.3, height: ringRadius * 1.3)),
                with: .color(Color.white.opacity(ringAlpha * 0.4)),
                lineWidth: max(3 * CGFloat(1 - p), 0.5)
            )
        }

        // Droplets with gravity — velocities are per-frame units, integrate at ~60fps scale
        for d in droplets {
            let frames = p * 30 // ~500ms at 60fps
            let x = d.x + d.vx * frames * (1 - CGFloat(p) * 0.3)
            let y = d.y + d.vy * frames * (1 - CGFloat(p) * 0.3) + d.gravity * frames * frames * 0.5
            let alpha = 1 - p * p
            let radius = d.radius * pow(0.997, frames)
            let stretch = 1 + CGFloat(p) * 0.5
            let angle = atan2(d.vy, d.vx)
            context.drawLayer { layer in
                layer.translateBy(x: x, y: y)
                layer.rotate(by: Angle(radians: Double(angle)))
                layer.opacity = alpha
                layer.fill(
                    Ellipse().path(in: CGRect(x: -radius, y: -radius * stretch,
                                              width: radius * 2, height: radius * 2 * stretch)),
                    with: .color(d.color)
                )
            }
        }

        // Mist — drifts slowly, fades slower
        for m in mist {
            let frames = p * 30
            let x = m.x + m.vx * 0.5 * frames
            let y = m.y + m.vy * 0.5 * frames
            let alpha = max(m.alpha - (2.0 / 255) * frames, 0)
            if alpha > 0 {
                context.fill(
                    Circle().path(in: CGRect(x: x - m.size, y: y - m.size,
                                             width: m.size * 2, height: m.size * 2)),
                    with: .color(Color.white.opacity(alpha))
                )
            }
        }
    }
}
