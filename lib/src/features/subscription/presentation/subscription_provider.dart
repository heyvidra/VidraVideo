import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../video/domain/video_collection.dart';
import '../data/subscription_notifier_service.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription.dart';

final subscriptionsProvider =
    AsyncNotifierProvider<SubscriptionNotifier, List<Subscription>>(
      SubscriptionNotifier.new,
    );

/// Unread count for the titlebar badge. Derived rather than queried again, so
/// the badge and the list can never disagree about what is unread.
final unreadSubscriptionCountProvider = Provider<int>((ref) {
  final subs = ref.watch(subscriptionsProvider).value ?? const [];
  return subs.where((s) => s.unread).length;
});

/// Whether one show is followed, for the detail page's button.
final isSubscribedProvider =
    Provider.family<bool, ({String? sourceId, int videoId})>((ref, arg) {
      final source = arg.sourceId;
      if (source == null) return false;
      final subs = ref.watch(subscriptionsProvider).value ?? const [];
      return subs.any((s) => s.sourceId == source && s.videoId == arg.videoId);
    });

class SubscriptionNotifier extends AsyncNotifier<List<Subscription>> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  Future<List<Subscription>> build() => _repo.all();

  Future<void> _refresh() async {
    state = AsyncData(await _repo.all());
  }

  Future<void> toggle(Video video) async {
    final source = video.sourceId;
    if (source == null) return;
    final existing = await _repo.find(source, video.apiId);
    if (existing == null) {
      await _repo.subscribe(video);
    } else {
      await _repo.unsubscribe(source, video.apiId);
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
