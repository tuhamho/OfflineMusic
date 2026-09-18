import Foundation
import UIKit
import AVFoundation
import MediaPlayer

enum RepeatMode: Int { case off = 0, all = 1, one = 2 }

final class MusicPlayerManager: NSObject {
    static let shared = MusicPlayerManager()
    static let didChangeNotification = Notification.Name("MusicPlayerManagerDidChange")

    private(set) var player = AVPlayer()
    private(set) var currentSong: Song?
    private(set) var isPlaying = false
    var shuffle = false { didSet { if oldValue != shuffle { resetShuffleQueue(); saveState(); notifyChange() } } }
    var repeatMode = RepeatMode.off { didSet { if oldValue != repeatMode { saveState(); updateNowPlaying(); notifyChange() } } }

    private var timeObserver: Any?
    private var shuffleQueue: [String] = []
    private var shuffleHistory: [String] = []
    private var shuffleIndex = -1

    private override init() {
        super.init()
        configureAudioSession()
        restoreState()
        configureRemoteCommands()
        NotificationCenter.default.addObserver(self, selector: #selector(itemEnded(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.updateNowPlaying()
            self.notifyChange()
        }
    }

    deinit {
        if let observer = timeObserver { player.removeTimeObserver(observer) }
        NotificationCenter.default.removeObserver(self)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback)
        try? session.setActive(true)
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
    }

    func selectSong(_ song: Song) {
        if currentSong?.id == song.id { notifyChange(); return }
        currentSong = song
        player.replaceCurrentItem(with: AVPlayerItem(url: song.url))
        player.seek(to: .zero)
        if shuffle { addSongToShuffleHistory(song.id) }
        player.play()
        isPlaying = true
        saveState()
        updateNowPlaying()
        notifyChange()
    }

    func play() {
        guard currentSong != nil else { return }
        player.play(); isPlaying = true
        updateNowPlaying(); saveState(); notifyChange()
    }

    func pause() {
        player.pause(); isPlaying = false
        updateNowPlaying(); saveState(); notifyChange()
    }

    func togglePlayPause() { isPlaying ? pause() : play() }

    func seek(to value: TimeInterval) {
        player.seek(to: CMTime(seconds: max(0, value), preferredTimescale: 600))
        saveState(); updateNowPlaying(); notifyChange()
    }

    func savePlaybackState() { saveState() }

    func next() { if let song = nextSong() { selectSong(song) } else { pause() } }

    func previous() {
        guard let song = currentSong else { return }
        if player.currentTime().seconds > 3 { seek(to: 0); return }
        if shuffle, shuffleIndex > 0 {
            shuffleIndex -= 1
            if let id = shuffleHistory[safe: shuffleIndex], let previous = songWithID(id) {
                currentSong = nil
                selectSong(previous)
                return
            }
        }
        let songs = MusicLibraryManager.shared.songs
        guard let index = songs.firstIndex(where: { $0.id == song.id }), !songs.isEmpty else { return }
        selectSong(songs[(index - 1 + songs.count) % songs.count])
    }

    @objc private func itemEnded(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, item === player.currentItem else { return }
        if repeatMode == .one {
            player.seek(to: .zero); play()
        } else if let next = nextSong() {
            selectSong(next)
        } else {
            isPlaying = false; player.pause(); saveState(); updateNowPlaying(); notifyChange()
        }
    }

    private func nextSong() -> Song? {
        guard let current = currentSong else { return nil }
        let songs = MusicLibraryManager.shared.songs
        guard !songs.isEmpty else { return nil }
        if shuffle {
            if shuffleQueue.isEmpty || shuffleIndex + 1 >= shuffleQueue.count { resetShuffleQueue() }
            guard shuffleIndex + 1 < shuffleQueue.count else { return nil }
            shuffleIndex += 1
            return songWithID(shuffleQueue[shuffleIndex])
        }
        guard let index = songs.firstIndex(where: { $0.id == current.id }) else { return songs.first }
        if index + 1 < songs.count { return songs[index + 1] }
        return repeatMode == .all ? songs[0] : nil
    }

    private func resetShuffleQueue() {
        let currentID = currentSong?.id
        shuffleQueue = MusicLibraryManager.shared.songs.map { $0.id }.filter { $0 != currentID }.shuffled()
        shuffleHistory = currentID.map { [$0] } ?? []
        shuffleIndex = currentID == nil ? -1 : 0
    }

    private func addSongToShuffleHistory(_ id: String) {
        if shuffleHistory.last != id { shuffleHistory.append(id) }
        shuffleIndex = shuffleHistory.count - 1
    }

    private func songWithID(_ id: String) -> Song? { MusicLibraryManager.shared.songs.first { $0.id == id } }

    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(currentSong?.id, forKey: "songID")
        defaults.set(player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0, forKey: "position")
        defaults.set(shuffle, forKey: "shuffle")
        defaults.set(repeatMode.rawValue, forKey: "repeat")
    }

    private func restoreState() {
        let defaults = UserDefaults.standard
        shuffle = defaults.bool(forKey: "shuffle")
        repeatMode = RepeatMode(rawValue: defaults.integer(forKey: "repeat")) ?? .off
    }

    func restoreCurrentSong() {
        guard let id = UserDefaults.standard.string(forKey: "songID"), let song = songWithID(id) else { return }
        currentSong = song
        player.replaceCurrentItem(with: AVPlayerItem(url: song.url))
        let position = UserDefaults.standard.double(forKey: "position")
        if position > 0 { player.seek(to: CMTime(seconds: position, preferredTimescale: 600)) }
        player.pause(); isPlaying = false
        if shuffle { resetShuffleQueue() }
        updateNowPlaying(); notifyChange()
    }

    private func updateNowPlaying() {
        guard let song = currentSong else { return }
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = song.title
        info[MPMediaItemPropertyArtist] = song.artist
        info[MPMediaItemPropertyAlbumTitle] = song.album
        info[MPMediaItemPropertyPlaybackDuration] = song.duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(0, player.currentTime().seconds)
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        if let data = song.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func notifyChange() { NotificationCenter.default.post(name: MusicPlayerManager.didChangeNotification, object: self) }
}

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
