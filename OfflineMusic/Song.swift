import Foundation

final class Song: NSObject, NSCoding {
    let id: String
    let url: URL
    var title: String
    var artist: String
    var album: String
    var artworkData: Data?
    var duration: TimeInterval

    init(id: String = UUID().uuidString, url: URL, title: String, artist: String, album: String, artworkData: Data?, duration: TimeInterval) {
        self.id = id; self.url = url; self.title = title; self.artist = artist; self.album = album; self.artworkData = artworkData; self.duration = duration
    }
    required init?(coder: NSCoder) {
        guard let id = coder.decodeObject(forKey: "id") as? String, let path = coder.decodeObject(forKey: "path") as? String else { return nil }
        self.id = id; self.url = URL(fileURLWithPath: path); self.title = coder.decodeObject(forKey: "title") as? String ?? self.url.deletingPathExtension().lastPathComponent
        self.artist = coder.decodeObject(forKey: "artist") as? String ?? "Unknown Artist"; self.album = coder.decodeObject(forKey: "album") as? String ?? "Unknown Album"
        self.artworkData = coder.decodeObject(forKey: "artwork") as? Data; self.duration = coder.decodeDouble(forKey: "duration")
    }
    func encode(with coder: NSCoder) { coder.encode(id, forKey: "id"); coder.encode(url.path, forKey: "path"); coder.encode(title, forKey: "title"); coder.encode(artist, forKey: "artist"); coder.encode(album, forKey: "album"); coder.encode(artworkData, forKey: "artwork"); coder.encode(duration, forKey: "duration") }
}
