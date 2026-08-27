import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vidra/src/config/ambient_background.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/core/telemetry/frame_metrics.dart';
import 'package:vidra/src/core/utils/log.dart';
import 'package:vidra/src/features/cast/presentation/cast_provider.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';
import 'package:vidra/src/features/video/data/source_latency.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import '../settings/presentation/settings_provider.dart';
import '../subscription/data/subscription_checker.dart';
import '../subscription/presentation/subscription_provider.dart';
import '../../window/pet_window.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../video/presentation/play_history_provider.dart';
import 'widgets/sidebar.dart';
import 'domain/app_navigation_item.dart';
import 'package:vidra/src/features/dashboard/widgets/titlebar.dart';

/// The toolbar pill: the window's top row, with the platform's own window
/// controls sitting on it.
///
/// Its height and top margin are load-bearing on macOS — see
/// `MainFlutterWindow.bitsdojo_window_title_bar_height`, which centres the
/// traffic lights on this pill.
const _pillHeight = 44.0;
const _pillTop = 6.0;

class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _subscriptionTimer;
  ProviderSubscription<AsyncValue<List<DownloadTask>>>? _downloadsSub;
  ProviderSubscription<CastState>? _castSub;
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Frame timings for this window. Here rather than in main(): the shell
    // exists once, in the main window, and it is the only place that knows
    // which screen the frames belong to.
    FrameMetrics.instance.start();
    // Followed shows: one sweep now, then occasionally while the window is
    // open. No background service — a desktop app that is not running has
    // nobody to tell, and the checker's own floor keeps repeated triggers from
    // becoming a poll.
    _checkSubscriptions();
    _subscriptionTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _checkSubscriptions(),
    );
    _restorePet();
    // The pet can die outside the settings screen — its own right-click
    // menu. Without this the showPet setting keeps saying "on" and the pet
    // resurrects on next launch. The subscription lives at library level
    // (pet_window.dart) so the exit interceptor can cancel it — see there.
    petWindowClosedSub = desktopApp.windowClosed.listen(_handleWindowClosed);
    // The pet reacts to app life beyond subscriptions: a finished download
    // and a cast going live each earn a bubble. macOS only, like the pet.
    if (Platform.isMacOS) {
      _downloadsSub = ref.listenManual(downloadTasksProvider, _onDownloads);
      _castSub = ref.listenManual(castStateProvider, _onCast);
    }
  }

  void _onDownloads(
    AsyncValue<List<DownloadTask>>? prev,
    AsyncValue<List<DownloadTask>> next,
  ) {
    // No previous DATA means this is the startup snapshot: tasks that
    // finished in some earlier session must not be re-celebrated.
    final before = prev?.asData?.value;
    final after = next.asData?.value;
    if (before == null || after == null) return;
    final wasCompleted = {
      for (final t in before) t.taskId: t.status == DownloadStatus.completed,
    };
    for (final task in after) {
      final justFinished =
          task.status == DownloadStatus.completed &&
          wasCompleted[task.taskId] == false;
      if (justFinished) {
        _petAnnounce(tr('download.pet_bubble', args: [task.videoTitle]));
        return; // One bubble per wave; the rest would only shout over it.
      }
    }
  }

  void _onCast(CastState? prev, CastState next) {
    if ((prev?.isCasting ?? false) || !next.isCasting) return;
    _petAnnounce(
      tr('cast.pet_bubble', args: [next.device?.name ?? tr('cast.this_tv')]),
    );
  }

  /// Best-effort bubble: only when the pet is on screen, and a window that
  /// cannot open must never break the flow that earned the announcement.
  Future<void> _petAnnounce(String message) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (!settings.showPet) return;
      await PetWindowLauncher.show(mood: PetMood.happy, message: message);
    } catch (e) {
      logR('Pet', 'announcement failed: $e');
    }
  }

  Future<void> _handleWindowClosed(String name) async {
    if (name != PetWindowLauncher.windowName) return;
    // A rapid off->on flip can land this broadcast AFTER the user already
    // reopened the pet; a live pet means the close it reports is old news.
    if (await desktopApp.hasWindow(PetWindowLauncher.windowName)) return;
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (!settings.showPet) return;
    settings.showPet = false;
    await repo.updateSettings(settings);
  }

  /// Brings the desktop pet back if it was on when the app last closed.
  ///
  /// Here rather than in main(): this screen exists only in the main window,
  /// so the player and pet engines — which run the same main() — cannot
  /// trigger it and spawn a second pet.
  Future<void> _restorePet() async {
    // macOS only, like every other pet entry point: elsewhere the window
    // renders opaque and cannot be closed by name.
    if (!Platform.isMacOS) return;
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!mounted || !settings.showPet) return;
      await PetWindowLauncher.show();
      logR('Pet', 'restore: pet window requested');
      // The 1.11.x CI binaries sometimes lost the request itself to a
      // startup race — no window, no error. Verify and re-ask once; the
      // native side reuses by name, so a retry can never spawn a second pet.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!await desktopApp.hasWindow(PetWindowLauncher.windowName)) {
        logR('Pet', 'restore: window missing after 2s — retrying once');
        await PetWindowLauncher.show();
      }
    } catch (e) {
      // An error here used to vanish into the release zone handler — which
      // is how an invisible pet shipped twice. Say it, always.
      logR('Pet', 'restore failed: $e');
    }
  }

  Future<void> _checkSubscriptions() async {
    final updated = await ref.read(subscriptionCheckerProvider).run();
    if (updated.isEmpty || !mounted) return;
    ref.invalidate(subscriptionsProvider);
    await ref.read(subscriptionsProvider.notifier).announceUnread(updated);
  }

  @override
  void dispose() {
    FrameMetrics.instance.stop();
    _subscriptionTimer?.cancel();
    _downloadsSub?.close();
    _castSub?.close();
    petWindowClosedSub?.cancel();
    petWindowClosedSub = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the main window gains focus again (e.g. after closing the player window)
    if (state == AppLifecycleState.resumed) {
      ref.read(playHistoryProvider.notifier).manualRefresh();
      _checkSubscriptions();
    }
    // A put-away app draws nothing, so no later frame batch would arrive to
    // close the window that just ended.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      FrameMetrics.instance.flush();
    }
  }

  /// Which screen the frames being drawn belong to, as one of a fixed set of
  /// literals.
  ///
  /// The location itself must never reach diagnostics: `/detail/83579` and
  /// `/search/<term>` are exactly the viewing history this app does not
  /// collect. Every value returned here is written in this file, and anything
  /// unrecognised becomes 'other' rather than something derived from the URI.
  static String _screenLabel(String location) {
    if (location == '/') return 'catalog';
    if (location.startsWith('/detail/')) return 'detail';
    if (location.startsWith('/search/')) return 'search';
    if (location.startsWith('/downloads')) return 'downloads';
    if (location.startsWith('/download-url')) return 'download_url';
    if (location.startsWith('/recent')) return 'recent';
    if (location.startsWith('/subscriptions')) return 'subscriptions';
    if (location.startsWith('/favorites')) return 'favorites';
    if (location.startsWith('/settings')) return 'settings';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location != _lastLocation) {
      _lastLocation = location;
      // A field on the collector: nothing is notified and nothing rebuilds.
      FrameMetrics.instance.setScreen(_screenLabel(location));
    }
    // The one toolbar. A detail page used to bring its own, eight pixels below
    // this one and carrying a second search field.
    final canGoBack =
        location.contains('/detail/') ||
        location.startsWith('/search/') ||
        location == '/pet-demo';

    return Scaffold(
      // Painted by AmbientBackground instead: every translucent surface in the
      // app is standing in the light it casts, and a Scaffold colour under it
      // would just be a second opaque layer to punch through.
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: WindowBorder(
          color: Colors.transparent,
          width: 1,
          // The window is one column: the toolbar pill, then the rail and the
          // content side by side, then the status line. The rail starts BELOW
          // the toolbar — a full-height rail put the search box in the
          // content's column, where it read as belonging to the page rather
          // than to the window.
          child: Column(
            children: [
              _TopBar(
                showBack: canGoBack,
                onSearchSubmitted: (value) {
                  if (value.isNotEmpty) context.push('/search/$value');
                },
                onHomeRequested: () => context.go('/'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  // Stretch, or the rail sizes to its rows and floats in the
                  // vertical middle of the window.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Sidebar(
                        selected: AppNavigationItem.forLocation(location),
                        onSelect: (item) => context.go(item.route),
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ),
              const AppStatusBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The window's top row: one pill carrying the platform's window controls and
/// the app's own.
///
/// The pill used to sit BELOW a separate 46px strip that held nothing but the
/// traffic lights and the wordmark — two bars of chrome where the window needs
/// one. Every platform's window controls are ON this pill now: macOS centres
/// its traffic lights on it (see [MainFlutterWindow]) at the left, Windows and
/// Linux get theirs at the right, drawn in the app's own icon family.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.onSearchSubmitted,
    required this.onHomeRequested,
  });

  final bool showBack;
  final void Function(String) onSearchSubmitted;
  final VoidCallback onHomeRequested;

  @override
  Widget build(BuildContext context) {
    final mac = Platform.isMacOS;
    final bar = DashboardTitleBar(
      showBack: showBack,
      // Nothing of ours may be drawn under the traffic lights.
      leadingInset: mac ? 78 : 14,
      onSearchSubmitted: onSearchSubmitted,
      onHomeRequested: onHomeRequested,
    );

    // MoveWindow alone, without WindowTitleBarBox: that widget's only job is
    // to reserve the platform title-bar HEIGHT, and this row sets its own —
    // wrapped in one, the 44pt pill would be squeezed into Windows' 32pt band.
    //
    // The pill spans the full width on every platform; Windows' own
    // minimise/maximise/close live INSIDE it, after the language switcher,
    // rather than loose in the corner in a different icon family.
    return SizedBox(
      height: _pillTop + _pillHeight + 10,
      child: MoveWindow(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, _pillTop, 14, 10),
          child: bar,
        ),
      ),
    );
  }
}

/// The strip a desktop app has and a web page does not.
///
/// It answers two questions that otherwise send someone hunting: which catalog
/// am I browsing, and is anything waiting for me. Both were already known to
/// the app and neither had anywhere to be said — the source only showed inside
/// a dropdown, and the unread count only on a nav badge you had to be looking
/// at the sidebar to see.
class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final source = ref.watch(activeDataSourceProvider);
    final subs = ref.watch(unreadSubscriptionCountProvider);
    // This bar sits on every shell screen and downloadTasksProvider emits on
    // every progress notification, so the watch is narrowed to the one number
    // the bar renders — an emission that leaves the count unchanged must
    // rebuild nothing.
    final active = ref.watch(
      downloadTasksProvider.select(
        (tasks) => tasks.maybeWhen(
          data: (list) => list
              .where((t) => t.status == DownloadStatus.downloading)
              .length,
          orElse: () => 0,
        ),
      ),
    );

    final style = TextStyle(
      fontSize: 10.5,
      height: 1.4,
      letterSpacing: 0.2,
      color: t.fg3,
      fontFeatures: VidraType.data,
    );

    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(
          children: [
            // Every enabled source with its round trip, so "which one is
            // quick today" is answerable without switching to each in turn.
            // The active one keeps the dot it always had.
            ...ref
                .watch(sourceLatencyProvider)
                .maybeWhen(
                  data: (all) => [
                    for (final entry in all)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _SourceLatencyChip(
                          entry: entry,
                          isActive: entry.sourceId == source.id,
                          style: style,
                        ),
                      ),
                  ],
                  // Measuring, or it failed outright: fall back to what this
                  // bar said before latency existed rather than to nothing.
                  orElse: () => [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: t.cyan,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: t.cyanGlow, blurRadius: 10),
                        ],
                      ),
                    ),
                    Text(source.name, style: style),
                  ],
                ),
            // After the chips, not before: it acts on the row to its left.
            // Only offered once there are numbers to re-measure — during the
            // first probe the fallback dot is showing and there is nothing to
            // refresh yet.
            if (ref.watch(sourceLatencyProvider).hasValue)
              const _LatencyRefreshButton(),
            if (active > 0) ...[
              const SizedBox(width: 18),
              Text(
                tr('download.active_count', args: ['$active']),
                style: style,
              ),
            ],
            const Spacer(),
            if (subs > 0)
              Text(
                tr('subscription.updates_waiting', args: ['$subs']),
                style: style.copyWith(color: t.amber),
              ),
          ],
        ),
      ),
    );
  }
}

/// Re-measures every source's round trip, at most once a minute.
///
/// The rule itself lives in [SourceLatencyNotifier.cooldown] — this only
/// mirrors it, because a disabled-looking button that still fires is worse
/// than either half alone. What this widget owns is the moment the button
/// comes BACK: nothing emits an event when a cooldown lapses, so it holds a
/// timer whose only job is to rebuild then.
class _LatencyRefreshButton extends ConsumerStatefulWidget {
  const _LatencyRefreshButton();

  @override
  ConsumerState<_LatencyRefreshButton> createState() =>
      _LatencyRefreshButtonState();
}

class _LatencyRefreshButtonState extends ConsumerState<_LatencyRefreshButton>
    with SingleTickerProviderStateMixin {
  Timer? _cooldownTimer;

  /// Spins while a probe is in flight.
  ///
  /// Driven from here rather than off the provider's `isLoading`: [refresh]
  /// assigns `AsyncData` straight over the old value on purpose, so the last
  /// numbers stay on screen instead of blanking, and the provider therefore
  /// never reports loading at all. The one thing that DOES know a probe is
  /// running is the await below.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _probing = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  /// Rebuilds when the current cooldown ends, so the icon un-dims by itself
  /// instead of waiting for the next unrelated rebuild of this bar.
  void _armFor(DateTime until) {
    _cooldownTimer?.cancel();
    final left = until.difference(DateTime.now());
    if (left.isNegative) return;
    _cooldownTimer = Timer(left, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final notifier = ref.read(sourceLatencyProvider.notifier);
    // Watched so a probe finishing elsewhere — the enabled set changing, say,
    // which re-stamps the cooldown — reaches this button without it having to
    // be told.
    ref.watch(sourceLatencyProvider);
    final until = notifier.nextRefreshAt;
    final enabled = until == null && !_probing;
    if (until != null) _armFor(until);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: enabled
            ? tr('dashboard.latency.refresh')
            : tr('dashboard.latency.refresh_wait'),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: enabled
                ? () async {
                    setState(() => _probing = true);
                    _spin.repeat();
                    try {
                      await notifier.refresh();
                    } finally {
                      _spin.stop();
                      // Back to upright, so the icon never rests at whatever
                      // angle the probe happened to finish on.
                      _spin.value = 0;
                      final next = notifier.nextRefreshAt;
                      if (next != null) _armFor(next);
                      if (mounted) setState(() => _probing = false);
                    }
                  }
                : null,
            child: RotationTransition(
              turns: _spin,
              child: Icon(
                Icons.refresh_rounded,
                size: 13,
                // Dimmed rather than hidden: a control that vanishes for a
                // minute reads as a glitch, and its absence would also shuffle
                // everything on this row sideways twice a minute.
                color: enabled ? t.fg2 : t.fg3.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One source's name and round trip, behind a signal glyph.
class _SourceLatencyChip extends StatelessWidget {
  const _SourceLatencyChip({
    required this.entry,
    required this.isActive,
    required this.style,
  });

  final SourceLatency entry;
  final bool isActive;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final bars = latencyBars(entry.millis);
    // Colour says reachability, the bars say how fast. Two channels rather
    // than one so the row still reads with the colours washed out.
    final tint = !entry.reachable
        ? t.clash
        : bars >= 3
        ? t.cyan
        : t.amber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SignalBars(filled: bars, tint: tint, dim: t.fg4),
        const SizedBox(width: 6),
        Text(
          entry.name,
          // The active source is the one the catalog below is showing, and
          // that has to stay legible at a glance in a row of four names.
          style: isActive
              ? style.copyWith(color: t.fg, fontWeight: FontWeight.w600)
              : style,
        ),
        const SizedBox(width: 5),
        Text(
          entry.reachable
              ? tr('source.latency_ms', args: ['${entry.millis}'])
              : tr('source.latency_unreachable'),
          style: style.copyWith(color: tint),
        ),
      ],
    );
  }
}

/// Four rising bars, [filled] of them lit.
class _SignalBars extends StatelessWidget {
  const _SignalBars({
    required this.filled,
    required this.tint,
    required this.dim,
  });

  final int filled;
  final Color tint;
  final Color dim;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 2,
            height: 3.0 + i * 2.0,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 1.5),
            decoration: BoxDecoration(
              color: i < filled ? tint : dim,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}
