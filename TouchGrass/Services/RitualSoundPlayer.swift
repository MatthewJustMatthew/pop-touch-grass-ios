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
}
