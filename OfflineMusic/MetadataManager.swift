import Foundation
import AVFoundation

final class MetadataManager {
    static let shared = MetadataManager()
    private init() {}
    func song(for url: URL) -> Song {
        let asset = AVURLAsset(url: url)
        var title: String?; var artist: String?; var album: String?; var artwork: Data?
        for item in asset.commonMetadata {
            guard let key = item.commonKey?.rawValue else { continue }
            if key == "title" { title = item.stringValue }
            if key == "artist" { artist = item.stringValue }
            if key == "albumName" { album = item.stringValue }
            if key == "artwork", let data = item.dataValue { artwork = data }
        }
        let fallback = url.deletingPathExtension().lastPathComponent
        let duration = CMTimeGetSeconds(asset.duration).isFinite ? CMTimeGetSeconds(asset.duration) : 0
        return Song(id: url.standardizedFileURL.path, url: url, title: title?.isEmpty == false ? title! : fallback, artist: artist?.isEmpty == false ? artist! : "Unknown Artist", album: album?.isEmpty == false ? album! : "Unknown Album", artworkData: artwork, duration: duration)
    }
}
