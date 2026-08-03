import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

/// Main dashboard — visually matched to the Android version:
///   • Mint green accent (#A8E6CF) replacing orange
///   • Enchanted-forest-style gradient background
///   • Centered hero header with logo, serif title, italic tagline
///   • Intention shown in mint green italic
///   • Full-width pill START/STOP button (not a toggle)
///   • Uppercase tracked section labels: CONFIGURATION · MONITORED APPS · HOW IT WORKS
///   • Glassmorphic cards (10% white fill, hairline border, 20pt corner radius)
struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var showAppPicker = false

    // Mint green — matches Android #A8E6CF
    private let mint = Color(red: 0.659, green: 0.902, blue: 0.812)

    var body: some View {
        ZStack {
            forestBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                        .padding(.bottom, 32)

                    actionButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                    statusLabel
                        .padding(.bottom, 32)

                    sectionLabel("Configuration")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    configCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    Button(action: { settings.ritualCompleted = false }) {
                        HStack {
                            Text("Reaffirm Your Intention  🌿")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(mint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .stroke(mint.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    sectionLabel("Monitored Apps")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    monitoredAppsCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    sectionLabel("How It Works")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    howItWorksCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
                .padding(.top, 56)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        #if canImport(FamilyControls)
        .sheet(isPresented: $showAppPicker) {
            FamilyActivityPicker(selection: $screenTime.selectedApps)
                .onChange(of: screenTime.selectedApps) { newSelection in
                    screenTime.saveSelection(newSelection)
                }
        }
        #endif
        .onAppear {
            #if canImport(FamilyControls)
            screenTime.loadSelection()
            #endif
        }
    }

    // MARK: - Background

    private var forestBackground: some View {
        ZStack {
            // Enchanted forest photo — explicitly framed to full screen on any device
            GeometryReader { geo in
                Image("ForestBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .overlay(Color.black.opacity(0.38))

            // Subtle vignette — mimics the dark overlay on the Android photo
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.35),
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 0) {
            // Poppable practice bubble — replaces the static logo so the pop
            // sound becomes familiar before it ever shows up as a nudge.
            PracticeBubbleView(size: 150)
                .frame(width: 150, height: 150)
                .padding(.bottom, 4)

            // "POP!\nTouch Grass" — serif, centered, matches Android textSize 28sp
            Text("POP!\nTouch Grass")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundColor(Color.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .tracking(0.5)
                .padding(.bottom, 6)

            // Tagline — italic serif, matches Android style
            Text("pop the bubble. break the loop. 🫧")
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Color.white.opacity(0.60))
                .padding(.bottom, 20)

            // User intention — mint green italic, matches Android #A8E6CF
            if !settings.userIntention.isEmpty {
                Text("\u{201C}\(settings.userIntention)\u{201D}")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(mint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button(action: {
            settings.monitoringEnabled.toggle()
            if settings.monitoringEnabled {
                Task { await screenTime.requestAuthorization() }
                screenTime.startMonitoring()
            } else {
                screenTime.stopMonitoring()
            }
        }) {
            Text(settings.monitoringEnabled
                 ? "Stop"
                 : "Start POP! Touch Grass 🌿")
                .font(.system(size: 16, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(Color(red: 0.05, green: 0.12, blue: 0.05))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(mint)
                .clipShape(Capsule())
        }
    }

    private var statusLabel: some View {
        Text(settings.monitoringEnabled
             ? "Active — watching for scroll time"
             : "Inactive")
            .font(.system(size: 12))
            .foregroundColor(Color.white.opacity(0.55))
    }

    // MARK: - Config Card

    private var configCard: some View {
        glassCard {
            VStack(spacing: 0) {
                // Frequency row
                HStack {
                    Text("Nudge frequency")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.87))
                    Spacer()
                    Text(settings.intervalLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(mint)
                }
                .padding(.bottom, 4)

                Slider(
                    value: Binding(
                        get: { Double(settings.intervalStepIndex) },
                        set: { settings.intervalStepIndex = Int($0) }
                    ),
                    in: 0...Double(AppSettings.intervalSteps.count - 1),
                    step: 1
                )
                .tint(mint)

                HStack {
                    Text("15s")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.47))
                    Spacer()
                    Text("10m")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.47))
                }
                .padding(.bottom, 20)

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.bottom, 16)

                // Escalation timing hint
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Escalating nudges")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.87))
                        Text(escalationLabel)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.47))
                    }
                    Spacer()
                }
            }
        }
    }

    private var escalationLabel: String {
        let s = settings.intervalSeconds
        func fmt(_ t: Int) -> String { t < 60 ? "\(t)s" : "\(t/60) min" }
        return "2nd nudge at \(fmt(s*2))  ·  3rd at \(fmt(s*4))"
    }

    // MARK: - Monitored Apps Card

    private var monitoredAppsCard: some View {
        glassCard {
            VStack(spacing: 0) {
                #if canImport(FamilyControls)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected apps")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.87))
                        let count = screenTime.selectedApps.applicationTokens.count +
                                    screenTime.selectedApps.categoryTokens.count
                        Text(count > 0 ? "\(count) app\(count == 1 ? "" : "s") selected" : "None selected")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.47))
                    }
                    Spacer()
                    Button("Edit") { showAppPicker = true }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(mint)
                }
                #else
                VStack(alignment: .leading, spacing: 6) {
                    Text("App selection")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.87))
                    Text("Available once FamilyControls entitlement is approved by Apple.")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.47))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                #endif
            }
        }
    }

    // MARK: - How It Works Card

    private var howItWorksCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 16) {
                howItWorksRow("Open your apps like normal")
                howItWorksRow("A gentle whistle nudge appears after your set time")
                howItWorksRow("Escalating nudges remind you to take a break")
                Text("Each nudge is a gentle moment of awareness")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(Color.white.opacity(0.60))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    private func howItWorksRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.53))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.73))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(2.0)
            .foregroundColor(Color.white.opacity(0.53))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.082), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
}
