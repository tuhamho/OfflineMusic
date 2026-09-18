import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { MusicLibraryManager.shared.restore(); MusicLibraryManager.shared.scan(); MusicPlayerManager.shared.restoreCurrentSong(); window = UIWindow(frame: UIScreen.main.bounds); let nav = UINavigationController(rootViewController: ViewController()); window?.rootViewController = nav; window?.makeKeyAndVisible(); return true }
    func applicationDidEnterBackground(_ application: UIApplication) { MusicPlayerManager.shared.savePlaybackState() }
}
