import 'package:bitsdojo_window/bitsdojo_window.dart';

enum WindowTitleBarButtonsMode {
  hidden('hidden'),
  closeOnly('closeOnly'),
  all('all'),
  custom('custom');

  const WindowTitleBarButtonsMode(this.value);

  final String value;

  static WindowTitleBarButtonsMode? fromValue(Object? value) {
    if (value is! String) return null;
    for (final mode in values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return null;
  }
}

class WindowTitleBarButtonsConfig {
  const WindowTitleBarButtonsConfig._();

  static const showButtonsKey = 'showTitleBarButtons';
  static const modeKey = 'titleBarButtonsMode';
  static const visibleButtonsKey = 'visibleTitleBarButtons';

  static const _allButtons = <DesktopWindowButton>{
    DesktopWindowButton.close,
    DesktopWindowButton.minimize,
    DesktopWindowButton.zoom,
  };

  static Map<String, dynamic> closeOnlyArguments() {
    return const {showButtonsKey: true, modeKey: 'closeOnly'};
  }

  static Map<DesktopWindowButton, bool> resolve(
    Map<String, dynamic>? arguments, {
    Set<DesktopWindowButton> defaultVisibleButtons = const {},
  }) {
    final showButtons = arguments?[showButtonsKey];
    if (showButtons == false) {
      return _visibilityFor(const {});
    }

    final explicitButtons = _parseButtons(arguments?[visibleButtonsKey]);
    if (explicitButtons != null) {
      return _visibilityFor(explicitButtons);
    }

    final mode = WindowTitleBarButtonsMode.fromValue(arguments?[modeKey]);
    if (mode != null) {
      return switch (mode) {
        WindowTitleBarButtonsMode.hidden => _visibilityFor(const {}),
        WindowTitleBarButtonsMode.closeOnly => _visibilityFor(const {
          DesktopWindowButton.close,
        }),
        WindowTitleBarButtonsMode.all => _visibilityFor(_allButtons),
        WindowTitleBarButtonsMode.custom => _visibilityFor(
          defaultVisibleButtons,
        ),
      };
    }

    if (showButtons == true) {
      return _visibilityFor(_allButtons);
    }

    return _visibilityFor(defaultVisibleButtons);
  }

  static Set<DesktopWindowButton>? _parseButtons(Object? rawValue) {
    if (rawValue is! List) return null;

    final buttons = <DesktopWindowButton>{};
    for (final value in rawValue) {
      final button = _buttonFromValue(value);
      if (button != null) {
        buttons.add(button);
      }
    }
    return buttons;
  }

  static DesktopWindowButton? _buttonFromValue(Object? value) {
    return switch (value) {
      'close' => DesktopWindowButton.close,
      'minimize' => DesktopWindowButton.minimize,
      'zoom' => DesktopWindowButton.zoom,
      _ => null,
    };
  }

  static Map<DesktopWindowButton, bool> _visibilityFor(
    Set<DesktopWindowButton> visibleButtons,
  ) {
    return {
      DesktopWindowButton.close: visibleButtons.contains(
        DesktopWindowButton.close,
      ),
      DesktopWindowButton.minimize: visibleButtons.contains(
        DesktopWindowButton.minimize,
      ),
      DesktopWindowButton.zoom: visibleButtons.contains(
        DesktopWindowButton.zoom,
      ),
    };
  }
}
