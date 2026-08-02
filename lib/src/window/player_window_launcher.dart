import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../core/utils/window.dart';
import 'window_title_bar_buttons.dart';

class PlayerWindowLauncher {
  /// Opens the player for a catalog video, or — when [directUrl] is given —
  /// for a stream that exists nowhere in the catalog.
  ///
  /// The direct route is for a pasted link that has been parsed but not
  /// downloaded: there is no videoId to look up, so the title, cover and
  /// address travel with the request instead.
  static Future<void> open({
    required int videoId,
    required int episodeIndex,
    String? sourceId,
    String? directUrl,
    String? directTitle,
    String? directCoverUrl,
  }) async {
    await appWindow.openNewWindow(
      size: await WindowHelper.playerSize(),
      name: 'player',
      arguments: {
        'videoId': videoId,
        'episodeIndex': episodeIndex,
        'sourceId': sourceId,
        'directUrl': ?directUrl,
        'directTitle': ?directTitle,
        'directCoverUrl': ?directCoverUrl,
        ...{WindowTitleBarButtonsConfig.showButtonsKey: false},
        // ...WindowTitleBarButtonsConfig.closeOnlyArguments(),
      },
    );
  }
}
