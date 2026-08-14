import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

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
      // The cast lives in the main engine, and the power assertion is
      // process-wide, so this channel belongs on this engine alone.
      SleepBlocker.register(with: flutterViewController.engine.binaryMessenger)
    }
  }
}

/// Keeps the Mac awake while it is serving a cast — the Mac, not its screen.
///
/// Casting makes this machine the media server: the television pulls every
/// segment from a local HTTP server here, so a system sleep freezes the
/// process and the picture stops. The obvious fix is the wrong one —
/// `wakelock_plus` asserts `NoDisplaySleep`, which leaves the display lit all
/// evening for a video playing in another room.
///
/// `NoIdleSleep` is the assertion that matches what casting needs: the
/// display sleeps on its usual schedule, the system stays up, the stream
/// keeps flowing. Closing the lid still sleeps the machine and still drops
/// the cast; no assertion overrides a sleep the user asked for.
///
/// Lives in this file rather than its own because a new file under
/// `macos/Runner/` is not in the Xcode target until `project.pbxproj` says
/// so, and hand-editing that to add sixty lines is a worse trade than
/// keeping process-wide helpers together — which is already the pattern
/// below.
final class SleepBlocker {
  static let shared = SleepBlocker()

  private var assertionID: IOPMAssertionID = 0
  private var held = false

  /// Idempotent: a second cast starting before the first is torn down must
  /// not leak an assertion that nothing will ever release.
  func hold(reason: String) -> Bool {
    if held { return true }
    var id: IOPMAssertionID = 0
    let result = IOPMAssertionCreateWithName(
      kIOPMAssertionTypeNoIdleSleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason as CFString,
      &id
    )
    guard result == kIOReturnSuccess else { return false }
    assertionID = id
    held = true
    return true
  }

  func release() {
    guard held else { return }
    IOPMAssertionRelease(assertionID)
    assertionID = 0
    held = false
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "vidra/sleep_blocker",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "hold":
        let reason = (call.arguments as? [String: Any])?["reason"] as? String
        result(shared.hold(reason: reason ?? "Vidra is casting"))
      case "release":
        shared.release()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
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
