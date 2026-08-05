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
    }
  }
}
