import Foundation

final class MusicLibraryManager {
    static let shared = MusicLibraryManager()
    private(set) var songs: [Song] = []
    private let archiveName = "library.archive"
    private init() {}
    var documentsURL: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    func scan() { songs = (try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]))?.filter { ["mp3", "m4a", "aac", "wav"].contains($0.pathExtension.lowercased()) }.map { MetadataManager.shared.song(for: $0) } ?? []; save() }
    func importFile(at source: URL) throws { let destination = documentsURL.appendingPathComponent(source.lastPathComponent); var target = destination; if FileManager.default.fileExists(atPath: target.path) { target = documentsURL.appendingPathComponent(UUID().uuidString + "-" + source.lastPathComponent) }; try FileManager.default.copyItem(at: source, to: target); scan() }
    func delete(_ song: Song) throws { if FileManager.default.fileExists(atPath: song.url.path) { try FileManager.default.removeItem(at: song.url) }; songs.removeAll { $0.url.path == song.url.path }; save() }
    private func archiveURL() -> URL { documentsURL.appendingPathComponent(archiveName) }
    func save() { try? NSKeyedArchiver.archiveRootObject(songs, toFile: archiveURL().path) }
    func restore() { if let saved = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL().path) as? [Song] { songs = saved.filter { FileManager.default.fileExists(atPath: $0.url.path) } } }
}
