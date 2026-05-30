import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

/// First-launch onboarding ritual, ported from Android's RitualActivity.
/// Flow: intro → pop bubble → awareness question → intention → setup Screen Time
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var currentStep = 1

    // Step 3 + 5 text input
    @State private var awarenessText = ""
    @State private var intentionText = ""

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.04, green: 0.02, blue: 0.08)
                .ignoresSafeArea()

            Group {
                switch currentStep {
                case 1: step1View
                case 2: step2View
                case 3: step3View
                case 4: step4View
                case 5: step5View
                case 6: step6View
                case 7: step7Setup
                default: EmptyView()
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.75)))
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 1: "Social media conditions you"

    private var step1View: some View {
        RitualStepView(
            lines: [
                (text: "Social media conditions you.", delay: 1.5),
                (text: "Let's condition you back to you.", delay: 4.5)
            ],
            tapPromptDelay: 7.5,
            onTap: { nextStep() }
        )
    }

    // MARK: - Step 2: "A gentle nudge"

    private var step2View: some View {
        VStack(spacing: 32) {
            Spacer()

            FadeInText("When you're mindlessly scrolling,", delay: 1.5)
            FadeInText("you'll hear a whistle.", delay: 4.5)
            FadeInText("That's your wake-up call.", delay: 7.5)

            FadeInView(delay: 10.0) {
                BubblePopView(delay: 0) {
                    nextStep()
                }
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Step 3: "What does awareness mean to you?"

    private var step3View: some View {
        VStack(spacing: 32) {
            Spacer()

            FadeInText("What does awareness\nmean to you?", delay: 1.5)

            FadeInView(delay: 4.5) {
                VStack(spacing: 8) {
                    TextField("", text: $awarenessText)
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocorrection(.no)

                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: 280)
                }
            }

            FadeInText("presence · clarity · feeling alive", delay: 7.5, size: 14, opacity: 0.4)

            FadeInView(delay: 7.5) {
                BubblePopView(delay: 0) {
                    if !awarenessText.isEmpty {
                        settings.userAwareness = awarenessText
                        nextStep()
                    }
                }
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Step 4: Show their awareness answer

    private var step4View: some View {
        VStack(spacing: 32) {
            Spacer()

            FadeInText("\"\(settings.userAwareness)\"", delay: 1.5, size: 28)
            FadeInText("Each nudge is your reminder\nto come back to this.", delay: 4.5)

            FadeInView(delay: 7.5) {
                BubblePopView(delay: 0) {
                    nextStep()
                }
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Step 5: Set intention

    private var step5View: some View {
        VStack(spacing: 32) {
            Spacer()

            FadeInText("Set your intention.", delay: 1.5)
            FadeInText("What will you do instead\nof mindless scrolling?", delay: 4.5, size: 16, opacity: 0.6)

            FadeInView(delay: 7.5) {
                VStack(spacing: 8) {
                    TextField("", text: $intentionText)
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocorrection(.no)

                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: 280)
                }
            }

            FadeInText("go for a walk · call a friend · read", delay: 10.5, size: 14, opacity: 0.4)

            FadeInView(delay: 10.5) {
                BubblePopView(delay: 0) {
                    if !intentionText.isEmpty {
                        settings.userIntention = intentionText
                        nextStep()
                    }
                }
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Step 6: Reinforce intention

    private var step6View: some View {
        VStack(spacing: 32) {
            Spacer()

            FadeInText("\"\(settings.userIntention)\"", delay: 1.5, size: 28)
            FadeInText("This is your anchor.\nEvery nudge carries it.", delay: 4.5)

            FadeInView(delay: 7.5) {
                BubblePopView(delay: 0) {
                    nextStep()
                }
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Step 7: Screen Time setup

    private var step7Setup: some View {
        VStack(spacing: 32) {
            Spacer()

            FadeInText("One last thing.", delay: 1.0)
            FadeInText("Choose the apps you want\nTouch Grass to watch over.", delay: 3.5, size: 16, opacity: 0.7)

            FadeInView(delay: 6.0) {
                Button(action: {
                    Task {
                        await screenTime.requestAuthorization()
                        settings.ritualCompleted = true
                        screenTime.startMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Enable Nudges")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }

            FadeInView(delay: 9.0) {
                Button("Skip for now") {
                    settings.ritualCompleted = true
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.75)) {
            currentStep += 1
        }
    }
}

// MARK: - Reusable Components

/// A ritual step with sequential text fade-ins and a tap-to-continue prompt
struct RitualStepView: View {
    let lines: [(text: String, delay: Double)]
    let tapPromptDelay: Double
    let onTap: () -> Void

    @State private var showPrompt = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                FadeInText(line.text, delay: line.delay)
            }

            if showPrompt {
                Text("tap to continue")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(32)
        .contentShape(Rectangle())
        .onTapGesture {
            if showPrompt { onTap() }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + tapPromptDelay) {
                withAnimation(.easeIn(duration: 1.5)) {
                    showPrompt = true
                }
            }
        }
    }
}

/// Text that fades in after a delay
struct FadeInText: View {
    let text: String
    let delay: Double
    let size: CGFloat
    let opacity: Double

    @State private var visible = false

    init(_ text: String, delay: Double, size: CGFloat = 22, opacity: Double = 0.9) {
        self.text = text
        self.delay = delay
        self.size = size
        self.opacity = opacity
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .light, design: .serif))
            .foregroundColor(.white.opacity(visible ? opacity : 0))
            .multilineTextAlignment(.center)
            .onAppear {
                withAnimation(.easeIn(duration: 2.0).delay(delay)) {
                    visible = true
                }
            }
    }
}

/// Generic view that fades in after a delay
struct FadeInView<Content: View>: View {
    let delay: Double
    @ViewBuilder let content: () -> Content

    @State private var visible = false

    var body: some View {
        content()
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 1.5).delay(delay)) {
                    visible = true
                }
            }
    }
}

/// A simple bubble that can be popped with a tap
struct BubblePopView: View {
    let delay: Double
    let onPopped: () -> Void

    @State private var visible = false
    @State private var popped = false
    @State private var scale: CGFloat = 1.0
    @State private var bubbleOpacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.cyan.opacity(0.15),
                        Color.blue.opacity(0.1)
                    ],
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 50
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .opacity(visible ? bubbleOpacity : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0).delay(delay)) {
                    visible = true
                }
                // Gentle breathing animation
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(delay + 1.0)) {
                    scale = 1.08
                }
            }
            .onTapGesture {
                guard visible && !popped else { return }
                popped = true

                // Pop haptic
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                // Pop animation
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.3
                    bubbleOpacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onPopped()
                }
            }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppSettings())
}
