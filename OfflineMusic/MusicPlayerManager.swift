import Foundation
import UIKit
import AVFoundation
import MediaPlayer

enum RepeatMode: Int { case off, one, all }
final class MusicPlayerManager: NSObject {
    static let shared = MusicPlayerManager()
    private(set) var player = AVPlayer()
    private(set) var currentSong: Song?
    var shuffle = false { didSet { saveState() } }
    var repeatMode = RepeatMode.off { didSet { saveState(); updateNowPlaying() } }
    var onChange: (() -> Void)?
    private var timeObserver: Any?
    private override init() { super.init(); configureAudio(); restoreState(); NotificationCenter.default.addObserver(self, selector: #selector(itemEnded), name: .AVPlayerItemDidPlayToEndTime, object: nil); timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] _ in self?.updateNowPlaying(); self?.onChange?() } }
    private func configureAudio() { try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback); try? AVAudioSession.sharedInstance().setActive(true); UIApplication.shared.beginReceivingRemoteControlEvents(); let commands = MPRemoteCommandCenter.shared(); commands.playCommand.addTarget { [weak self] _ in self?.play(); return .success }; commands.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }; commands.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }; commands.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success } }
    func play(_ song: Song? = nil) { if let song = song { currentSong = song; player.replaceCurrentItem(with: AVPlayerItem(url: song.url)); player.play() } else { player.play() }; updateNowPlaying(); saveState(); onChange?() }
    func pause() { player.pause(); saveState(); updateNowPlaying(); onChange?() }
    func toggle() { player.timeControlStatus == .playing ? pause() : play() }
    func seek(to value: TimeInterval) { player.seek(to: CMTime(seconds: value, preferredTimescale: 600)); saveState() }
    func next() { guard let current = currentSong else { return }; let list = MusicLibraryManager.shared.songs; guard !list.isEmpty else { return }; let index = list.firstIndex { $0.id == current.id } ?? 0; let nextIndex: Int; if shuffle { nextIndex = Int.random(in: 0..<list.count) } else if index + 1 < list.count { nextIndex = index + 1 } else if repeatMode == .all { nextIndex = 0 } else { pause(); return }; play(list[nextIndex]) }
    func previous() { guard let current = currentSong else { return }; let list = MusicLibraryManager.shared.songs; guard !list.isEmpty else { return }; let index = list.firstIndex { $0.id == current.id } ?? 0; play(list[(index - 1 + list.count) % list.count]) }
    @objc private func itemEnded() { repeatMode == .one ? play(currentSong) : next() }
    private func saveState() { let d = UserDefaults.standard; d.set(currentSong?.id, forKey: "songID"); d.set(player.currentTime().seconds, forKey: "position"); d.set(shuffle, forKey: "shuffle"); d.set(repeatMode.rawValue, forKey: "repeat"); d.synchronize() }
    private func restoreState() { shuffle = UserDefaults.standard.bool(forKey: "shuffle"); repeatMode = RepeatMode(rawValue: UserDefaults.standard.integer(forKey: "repeat")) ?? .off }
    func restoreCurrentSong() { guard let id = UserDefaults.standard.string(forKey: "songID"), let song = MusicLibraryManager.shared.songs.first(where: { $0.id == id }) else { return }; currentSong = song; player.replaceCurrentItem(with: AVPlayerItem(url: song.url)); let position = UserDefaults.standard.double(forKey: "position"); if position > 0 { player.seek(to: CMTime(seconds: position, preferredTimescale: 600)) }; updateNowPlaying() }
    private func updateNowPlaying() { guard let song = currentSong else { return }; var info = [String: Any](); info[MPMediaItemPropertyTitle] = song.title; info[MPMediaItemPropertyArtist] = song.artist; info[MPMediaItemPropertyAlbumTitle] = song.album; info[MPMediaItemPropertyAlbumTrackCount] = 1; info[MPMediaItemPropertyPlaybackDuration] = song.duration; info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds; info[MPNowPlayingInfoPropertyPlaybackRate] = player.rate; if let data = song.artworkData, let image = UIImage(data: data) { info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image } }; MPNowPlayingInfoCenter.default().nowPlayingInfo = info }
}
