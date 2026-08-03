import SwiftUI
import AVFoundation

/// First-launch onboarding ritual — direct port of Android's RitualActivity.
/// Flow: intro → associate pop sound with awareness → awareness question →
/// confirm answer → set intention → reinforce intention → blow out the candle.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var currentStep = 1
    @Environment(\.scenePhase) private var scenePhase

    // Step 3 + 5 answers
    @State private var awarenessText = ""
    @State private var intentionText = ""

    private let mint = Color(red: 0.659, green: 0.902, blue: 0.812)

    var body: some View {
        ZStack {
            // Ritual background photo + #55000000 overlay (matches Android activity_ritual)
            GeometryReader { geo in
                Image("RitualBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .overlay(Color.black.opacity(0.33))
            .ignoresSafeArea()

            Group {
                switch currentStep {
                case 1: step1View
                case 2: step2View
                case 3: step3View
                case 4: step4View
                case 5: step5View
                case 6: step6View
                case 7: step7Candle
                default: EmptyView()
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.75)))
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            BackgroundAudioManager.shared.start()
            // Request mic permission upfront (mirrors Android onCreate)
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                BackgroundAudioManager.shared.resume()
            } else {
                BackgroundAudioManager.shared.pause()
            }
        }
    }

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.75)) {
            currentStep += 1
        }
    }

    // MARK: - Step 1: "Social media conditions you"

    private var step1View: some View {
        VStack(spacing: 0) {
            Spacer()
            RitualText("Social media conditions you.", delay: 1.5,
                       size: 26, color: .white, italic: true)
                .padding(.bottom, 24)
            RitualText("Let's get you back to you.", delay: 4.5,
                       size: 28, color: mint, italic: true, bold: true)
                .padding(.bottom, 60)
            RitualText("tap to continue", delay: 7.5,
                       size: 14, color: .white.opacity(0.53), italic: false)
            Spacer()
        }
        .padding(40)
        .contentShape(Rectangle())
        .onTapGestureAfter(delay: 7.5) { nextStep() }
    }

    // MARK: - Step 2: Associate the pop with awareness

    private var step2View: some View {
        VStack(spacing: 0) {
            Spacer()
            RitualText("Notice your thumb on the screen.", delay: 1.5, fadeOutAt: 7.5,
                       size: 22, color: .white, italic: true)
                .padding(.bottom, 20)
            RitualText("Feel the phone in your hand.", delay: 4.5, fadeOutAt: 7.5,
                       size: 22, color: mint, italic: true)
                .padding(.bottom, 40)
            RitualText("Let's associate this sound\nwith AWARENESS", delay: 10.5,
                       size: 24, color: .white, italic: true)
                .padding(.bottom, 16)
            RitualText("Pop the Magic Bubble", delay: 13.5,
                       size: 20, color: mint, italic: false)
                .padding(.bottom, 24)
            RitualBubbleView(size: 200) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nextStep() }
            }
            .appearWithOpacity(delay: 17.5, duration: 0.6)
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 40)
        .padding(.bottom, 150)
    }

    // MARK: - Step 3: What does AWARENESS mean to you?

    private var step3View: some View {
        RitualInputStep(
            suggestions: "looking around the room · noticing my breath\nremembering I have a body · a pause\nclarity · freedom · stillness",
            suggestionsDelay: 7.75,
            prompt: "What does AWARENESS\nmean to you?",
            promptDelay: 1.5,
            sub: nil,
            subDelay: 0,
            placeholder: "Type your answer...",
            inputDelay: 4.5,
            focusDelay: 6.5,
            bubbleDelay: 7.5,
            popHint: "pop the bubble to continue",
            text: $awarenessText,
            onSealed: { answer in
                settings.userAwareness = answer
                nextStep()
            }
        )
    }

    // MARK: - Step 4: Show their answer beautifully

    private var step4View: some View {
        VStack(spacing: 0) {
            Spacer()
            RitualText("\"\(settings.userAwareness)\"", delay: 1.5,
                       size: 24, color: mint, italic: true)
                .padding(.bottom, 32)
            RitualText("Every pop is your reminder.", delay: 4.5,
                       size: 20, color: .white, italic: false)
                .padding(.bottom, 48)
            RitualBubbleView(size: 120) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nextStep() }
            }
            .appearWithOpacity(delay: 7.5, duration: 2.0)
            .padding(.top, 8)
            Spacer()
        }
        .padding(40)
    }

    // MARK: - Step 5: Set your intention

    private var step5View: some View {
        RitualInputStep(
            suggestions: "stop doomscrolling · more awareness\nbreak the loop · less screen time · more magic",
            suggestionsDelay: 10.75,
            prompt: "Set your intention",
            promptDelay: 1.5,
            sub: "Why are you here?",
            subDelay: 4.5,
            placeholder: "I want to...",
            inputDelay: 7.5,
            focusDelay: 9.5,
            bubbleDelay: 10.5,
            popHint: "pop the bubble to seal your intention",
            text: $intentionText,
            onSealed: { intention in
                settings.userIntention = intention
                nextStep()
            }
        )
    }

    // MARK: - Step 6: Reinforce intention

    private var step6View: some View {
        VStack(spacing: 0) {
            Spacer()
            RitualText("\"\(settings.userIntention)\"", delay: 1.5,
                       size: 24, color: mint, italic: true)
                .padding(.bottom, 32)
            RitualText("Every pop brings you\nback to this", delay: 4.5,
                       size: 20, color: .white, italic: false)
                .padding(.bottom, 48)
            RitualBubbleView(size: 120) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nextStep() }
            }
            .appearWithOpacity(delay: 7.5, duration: 2.0)
            .padding(.top, 8)
            Spacer()
        }
        .padding(40)
    }

    // MARK: - Step 7: Blow out the candle

    private var step7Candle: some View {
        CandleRitualStep(mint: mint) {
            // Ritual complete — fade nature ambience, mark done
            BackgroundAudioManager.shared.fadeOut()
            settings.ritualCompleted = true
        }
    }
}

// MARK: - Candle Ritual Step (Android startStep7)

private struct CandleRitualStep: View {
    let mint: Color
    let onComplete: () -> Void

    @State private var flameBrightness: Double = 1.0
    @State private var blown = false
    @State private var tapFallbackEnabled = false
    @State private var hintText = "blow into your microphone"
    @State private var blowDetector = BlowDetector()
    @State private var autoBlowTask: Task<Void, Never>?
    @State private var tapFallbackTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RitualText("Affirm your Intention", delay: 1.5,
                           size: 24, color: .white, italic: true)
                    .opacity(blown ? 0 : 1)
                if blown {
                    Text("Your intention is set")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: blown)
            .padding(.bottom, 32)

            // Candle image (400dp frame, fitCenter) + flame overlay at top
            ZStack(alignment: .top) {
                Image("RitualCandle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                    .appearWithOpacity(delay: 4.5, duration: 2.0)

                CandleFlameView(brightness: $flameBrightness)
                    .frame(width: 70, height: 95)
                    .offset(x: -4, y: -15)
                    .appearWithOpacity(delay: 6.0, duration: 2.0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if tapFallbackEnabled { blowOutCandle() }
            }

            RitualText("Blow out the candle", delay: 7.5,
                       size: 20, color: mint, italic: true)
                .opacity(blown ? 0 : 1)
                .padding(.top, 24)

            RitualText(hintText, delay: 7.5,
                       size: 20, color: .white, italic: true)
                .opacity(blown ? 0 : 1)
                .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .onAppear {
            // Start blow detection at 6.5s (if mic permission granted)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                startBlowDetectionIfPermitted()
            }
            // At 17.5s, hint changes to "or tap the flame" and tap is enabled
            tapFallbackTask = Task {
                try? await Task.sleep(nanoseconds: 17_500_000_000)
                guard !Task.isCancelled, !blown else { return }
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.5)) {
                        hintText = "or tap the flame"
                    }
                    tapFallbackEnabled = true
                }
            }
            // Auto blow-out after 25s of inaction
            autoBlowTask = Task {
                try? await Task.sleep(nanoseconds: 25_000_000_000)
                guard !Task.isCancelled, !blown else { return }
                await MainActor.run { blowOutCandle() }
            }
        }
        .onDisappear {
            autoBlowTask?.cancel()
            tapFallbackTask?.cancel()
            blowDetector.stop()
        }
    }

    private func startBlowDetectionIfPermitted() {
        guard !blown else { return }
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            blowDetector.onBlow = { blowOutCandle() }
            blowDetector.start()
        case .denied:
            // If denied, allow tap as fallback
            tapFallbackEnabled = true
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.blowDetector.onBlow = { self.blowOutCandle() }
                        self.blowDetector.start()
                    } else {
                        self.tapFallbackEnabled = true
                    }
                }
            }
        @unknown default:
            tapFallbackEnabled = true
        }
    }

    private func blowOutCandle() {
        guard !blown else { return }
        blown = true
        autoBlowTask?.cancel()
        tapFallbackTask?.cancel()
        blowDetector.stop()

        // Magic echo sound + flame fade (1.2s, Android fadeOut(1200))
        RitualSoundPlayer.shared.playMagicEcho()
        withAnimation(.linear(duration: 1.2)) {
            flameBrightness = 0
        }

        // "Your intention is set" appears, then complete after 5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            onComplete()
        }
    }
}

// MARK: - Input Step (Android steps 3 & 5)

private struct RitualInputStep: View {
    let suggestions: String
    let suggestionsDelay: Double
    let prompt: String
    let promptDelay: Double
    let sub: String?
    let subDelay: Double
    let placeholder: String
    let inputDelay: Double
    let focusDelay: Double
    let bubbleDelay: Double
    let popHint: String
    @Binding var text: String
    let onSealed: (String) -> Void

    @State private var bubbleID = 0
    @State private var bubbleVisible = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            RitualText(suggestions, delay: suggestionsDelay,
                       size: 13, color: .white.opacity(0.47), italic: true, lineSpacing: 4)
                .padding(.bottom, 24)
            RitualText(prompt, delay: promptDelay,
                       size: 26, color: .white, italic: true)
                .padding(.bottom, sub != nil ? 12 : 32)
            if let sub {
                RitualText(sub, delay: subDelay,
                           size: 20, color: Color(red: 0.659, green: 0.902, blue: 0.812), italic: false)
                    .padding(.bottom, 20)
            }
            VStack(spacing: 0) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.53)))
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .disableAutocorrection(true)
                    .focused($inputFocused)
                    .padding(16)
                Rectangle()
                    .fill(Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.33))
                    .frame(width: 200, height: 1)
            }
            .appearWithOpacity(delay: inputDelay, duration: 2.0)

            if bubbleVisible {
                RitualBubbleView(size: 120) {
                    let answer = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !answer.isEmpty {
                        inputFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onSealed(answer)
                        }
                    } else {
                        // Re-add a bubble if text is empty (Android behavior)
                        bubbleVisible = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            bubbleID += 1
                            bubbleVisible = true
                        }
                    }
                }
                .id(bubbleID)
                .transition(.opacity)
            } else {
                Color.clear.frame(width: 120, height: 120)
            }
            Spacer().frame(height: 24)

            RitualText(popHint, delay: bubbleDelay,
                       size: 13, color: .white.opacity(0.47), italic: true)
                .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 40)
        .padding(.bottom, 200)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + focusDelay) {
                inputFocused = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + bubbleDelay) {
                withAnimation(.easeIn(duration: 2.0)) {
                    bubbleVisible = true
                }
            }
        }
    }
}

// MARK: - Ritual Text (2s fade-in, optional fade-out)

private struct RitualText: View {
    let text: String
    let delay: Double
    let fadeOutAt: Double?
    let size: CGFloat
    let color: Color
    let italic: Bool
    let bold: Bool
    let lineSpacing: CGFloat

    @State private var opacity: Double = 0

    init(_ text: String, delay: Double, fadeOutAt: Double? = nil,
         size: CGFloat, color: Color, italic: Bool, bold: Bool = false,
         lineSpacing: CGFloat = 0) {
        self.text = text
        self.delay = delay
        self.fadeOutAt = fadeOutAt
        self.size = size
        self.color = color
        self.italic = italic
        self.bold = bold
        self.lineSpacing = lineSpacing
    }

    @ViewBuilder
    private var styledText: some View {
        if italic {
            Text(text)
                .font(.system(size: size, weight: bold ? .bold : .regular, design: .serif))
                .italic()
        } else {
            Text(text)
                .font(.system(size: size, weight: bold ? .bold : .regular, design: .serif))
        }
    }

    var body: some View {
        styledText
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .lineSpacing(lineSpacing)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 2.0).delay(delay)) {
                    opacity = 1
                }
                if let fadeOutAt {
                    withAnimation(.easeOut(duration: 2.0).delay(fadeOutAt)) {
                        opacity = 0
                    }
                }
            }
    }
}

// MARK: - View helpers

private struct AppearWithOpacity: ViewModifier {
    let delay: Double
    let duration: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

private extension View {
    func appearWithOpacity(delay: Double, duration: Double) -> some View {
        modifier(AppearWithOpacity(delay: delay, duration: duration))
    }

    /// Tap only registers after the given delay (mirrors Android's alpha-gated tap)
    func onTapGestureAfter(delay: Double, action: @escaping () -> Void) -> some View {
        modifier(TapAfterModifier(delay: delay, action: action))
    }
}

private struct TapAfterModifier: ViewModifier {
    let delay: Double
    let action: () -> Void
    @State private var enabled = false

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                if enabled { action() }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 1.0) {
                    enabled = true
                }
            }
    }
}

