import AVFoundation

/// Detects blowing into the microphone — direct port of RitualActivity.startBlowDetection.
/// Blow signature: high amplitude + low zero-crossing rate (low-frequency air noise),
/// sustained across 3 consecutive buffers (~300ms) to reject speech/taps.
final class BlowDetector {
    private let engine = AVAudioEngine()
    private var isListening = false
    private var sustainedBlowFrames = 0

    /// Called on the main thread when a sustained blow is detected.
    var onBlow: (() -> Void)?

    private let requiredFrames = 3
    // Android: 16-bit PCM amplitude > 800 → float equivalent 800/32768
    private let amplitudeThreshold: Float = 800.0 / 32768.0
    private let maxCrossingRate: Float = 0.12

    func start() {
        guard !isListening else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // Need record capability while keeping ambience + sounds audible on speaker
            try session.setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true)

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.analyze(buffer)
            }
            try engine.start()
            isListening = true
        } catch {
            print("BlowDetector: failed to start: \(error)")
        }
    }

    func stop() {
        guard isListening else { return }
        isListening = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // Restore playback-only session for ambience/sounds
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
    }

    private func analyze(_ buffer: AVAudioPCMBuffer) {
        guard isListening,
              let channelData = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        let samples = channelData[0]

        // Overall amplitude (average absolute value)
        var total: Float = 0
        for i in 0..<frameCount {
            total += abs(samples[i])
        }
        let amplitude = total / Float(frameCount)

        // Zero-crossing rate — low = low frequency (blow), high = speech/taps/music
        var crossings = 0
        for i in 1..<frameCount {
            let cur = samples[i]
            let prev = samples[i - 1]
            if (cur > 0 && prev <= 0) || (cur <= 0 && prev > 0) {
                crossings += 1
            }
        }
        let crossingRate = Float(crossings) / Float(frameCount)

        let isBlowLike = amplitude > amplitudeThreshold && crossingRate < maxCrossingRate

        if isBlowLike {
            sustainedBlowFrames += 1
            if sustainedBlowFrames >= requiredFrames {
                isListening = false
                let callback = onBlow
                DispatchQueue.main.async {
                    self.stop()
                    callback?()
                }
            }
        } else {
            sustainedBlowFrames = 0
        }
    }
}
