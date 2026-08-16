import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra/src/config/ambient_background.dart';
import 'package:vidra/src/common/bar_controls.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/config/reduce_effects.dart';
import '../../../core/providers/theme_provider.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'package:vidra/src/features/settings/presentation/settings_provider.dart';
import 'package:vidra/src/window/pet_window.dart';

import 'data_source_switcher.dart';
import 'language_switcher.dart';
import '../../subscription/presentation/widgets/subscription_bell.dart';
import '../../video/presentation/search_history_provider.dart';

/// The window's one toolbar: `.pillbar` in the design.
///
/// A single glass pill spanning the window, carrying the back affordance on
/// the left, the search field beside it, and the window's controls on the
/// right. There is exactly one of these — a detail page used to add a second
/// toolbar of its own with a second search field in it.
class DashboardTitleBar extends ConsumerStatefulWidget {
  final void Function(String) onSearchSubmitted;
  final VoidCallback? onHomeRequested;

  /// Whether this route has somewhere to go back to.
  final bool showBack;

  /// Space kept clear at the pill's left edge for the platform's own window
  /// controls — the macOS traffic lights sit ON this bar.
  final double leadingInset;

  const DashboardTitleBar({
    super.key,
    required this.onSearchSubmitted,
    this.onHomeRequested,
    this.showBack = false,
    this.leadingInset = 14,
  });

  @override
  ConsumerState<DashboardTitleBar> createState() => _DashboardTitleBarState();
}

class _DashboardTitleBarState extends ConsumerState<DashboardTitleBar> {
  bool isAlwaysOnTop = false;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _historyLink = LayerLink();
  final _historyOverlay = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    // The dropdown exists exactly while the field has focus; what it shows
    // (filtered by the current text) is the overlay's own business.
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        _historyOverlay.show();
      } else {
        _historyOverlay.hide();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final kw = value.trim();
    if (kw.isEmpty) return;
    ref.read(searchHistoryProvider.notifier).push(kw);
    _searchFocus.unfocus();
    widget.onSearchSubmitted(kw);
  }

  /// Opening the pet from here must also RECORD it: showPet is the app's
  /// only notion of whether the pet is on screen, and a pet opened without
  /// it gets no subscription bubbles and no restore on next launch.
  Future<void> _showPet() async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (!settings.showPet) {
      settings.showPet = true;
      await repo.updateSettings(settings);
    }
    await PetWindowLauncher.show();
  }

  void _toggleAlwaysOnTop() {
    setState(() {
      isAlwaysOnTop = !isAlwaysOnTop;
      appWindow.alwaysOnTop = isAlwaysOnTop;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = VidraTokens.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduce = ref.watch(reduceEffectsProvider);

    return GlassPanel(
      radius: 999,
      blur: 12,
      border: t.edgeSoft,
      shadow: t.drop1,
      // The pill has its own row of the shell Column — nothing ever scrolls
      // or animates beneath it, only the static ambient washes, over which
      // the blur is visually the identity. So the pill keeps the saturation
      // that makes it glass and skips the Gaussian that Skia would otherwise
      // re-run on every rasterized frame; 减少特效 drops the readback too.
      staticBackdrop: true,
      flat: reduce,
      padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
      child: Row(
        children: [
          SizedBox(width: widget.leadingInset),
          // The wordmark names the WINDOW, so it belongs on the window's bar.
          Text(
            'VIDRA',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.3,
              color: t.fg2,
            ),
          ),
          const SizedBox(width: 14),
          if (widget.showBack) ...[
            _PillButton(
              label: tr('common.back'),
              icon: Icons.chevron_left_rounded,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: 10),
          ],
          // The search field, left-aligned with the rest of the bar rather
          // than centred: centred, it drifted away from the back button it
          // sits next to and left a hole on both sides at wide window sizes.
          //
          // Flexible, and with no minimum, because it is the ONE elastic thing
          // on this bar — everything else is an icon, a wordmark or a source
          // name, none of which can give up a pixel. It used to hold a 180
          // floor, so a narrow window had nothing left to take from and the row
          // overflowed by exactly what that floor would not surrender, silently
          // clipping the controls on the right. The minimum window size is 60%
          // of the SCREEN, not a fixed width, so there is no width this bar can
          // assume; it has to be able to shrink instead.
          Flexible(
            child: CompositedTransformTarget(
              link: _historyLink,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Icon(Icons.search, color: t.fg3, size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OverlayPortal(
                          controller: _historyOverlay,
                          overlayChildBuilder: (context) => _HistoryDropdown(
                            link: _historyLink,
                            controller: _searchController,
                            onPick: _submit,
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            style: TextStyle(color: t.fg, fontSize: 13),
                            cursorColor: t.cyan,
                            decoration: InputDecoration(
                              hintText: tr('dashboard.search_hint'),
                              hintStyle: TextStyle(color: t.fg3, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: _submit,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          DataSourceSwitcher(onDataSourceChanged: widget.onHomeRequested),
          const SizedBox(width: 8),
          const SubscriptionBell(),
          // macOS only: elsewhere the pet window renders opaque and cannot
          // be closed by name, so the door stays shut until those platforms
          // get their own pass.
          if (Platform.isMacOS)
            BarIcon(
              icon: Icons.pets_outlined,
              tooltip: tr('dashboard.show_pet'),
              // Opening an already-open pet just brings it forward: the
              // native side reuses windows by name.
              onTap: _showPet,
            ),
          BarIcon(
            // Outlined even when active — the colour says "on", and a filled
            // glyph beside four outlined ones reads as a different family
            // rather than a different state.
            icon: Icons.push_pin_outlined,
            active: isAlwaysOnTop,
            tooltip: isAlwaysOnTop
                ? tr('dashboard.unpin_from_top')
                : tr('dashboard.pin_to_top'),
            onTap: _toggleAlwaysOnTop,
          ),
          BarIcon(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: isDark
                ? tr('dashboard.switch_to_light_mode')
                : tr('dashboard.switch_to_dark_mode'),
            onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const LanguageSwitcher(),
          // Windows and Linux keep their minimise/maximise/close here, at the
          // end of the same row rather than loose in the corner: they are the
          // window's controls and so is everything to their left. macOS has
          // its own, on the other end of this bar.
          if (!Platform.isMacOS) ...[
            const SizedBox(width: 2),
            const _WindowControls(),
          ],
        ],
      ),
    );
  }
}

/// Minimise, maximise, close — drawn in the app's own icon family rather than
/// bitsdojo's, so they match the four controls they sit beside instead of
/// arriving with their own size, colour and hover.
///
/// Close must REQUEST, not act: `appWindow.close()` is the definitive close —
/// it clears the native close-requested callback before posting SC_CLOSE
/// (so a confirmed close doesn't re-ask), which meant this button skipped
/// the exit-confirm dialog entirely and the window just died. Going through
/// the `onClose` slot runs the same chain a native close request does:
/// WindowEventListener → the app's `onCloseRequested` interceptor → dialog.
class _WindowControls extends StatefulWidget {
  const _WindowControls();

  @override
  State<_WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<_WindowControls> {
  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BarIcon(
          icon: Icons.remove_rounded,
          tooltip: tr('dashboard.minimize'),
          onTap: appWindow.minimize,
        ),
        BarIcon(
          icon: appWindow.isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
          tooltip: appWindow.isMaximized
              ? tr('dashboard.restore')
              : tr('dashboard.maximize'),
          onTap: () => setState(appWindow.maximizeOrRestore),
        ),
        BarIcon(
          icon: Icons.close_rounded,
          tooltip: tr('common.close'),
          hoverTone: t.clash,
          // Hard close only as the fallback for a window with no listener.
          onTap: () => (appWindow.onClose ?? appWindow.close)(),
        ),
      ],
    );
  }
}

/// Recent searches under the field, alive exactly while the field has focus.
///
/// [TextFieldTapRegion] keeps a tap on a row from blurring the field before
/// the row's handler runs; a tap anywhere else still blurs, which is what
/// dismisses the panel. Rows live-filter against what has been typed, so the
/// panel doubles as a poor man's autocomplete over past searches.
class _HistoryDropdown extends ConsumerWidget {
  const _HistoryDropdown({
    required this.link,
    required this.controller,
    required this.onPick,
  });

  final LayerLink link;
  final TextEditingController controller;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final history = ref.watch(searchHistoryProvider).value ?? const <String>[];

    return Positioned(
      width: 320,
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        showWhenUnlinked: false,
        child: TextFieldTapRegion(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final q = value.text.trim().toLowerCase();
              final matches = [
                for (final h in history)
                  if (q.isEmpty || h.toLowerCase().contains(q)) h,
              ];
              if (matches.isEmpty) return const SizedBox.shrink();

              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    // barBg, not glass: the panel floats over whatever the
                    // page is showing and has to stay readable on top of it.
                    color: t.barBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.edge),
                    boxShadow: t.drop2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final h in matches)
                        InkWell(
                          onTap: () {
                            controller.text = h;
                            onPick(h);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 15,
                                  color: t.fg3,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    h,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: t.fg2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Divider(height: 12, thickness: 0.5, color: t.edgeSoft),
                      InkWell(
                        onTap: () =>
                            ref.read(searchHistoryProvider.notifier).clear(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            tr('dashboard.clear_search_history'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: t.fg3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// `.btn` — a pill inside the pill.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 14, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.edgeSoft),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: t.glass2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: t.fg),
              const SizedBox(width: 2),
              Text(label, style: TextStyle(fontSize: 13, color: t.fg)),
            ],
          ),
        ),
      ),
    );
  }
}
