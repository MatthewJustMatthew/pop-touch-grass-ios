import AVFoundation

/// Looping nature ambience during the onboarding ritual — mirrors Android's RitualActivity:
/// loops ritual_firefly_glade at 40% volume, fades out over 1s when the ritual completes.
final class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()

    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?

    private let targetVolume: Float = 0.4

    private init() {}

    func start() {
        guard player == nil else {
            player?.play()
            return
        }
        guard let url = Bundle.main.url(forResource: "ritual_firefly_glade", withExtension: "wav") else {
            print("BackgroundAudioManager: ritual_firefly_glade.wav not found in bundle")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = targetVolume
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            print("BackgroundAudioManager: failed to start: \(error)")
        }
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    /// Fade out over the given duration, then stop and release the player.
    func fadeOut(duration: TimeInterval = 1.0) {
        guard let player else { return }
        fadeTimer?.invalidate()
        let startVolume = player.volume
        let steps = 20
        let interval = duration / Double(steps)
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            player.volume = max(startVolume * (1 - progress), 0)
            if currentStep >= steps {
                timer.invalidate()
                player.stop()
                self?.player = nil
                self?.fadeTimer = nil
            }
        }
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        player?.stop()
        player = nil
    }
}
