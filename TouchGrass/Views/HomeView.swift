import SwiftUI
import FamilyControls

/// Main dashboard shown after onboarding is complete.
/// Displays user intention, monitoring controls, and app selection.
struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var showAppPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color(red: 0.04, green: 0.02, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // User intention display
                        if !settings.userIntention.isEmpty {
                            intentionCard
                        }

                        // Monitoring toggle
                        monitoringCard

                        // Frequency slider
                        frequencyCard

                        // App selection
                        appSelectionCard

                        // Reaffirm intention
                        Button(action: {
                            settings.ritualCompleted = false
                        }) {
                            HStack {
                                Image(systemName: "flame")
                                Text("Reaffirm Intention")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange.opacity(0.8))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Touch Grass")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAppPicker) {
                FamilyActivityPicker(selection: $screenTime.selectedApps)
                    .onChange(of: screenTime.selectedApps) { newSelection in
                        screenTime.saveSelection(newSelection)
                    }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            screenTime.loadSelection()
        }
    }

    // MARK: - Cards

    private var intentionCard: some View {
        VStack(spacing: 12) {
            Text("Your Intention")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.5)

            Text("\u{201C}\(settings.userIntention)\u{201D}")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var monitoringCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nudges Active")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text(settings.monitoringEnabled
                         ? "Watching your scroll time"
                         : "Nudges are off")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Toggle("", isOn: $settings.monitoringEnabled)
                    .labelsHidden()
                    .tint(.orange)
                    .onChange(of: settings.monitoringEnabled) { enabled in
                        if enabled {
                            Task { await screenTime.requestAuthorization() }
                            screenTime.startMonitoring()
                        } else {
                            screenTime.stopMonitoring()
                        }
                    }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var frequencyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("First Nudge After")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text(settings.intervalLabel)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
            }

            Slider(
                value: Binding(
                    get: { Double(settings.intervalStepIndex) },
                    set: { settings.intervalStepIndex = Int($0) }
                ),
                in: 0...Double(AppSettings.intervalSteps.count - 1),
                step: 1
            )
            .tint(.orange)

            HStack {
                Text("15s")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
                Text("10 min")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }

            // Escalation explanation
            Text("2nd nudge at \(settings.intervalSeconds * 2 < 60 ? "\(settings.intervalSeconds * 2)s" : "\(settings.intervalSeconds * 2 / 60) min")  ·  3rd at \(settings.intervalSeconds * 4 < 60 ? "\(settings.intervalSeconds * 4)s" : "\(settings.intervalSeconds * 4 / 60) min")")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var appSelectionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monitored Apps")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Button("Edit") {
                    showAppPicker = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
            }

            let count = screenTime.selectedApps.applicationTokens.count +
                        screenTime.selectedApps.categoryTokens.count
            Text(count > 0 ? "\(count) app\(count == 1 ? "" : "s") selected" : "No apps selected")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
}
