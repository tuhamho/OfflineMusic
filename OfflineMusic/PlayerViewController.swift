import UIKit

private enum PlayerTheme {
    static let background = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
    static let navigation = UIColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1)
    static let primary = UIColor.white
    static let secondary = UIColor(red: 0.702, green: 0.702, blue: 0.702, alpha: 1)
    static let accent = UIColor(red: 0.93, green: 0.22, blue: 0.38, alpha: 1)
    static let track = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1)
}

final class PlayerViewController: UIViewController {
    private let artworkView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let slider = UISlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let shuffleButton = PlaybackIconButton()
    private let previousButton = PlaybackIconButton()
    private let playButton = PlaybackIconButton()
    private let nextButton = PlaybackIconButton()
    private let repeatButton = PlaybackIconButton()
    private let manager = MusicPlayerManager.shared
    private var isSeeking = false
    private var artworkSongID: String?

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Now Playing"
        view.backgroundColor = PlayerTheme.background
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = PlayerTheme.navigation
        navigationController?.navigationBar.tintColor = PlayerTheme.accent
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: PlayerTheme.primary]
        configureViews()
        NotificationCenter.default.addObserver(self, selector: #selector(playerChanged), name: MusicPlayerManager.didChangeNotification, object: manager)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func configureViews() {
        artworkView.translatesAutoresizingMaskIntoConstraints = false
        artworkView.contentMode = .scaleAspectFit
        artworkView.backgroundColor = PlayerTheme.navigation
        artworkView.clipsToBounds = true
        view.addSubview(artworkView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = PlayerTheme.primary
        titleLabel.numberOfLines = 2
        view.addSubview(titleLabel)

        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 15)
        artistLabel.textColor = PlayerTheme.secondary
        view.addSubview(artistLabel)

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.isUserInteractionEnabled = true
        slider.isEnabled = true
        slider.minimumTrackTintColor = PlayerTheme.accent
        slider.maximumTrackTintColor = PlayerTheme.track
        slider.thumbTintColor = PlayerTheme.primary
        slider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderEnded), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderEnded), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(sliderEnded), for: .touchCancel)
        view.addSubview(slider)

        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.font = .systemFont(ofSize: 12)
        durationLabel.font = .systemFont(ofSize: 12)
        currentTimeLabel.textColor = PlayerTheme.primary
        durationLabel.textColor = PlayerTheme.secondary
        currentTimeLabel.textAlignment = .left
        durationLabel.textAlignment = .right
        view.addSubview(currentTimeLabel)
        view.addSubview(durationLabel)

        configureButton(shuffleButton, kind: .shuffle, action: #selector(toggleShuffle))
        configureButton(previousButton, kind: .previous, action: #selector(previous))
        configureButton(playButton, kind: .play, action: #selector(togglePlay))
        configureButton(nextButton, kind: .next, action: #selector(nextTapped))
        configureButton(repeatButton, kind: .repeatAll, action: #selector(cycleRepeat))

        let controls = UIStackView(arrangedSubviews: [shuffleButton, previousButton, playButton, nextButton, repeatButton])
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.axis = .horizontal
        controls.alignment = .center
        controls.distribution = .equalSpacing
        controls.spacing = 0
        view.addSubview(controls)

        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            artworkView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            artworkView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor),
            titleLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            slider.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 22),
            slider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 6),
            slider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -6),
            slider.heightAnchor.constraint(equalToConstant: 44),
            currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            currentTimeLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 42),
            durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            durationLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 42),
            controls.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 22),
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            controls.heightAnchor.constraint(equalToConstant: 60),
            controls.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func configureButton(_ button: PlaybackIconButton, kind: PlaybackIconKind, action: Selector) {
        button.iconKind = kind
        button.iconColor = PlayerTheme.secondary
        button.dominant = kind == .play
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    @objc private func playerChanged() { refresh() }

    private func refresh() {
        guard let song = manager.currentSong else { return }
        titleLabel.text = song.title
        artistLabel.text = song.artist
        if artworkSongID != song.id {
            artworkView.image = song.artworkData.flatMap { UIImage(data: $0) }
            artworkSongID = song.id
        }
        let duration = validTime(song.duration)
        durationLabel.text = formatTime(duration)
        slider.maximumValue = Float(duration)
        if !isSeeking {
            let current = min(validTime(manager.player.currentTime().seconds), duration)
            currentTimeLabel.text = formatTime(current)
            slider.value = Float(current)
        }
        playButton.iconKind = manager.isPlaying ? .pause : .play
        playButton.iconColor = .black
        shuffleButton.iconColor = manager.shuffle ? PlayerTheme.accent : PlayerTheme.secondary
        repeatButton.iconKind = manager.repeatMode == .one ? .repeatOne : .repeatAll
        repeatButton.iconColor = manager.repeatMode == .off ? PlayerTheme.secondary : PlayerTheme.accent
    }

    @objc private func sliderBegan() {
        isSeeking = true
        currentTimeLabel.text = formatTime(Double(slider.value))
    }

    @objc private func sliderChanged() {
        currentTimeLabel.text = formatTime(Double(slider.value))
    }

    @objc private func sliderEnded() {
        manager.seek(to: Double(slider.value))
        isSeeking = false
        refresh()
    }
    @objc private func toggleShuffle() { manager.shuffle.toggle(); refresh() }
    @objc private func previous() { manager.previous() }
    @objc private func togglePlay() { manager.togglePlayPause() }
    @objc private func nextTapped() {
    MusicPlayerManager.shared.next()
}
    @objc private func cycleRepeat() { manager.repeatMode = RepeatMode(rawValue: (manager.repeatMode.rawValue + 1) % 3) ?? .off; refresh() }

    private func formatTime(_ seconds: Double) -> String {
        let safeSeconds = validTime(seconds)
        let totalSeconds = Int(safeSeconds.rounded(.down))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func validTime(_ seconds: Double) -> Double {
        guard seconds.isFinite, seconds >= 0 else { return 0 }
        return seconds
    }
}
