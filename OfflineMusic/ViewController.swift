import UIKit

private enum AppTheme {
    static let background = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
    static let card = UIColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1)
    static let navigation = UIColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1)
    static let primary = UIColor.white
    static let secondary = UIColor(red: 0.702, green: 0.702, blue: 0.702, alpha: 1)
    static let separator = UIColor(red: 0.165, green: 0.165, blue: 0.165, alpha: 1)
    static let accent = UIColor(red: 0.93, green: 0.22, blue: 0.38, alpha: 1)
}

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let miniPlayer = UIView()
    private let miniArtwork = UIImageView()
    private let miniTitle = UILabel()
    private let miniSubtitle = UILabel()
    private let miniPlayButton = UIButton(type: .system)
    private let miniNextButton = UIButton(type: .system)
    private let library = MusicLibraryManager.shared
    private let manager = MusicPlayerManager.shared
    private var miniArtworkSongID: String?

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Offline Music"
        view.backgroundColor = AppTheme.background
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = AppTheme.navigation
        navigationController?.navigationBar.tintColor = AppTheme.accent
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.primary]
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importAudio))
        configureTableView()
        configureMiniPlayer()
        NotificationCenter.default.addObserver(self, selector: #selector(playerChanged), name: MusicPlayerManager.didChangeNotification, object: manager)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppTheme.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 72
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongCell.self, forCellReuseIdentifier: SongCell.reuseIdentifier)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func configureMiniPlayer() {
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        miniPlayer.backgroundColor = AppTheme.card
        miniPlayer.layer.borderColor = AppTheme.separator.cgColor
        miniPlayer.layer.borderWidth = 0.5
        miniPlayer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPlayer)))
        view.addSubview(miniPlayer)

        miniArtwork.translatesAutoresizingMaskIntoConstraints = false
        miniArtwork.contentMode = .scaleAspectFill
        miniArtwork.clipsToBounds = true
        miniArtwork.backgroundColor = UIColor(white: 0.88, alpha: 1)
        miniPlayer.addSubview(miniArtwork)

        miniTitle.translatesAutoresizingMaskIntoConstraints = false
        miniTitle.font = .systemFont(ofSize: 14, weight: .medium)
        miniTitle.textColor = AppTheme.primary
        miniTitle.numberOfLines = 1
        miniPlayer.addSubview(miniTitle)
        miniSubtitle.translatesAutoresizingMaskIntoConstraints = false
        miniSubtitle.font = .systemFont(ofSize: 12)
        miniSubtitle.textColor = AppTheme.secondary
        miniPlayer.addSubview(miniSubtitle)

        configureButton(miniPlayButton, title: "Play", action: #selector(togglePlayback))
        configureButton(miniNextButton, title: "Next", action: #selector(nextTrack))
        NSLayoutConstraint.activate([
            miniPlayer.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            miniPlayer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            miniPlayer.heightAnchor.constraint(equalToConstant: 60),
            miniArtwork.leadingAnchor.constraint(equalTo: miniPlayer.leadingAnchor, constant: 10),
            miniArtwork.centerYAnchor.constraint(equalTo: miniPlayer.centerYAnchor),
            miniArtwork.widthAnchor.constraint(equalToConstant: 44),
            miniArtwork.heightAnchor.constraint(equalToConstant: 44),
            miniTitle.leadingAnchor.constraint(equalTo: miniArtwork.trailingAnchor, constant: 10),
            miniTitle.trailingAnchor.constraint(equalTo: miniPlayButton.leadingAnchor, constant: -6),
            miniTitle.topAnchor.constraint(equalTo: miniPlayer.topAnchor, constant: 12),
            miniSubtitle.leadingAnchor.constraint(equalTo: miniTitle.leadingAnchor),
            miniSubtitle.trailingAnchor.constraint(equalTo: miniTitle.trailingAnchor),
            miniSubtitle.topAnchor.constraint(equalTo: miniTitle.bottomAnchor, constant: 2),
            miniPlayButton.trailingAnchor.constraint(equalTo: miniNextButton.leadingAnchor, constant: -2),
            miniPlayButton.centerYAnchor.constraint(equalTo: miniPlayer.centerYAnchor),
            miniPlayButton.widthAnchor.constraint(equalToConstant: 54),
            miniNextButton.trailingAnchor.constraint(equalTo: miniPlayer.trailingAnchor, constant: -8),
            miniNextButton.centerYAnchor.constraint(equalTo: miniPlayer.centerYAnchor),
            miniNextButton.widthAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppTheme.accent, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        miniPlayer.addSubview(button)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { library.songs.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseIdentifier, for: indexPath) as! SongCell
        cell.configure(with: library.songs[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        manager.selectSong(library.songs[indexPath.row])
        openPlayer()
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let song = library.songs[indexPath.row]
        try? library.delete(song)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    @objc private func importAudio() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.mp3", "com.apple.m4a-audio", "public.aac-audio", "com.microsoft.waveform-audio"], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        urls.forEach { try? library.importFile(at: $0) }
        refresh()
    }

    @objc private func togglePlayback() { manager.togglePlayPause() }
    @objc private func nextTrack() { manager.next() }
    @objc private func openPlayer() { navigationController?.pushViewController(PlayerViewController(), animated: true) }
    @objc private func playerChanged() { refreshMini() }

    private func refresh() { tableView.reloadData(); refreshMini() }

    private func refreshMini() {
        guard let song = manager.currentSong else {
            miniTitle.text = "No song selected"
            miniSubtitle.text = ""
            miniArtwork.image = nil
            miniArtworkSongID = nil
            miniPlayButton.setTitle("Play", for: .normal)
            return
        }
        miniTitle.text = song.title
        miniSubtitle.text = manager.isPlaying ? song.artist : "Paused"
        if miniArtworkSongID != song.id {
            miniArtwork.image = song.artworkData.flatMap { UIImage(data: $0) }
            miniArtworkSongID = song.id
        }
        miniPlayButton.setTitle(manager.isPlaying ? "Pause" : "Play", for: .normal)
    }
}

private final class SongCell: UITableViewCell {
    static let reuseIdentifier = "SongCell"
    private let artworkView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let durationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .gray
        contentView.backgroundColor = AppTheme.card
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        artworkView.translatesAutoresizingMaskIntoConstraints = false
        artworkView.contentMode = .scaleAspectFill
        artworkView.clipsToBounds = true
        artworkView.backgroundColor = AppTheme.separator
        contentView.addSubview(artworkView)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = AppTheme.primary
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.font = .systemFont(ofSize: 13)
        artistLabel.textColor = AppTheme.secondary
        contentView.addSubview(artistLabel)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.textColor = AppTheme.secondary
        contentView.addSubview(durationLabel)
        NSLayoutConstraint.activate([
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            artworkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 55),
            artworkView.heightAnchor.constraint(equalToConstant: 55),
            titleLabel.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 42)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with song: Song) {
        titleLabel.text = song.title
        artistLabel.text = song.artist
        durationLabel.text = format(song.duration)
        artworkView.image = song.artworkData.flatMap { UIImage(data: $0) }
    }

    private func format(_ seconds: TimeInterval) -> String { String(format: "%d:%02d", max(0, Int(seconds)) / 60, max(0, Int(seconds)) % 60) }
}
