import SwiftUI
import AVFoundation

/// Cinematic cold open shown once before the onboarding ritual begins.
/// Letterboxed on black — the footage is 16:9 and its full width carries the
/// visual payoff, so it is never cropped. Tap anywhere to skip.
struct IntroVideoView: View {
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var showSkipHint = false
    @State private var didFinish = false
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                VideoLayerView(player: player)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()
                Text("tap to skip")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.4))
                    .opacity(showSkipHint ? 1 : 0)
                    .padding(.bottom, 44)
            }
            .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { start() }
        .onDisappear {
            player?.pause()
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }

    private func start() {
        guard let url = Bundle.main.url(forResource: "ritual_intro", withExtension: "mp4") else {
            print("IntroVideoView: ritual_intro.mp4 not found in bundle")
            onFinished()
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("IntroVideoView: audio session setup failed: \(error)")
        }

        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.actionAtItemEnd = .pause
        player = p

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            finish()
        }

        p.play()

        withAnimation(.easeIn(duration: 1.0).delay(2.0)) {
            showSkipHint = true
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        player?.pause()
        onFinished()
    }
}

/// AVPlayerLayer wrapper — gives exact control over videoGravity, which
/// SwiftUI's VideoPlayer does not expose (it would letterbox with controls).
private struct VideoLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.backgroundColor = .black
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
