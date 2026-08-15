import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../config/player_window_mode.dart';
import '../core/utils/window.dart';
import 'window_title_bar_buttons.dart';

/// Starts playback, in whichever place this machine is set to play.
///
/// Both destinations mount the same `VideoPlayerScreen`; what differs is
/// whether it gets a Flutter engine of its own. Everything a caller has to say
/// about what to play is identical either way, so the choice lives here rather
/// than at seven tap handlers — see [PlayerWindow] for how it is made.
class PlayerLauncher {
  /// Opens the player for a catalog video, or — when [directUrl] is given —
  /// for a stream that exists nowhere in the catalog.
  ///
  /// The direct route is for a pasted link that has been parsed but not
  /// downloaded: there is no videoId to look up, so the title, cover and
  /// address travel with the request instead.
  static Future<void> open(
    BuildContext context, {
    required int videoId,
    required int episodeIndex,
    String? sourceId,
    String? directUrl,
    String? directTitle,
    String? directCoverUrl,
  }) async {
    if (PlayerWindow.inApp) {
      // Read before the await that follows in the window branch, and before
      // any frame can retire this context.
      final location = Uri(
        path: '/player/$videoId',
        queryParameters: {
          'index': '$episodeIndex',
          'sourceId': ?sourceId,
          'directUrl': ?directUrl,
          'directTitle': ?directTitle,
          'directCoverUrl': ?directCoverUrl,
        },
      ).toString();
      context.push(location);
      return;
    }
    await appWindow.openNewWindow(
      size: await WindowHelper.playerSize(),
      // Saved normal-mode top-left; null centers via the window
      // configuration's alignment fallback.
      position: await WindowHelper.savedPlayerPosition(),
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
