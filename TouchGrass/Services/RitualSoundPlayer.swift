import AVFoundation

/// Plays one-shot ritual sounds (bubble pop, magic echo) at full volume.
/// Runs on the .playback session so sounds cut through even in silent mode —
/// mirrors Android's PopSoundPlayer using the ALARM stream.
final class RitualSoundPlayer {
    static let shared = RitualSoundPlayer()

    private var players: [AVAudioPlayer] = []

    private init() {}

    func playPop() {
        play(resource: "pop", extension: "mp3")
    }

    func playMagicEcho() {
        play(resource: "magic_echo", extension: "mp3")
    }

    private func play(resource: String, extension ext: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            print("RitualSoundPlayer: \(resource).\(ext) not found in bundle")
            return
        }
        ensurePlaybackSession()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 1.0
            p.prepareToPlay()
            p.play()
            players.append(p)
            // Prune finished players
            players.removeAll { !$0.isPlaying && $0.currentTime > 0 }
        } catch {
            print("RitualSoundPlayer: failed to play \(resource): \(error)")
        }
    }

    /// The ritual's ambience normally puts the session in .playback, but these sounds
    /// also play outside the ritual (e.g. the practice bubble on the home screen),
    /// where the default session would let the silent switch mute them.
    /// Left alone while recording so the blow detector's session isn't torn down.
    private func ensurePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        guard session.category != .playAndRecord else { return }
        try? session.setCategory(.playback, options: .mixWithOthers)
        try? session.setActive(true)
    }
}
