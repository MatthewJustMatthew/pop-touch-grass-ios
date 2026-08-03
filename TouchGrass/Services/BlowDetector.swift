import AVFoundation

/// Detects blowing into the microphone.
/// Blow signature: high amplitude + low zero-crossing rate (low-frequency air noise),
/// sustained across consecutive buffers to reject speech/taps/ambient noise.
///
/// Ambient rooms (traffic hum, AC, fans) can share a blow's low zero-crossing rate,
/// so absolute amplitude alone is not reliable. We additionally calibrate a rolling
/// noise floor from quiet frames and require a blow to be a strong multiple *above*
/// that floor — this is what actually distinguishes "blowing" from "the room."
final class BlowDetector {
    private let engine = AVAudioEngine()
    private var isListening = false
    private var sustainedBlowFrames = 0

    /// Rolling ambient noise floor, updated continuously from non-blow-like frames.
    private var noiseFloor: Float = 0.006
    private var hasCalibratedFloor = false

    /// Called on the main thread when a sustained blow is detected.
    var onBlow: (() -> Void)?

    private let requiredFrames = 4
    /// Absolute floor a blow must clear regardless of how quiet the room is.
    private let minAbsoluteThreshold: Float = 0.05
    /// A blow must also be this many times louder than the recent ambient floor.
    private let noiseFloorMultiplier: Float = 4.0
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

        // A blow must clear an absolute floor AND be well above the room's own noise —
        // this is what rejects AC hum, traffic, or a loud room from false-triggering.
        let dynamicThreshold = max(minAbsoluteThreshold, noiseFloor * noiseFloorMultiplier)
        let isBlowLike = amplitude > dynamicThreshold && crossingRate < maxCrossingRate

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
            // Only calibrate from quiet, non-blow-like frames so a slow rising blow
            // doesn't get absorbed into the floor before it's detected.
            if amplitude < minAbsoluteThreshold {
                if !hasCalibratedFloor {
                    noiseFloor = amplitude
                    hasCalibratedFloor = true
                } else {
                    noiseFloor = noiseFloor * 0.9 + amplitude * 0.1
                }
            }
        }
    }
}
