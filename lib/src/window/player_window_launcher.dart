import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../core/utils/window.dart';
import 'window_title_bar_buttons.dart';

class PlayerWindowLauncher {
  static Future<void> open({
    required int videoId,
    required int episodeIndex,
    String? sourceId,
  }) async {
    await appWindow.openNewWindow(
      size: await WindowHelper.playerSize(),
      name: 'player',
      arguments: {
        'videoId': videoId,
        'episodeIndex': episodeIndex,
        'sourceId': sourceId,
        ...{WindowTitleBarButtonsConfig.showButtonsKey: false},
        // ...WindowTitleBarButtonsConfig.closeOnlyArguments(),
      },
    );
  }
}
