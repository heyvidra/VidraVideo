import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/log.dart';
import '../../../window/pet_window.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../video/data/video_repository.dart'
    show disabledDataSourceIdsProvider;
import '../../video/domain/video_collection.dart';
import '../data/subscription_notifier_service.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription.dart';
import '../domain/subscription_identity.dart';

final subscriptionsProvider =
    AsyncNotifierProvider<SubscriptionNotifier, List<Subscription>>(
      SubscriptionNotifier.new,
    );

/// What 订阅 lists: followed shows minus the sources the user switched off.
///
/// Derived, not filtered in the notifier: unfollowing walks every row for a
/// show across sources, and hiding rows from that walk would leave the show
/// still followed under the other catalog. Nothing is deleted — switching the
/// source back on brings the entries back, unread flags included.
final visibleSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>((
  ref,
) {
  final disabled = ref.watch(disabledDataSourceIdsProvider);
  return ref
      .watch(subscriptionsProvider)
      .whenData(
        (all) => all.where((s) => !disabled.contains(s.sourceId)).toList(),
      );
});

/// Unread count for the titlebar badge. Derived rather than queried again, so
/// the badge and the list can never disagree about what is unread — which is
/// why it counts the VISIBLE list: a badge promising updates that the screen
/// below it does not show is the one way those two can still diverge.
final unreadSubscriptionCountProvider = Provider<int>((ref) {
  final subs = ref.watch(visibleSubscriptionsProvider).value ?? const [];
  return subs.where((s) => s.unread).length;
});

/// Whether one show is followed, for the detail page's button.
///
/// Keyed by the SHOW, not by the catalog row — see [isShowSubscribed]. Asking
/// the row for whichever source happens to be on screen answered "not
/// following" on a show followed yesterday from the other catalog, and the tap
/// that followed then created a second row instead of undoing anything.
final isSubscribedProvider =
    Provider.family<bool, ({String title, String? year})>((ref, arg) {
      final subs = ref.watch(subscriptionsProvider).value ?? const [];
      return isShowSubscribed(subs, title: arg.title, year: arg.year);
    });

class SubscriptionNotifier extends AsyncNotifier<List<Subscription>> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  Future<List<Subscription>> build() => _repo.all();

  Future<void> _refresh() async {
    state = AsyncData(await _repo.all());
  }

  /// Follow or unfollow the SHOW, across every catalog that holds it.
  ///
  /// Unfollowing has to span sources or it does not stop anything: the rows are
  /// per (sourceId, videoId), so deleting only the one for the page on screen
  /// leaves the other catalog's row due for checks, and the show keeps
  /// notifying from a source the user may never have opened — with no
  /// subscription visible anywhere to explain where it came from.
  ///
  /// Following still writes a single row, for the catalog the user is looking
  /// at. Subscribing to both would double every notification, and the checker
  /// already carries the other source's progress on that one row
  /// (`crossSeenSourceId`/`crossSeenRemarks`).
  Future<void> toggle(Video video) async {
    final source = video.sourceId;
    if (source == null) return;
    final owned = subscriptionsForShow(
      state.value ?? const [],
      title: video.title,
      year: video.year,
    );
    if (owned.isEmpty) {
      await _repo.subscribe(video);
    } else {
      for (final s in owned) {
        await _repo.unsubscribe(s.sourceId, s.videoId);
      }
    }
    await _refresh();
  }

  Future<void> markRead(Subscription s) async {
    await _repo.markRead(s.sourceId, s.videoId);
    await _refresh();
  }

  Future<void> remove(Subscription s) async {
    await _repo.unsubscribe(s.sourceId, s.videoId);
    await _refresh();
  }

  /// Shows that became unread since the last announcement, so the OS is told
  /// once per batch rather than once per detection pass.
  Future<void> announceUnread(List<Subscription> updated) async {
    if (updated.isEmpty) return;
    await ref.read(subscriptionNotifierServiceProvider).announce(updated);
    await _tellPet(updated);
  }

  /// Lets the desktop pet say the same news, but only when the user already
  /// has it on screen. Opening the pet to deliver a line would turn a toast
  /// into a second, louder notification nobody asked for.
  ///
  /// Best-effort like the toast itself: this rides on every catalog sweep,
  /// and a window that cannot open must not break update detection.
  Future<void> _tellPet(List<Subscription> updated) async {
    if (!Platform.isMacOS) return;
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (!settings.showPet) return;
      await PetWindowLauncher.show(
        mood: PetMood.happy,
        message: tr(
          'subscription.pet_bubble',
          args: [SubscriptionNotifierService.summarise(updated)],
        ),
      );
    } catch (e) {
      logR('Subscription', 'pet announcement failed: $e');
    }
  }

  /// Tier 1: reconcile against a listing the app already fetched.
  ///
  /// Called from catalog loads, so it runs constantly — and costs nothing,
  /// because the videos are already in hand. Only refreshes state when
  /// something actually changed, or every scroll would rebuild the badge.
  Future<void> noticeFromListing(List<Video> videos) async {
    final changed = await _repo.noticeFromListing(videos);
    if (changed.isNotEmpty) {
      await _refresh();
      await announceUnread(changed);
    }
  }
}
