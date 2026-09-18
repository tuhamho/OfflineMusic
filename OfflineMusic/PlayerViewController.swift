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
    private let elapsedLabel = UILabel()
    private let durationLabel = UILabel()
    private let shuffleButton = PlaybackIconButton()
    private let previousButton = PlaybackIconButton()
    private let playButton = PlaybackIconButton()
    private let nextButton = PlaybackIconButton()
    private let repeatButton = PlaybackIconButton()
    private let manager = MusicPlayerManager.shared
    private var isScrubbing = false
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
        slider.minimumTrackTintColor = PlayerTheme.accent
        slider.maximumTrackTintColor = PlayerTheme.track
        slider.thumbTintColor = PlayerTheme.primary
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        view.addSubview(slider)

        elapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        elapsedLabel.font = .systemFont(ofSize: 12)
        durationLabel.font = .systemFont(ofSize: 12)
        elapsedLabel.textColor = PlayerTheme.secondary
        durationLabel.textColor = PlayerTheme.secondary
        view.addSubview(elapsedLabel)
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
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            elapsedLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 2),
            elapsedLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            durationLabel.topAnchor.constraint(equalTo: elapsedLabel.topAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor),
            controls.topAnchor.constraint(equalTo: elapsedLabel.bottomAnchor, constant: 22),
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
        durationLabel.text = format(song.duration)
        if !isScrubbing {
            let current = max(0, manager.player.currentTime().seconds)
            elapsedLabel.text = format(current)
            slider.maximumValue = Float(max(1, song.duration))
            slider.value = Float(min(current, song.duration))
        }
        playButton.iconKind = manager.isPlaying ? .pause : .play
        playButton.iconColor = .black
        shuffleButton.iconColor = manager.shuffle ? PlayerTheme.accent : PlayerTheme.secondary
        repeatButton.iconKind = manager.repeatMode == .one ? .repeatOne : .repeatAll
        repeatButton.iconColor = manager.repeatMode == .off ? PlayerTheme.secondary : PlayerTheme.accent
    }

    @objc private func sliderBegan() { isScrubbing = true }
    @objc private func sliderChanged() { elapsedLabel.text = format(TimeInterval(slider.value)) }
    @objc private func sliderEnded() { isScrubbing = false; manager.seek(to: TimeInterval(slider.value)); refresh() }
    @objc private func toggleShuffle() { manager.shuffle.toggle(); refresh() }
    @objc private func previous() { manager.previous() }
    @objc private func togglePlay() { manager.togglePlayPause() }
    @objc private func nextTapped() {
    MusicPlayerManager.shared.next()
}
    @objc private func cycleRepeat() { manager.repeatMode = RepeatMode(rawValue: (manager.repeatMode.rawValue + 1) % 3) ?? .off; refresh() }

    private func format(_ seconds: TimeInterval) -> String { String(format: "%d:%02d", max(0, Int(seconds)) / 60, max(0, Int(seconds)) % 60) }
}
