import Cocoa
import FlutterMacOS

import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {
  override func bitsdojo_window_configure() -> UInt {
    return BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP
  }

  /// Where macOS centres the traffic lights vertically.
  ///
  /// The toolbar pill is the top row now and the lights sit ON it, so this has
  /// to agree with where that pill's centre lands: 6pt of top margin plus a
  /// 44pt pill centres at 28, and the system centres the buttons at half this
  /// number. Move the pill's geometry and this moves with it.
  override func bitsdojo_window_title_bar_height() -> Double {
    return 56.0
  }

  override func setupFlutter() {
    super.setupFlutter()

    // Register plugins for this window's Flutter engine
    if let flutterViewController = self.contentViewController as? FlutterViewController {
      RegisterGeneratedPlugins(registry: flutterViewController)
      // ...which just pointed the notification centre at a per-engine object.
      // Take it back before that object can outlive its window.
      NotificationCenterDelegate.takeOver()
    }
  }
}

/// Owns `NSUserNotificationCenter`'s delegate for the life of the process.
///
/// local_notifier's plugin makes itself the delegate in `init`, and that
/// property is `assign` — unowned and unchecked. Every player window builds its
/// own engine, so closing one frees the plugin the notification centre is still
/// pointing at, and the next delivered notification messages freed memory
/// (crash: objc_opt_respondsToSelector, SIGTRAP — hours after the window
/// closed, when a subscription update fires).
///
/// ponytail: only `shouldPresent` is reimplemented, so banners still show while
/// Vidra is frontmost. The plugin's show/click/close callbacks stop reaching
/// Dart — nothing here listens to them. Wire them back through this object if
/// something ever does.
@available(macOS, deprecated: 11.0, message: "Mirrors local_notifier's NSUserNotification use.")
final class NotificationCenterDelegate: NSObject, NSUserNotificationCenterDelegate {
  static let shared = NotificationCenterDelegate()

  static func takeOver() {
    NSUserNotificationCenter.default.delegate = shared
  }

  func userNotificationCenter(
    _ center: NSUserNotificationCenter,
    shouldPresent notification: NSUserNotification
  ) -> Bool {
    return true
  }
}
