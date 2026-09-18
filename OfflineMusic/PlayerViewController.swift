import UIKit

final class PlayerViewController: UIViewController {
    private let artworkView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let slider = UISlider()
    private let elapsedLabel = UILabel()
    private let durationLabel = UILabel()
    private let shuffleButton = UIButton(type: .system)
    private let previousButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let repeatButton = UIButton(type: .system)
    private let manager = MusicPlayerManager.shared
    private var isScrubbing = false
    private var artworkSongID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Now Playing"
        view.backgroundColor = .white
        configureViews()
        NotificationCenter.default.addObserver(self, selector: #selector(playerChanged), name: MusicPlayerManager.didChangeNotification, object: manager)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func configureViews() {
        artworkView.translatesAutoresizingMaskIntoConstraints = false
        artworkView.contentMode = .scaleAspectFit
        artworkView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        artworkView.clipsToBounds = true
        view.addSubview(artworkView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 2
        view.addSubview(titleLabel)

        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 15)
        artistLabel.textColor = .gray
        view.addSubview(artistLabel)

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        view.addSubview(slider)

        elapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        elapsedLabel.font = .systemFont(ofSize: 12)
        durationLabel.font = .systemFont(ofSize: 12)
        elapsedLabel.textColor = .gray
        durationLabel.textColor = .gray
        view.addSubview(elapsedLabel)
        view.addSubview(durationLabel)

        configureButton(shuffleButton, title: "Shuffle", action: #selector(toggleShuffle))
        configureButton(previousButton, title: "Previous", action: #selector(previous))
        configureButton(playButton, title: "Play", action: #selector(togglePlay))
        configureButton(nextButton, title: "Next", action: #selector(next))
        configureButton(repeatButton, title: "Repeat Off", action: #selector(cycleRepeat))

        let controls = UIStackView(arrangedSubviews: [shuffleButton, previousButton, playButton, nextButton, repeatButton])
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.axis = .horizontal
        controls.alignment = .center
        controls.distribution = .fillEqually
        controls.spacing = 2
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
            controls.heightAnchor.constraint(equalToConstant: 52),
            controls.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
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
        playButton.setTitle(manager.isPlaying ? "Pause" : "Play", for: .normal)
        shuffleButton.alpha = manager.shuffle ? 1 : 0.5
        repeatButton.setTitle(repeatTitle(), for: .normal)
    }

    @objc private func sliderBegan() { isScrubbing = true }
    @objc private func sliderChanged() { elapsedLabel.text = format(TimeInterval(slider.value)) }
    @objc private func sliderEnded() { isScrubbing = false; manager.seek(to: TimeInterval(slider.value)); refresh() }
    @objc private func toggleShuffle() { manager.shuffle.toggle(); refresh() }
    @objc private func previous() { manager.previous() }
    @objc private func togglePlay() { manager.togglePlayPause() }
    @objc private func next() { manager.next() }
    @objc private func cycleRepeat() { manager.repeatMode = RepeatMode(rawValue: (manager.repeatMode.rawValue + 1) % 3) ?? .off; refresh() }

    private func repeatTitle() -> String {
        switch manager.repeatMode {
        case .off: return "Repeat Off"
        case .all: return "Repeat All"
        case .one: return "Repeat One"
        }
    }

    private func format(_ seconds: TimeInterval) -> String { String(format: "%d:%02d", max(0, Int(seconds)) / 60, max(0, Int(seconds)) % 60) }
}
