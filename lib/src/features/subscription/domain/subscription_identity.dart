import '../../video/domain/play_history.dart' show crossSourceKey;
import 'subscription.dart';

/// Whether the user follows this SHOW, on any catalog.
///
/// Rows are stored per (sourceId, videoId) because that is what a check can be
/// run against — a request needs a catalog and an id to name the show with. But
/// the catalogs share no id space: olevod's 1 and dbku's 1 are unrelated shows,
/// and the same show followed from both detail pages becomes two rows with
/// nothing in common except what it calls itself. So asking the bell about the
/// row for the catalog that happens to be on screen is the wrong question. It
/// reads "not following" on a show the user followed yesterday from the other
/// source, and tapping it then creates the duplicate instead of undoing
/// anything — two rows checking one show, two notifications per episode.
///
/// Identity is [crossSourceKey] — title plus year, exact after whitespace
/// normalisation; its own doc explains why exact rather than fuzzy and why the
/// year cannot be dropped. A row that carries no year is its own key rather
/// than a wildcard: matching it against every year would be precisely the false
/// positive that hands one show's following state to another.
bool isShowSubscribed(
  List<Subscription> subs, {
  required String title,
  String? year,
}) {
  final key = crossSourceKey(title, year);
  // `any` rather than `subscriptionsForShow(...).isNotEmpty` — the bell asks
  // this on every rebuild of every card, and the answer needs no list.
  return subs.any((s) => crossSourceKey(s.title, s.year) == key);
}

/// Every stored row belonging to this show, across catalogs.
///
/// This is what an unfollow has to remove. `SubscriptionRepository.unsubscribe`
/// deletes one (sourceId, videoId) pair, so unfollowing "the" subscription
/// deletes the row for the catalog on screen and leaves the other one due for
/// checks: the show keeps notifying after the user switched it off, from a
/// source they may never have opened, and no subscription is visible anywhere
/// to explain where the notification came from. Escaping that state by hand
/// means finding the other catalog's page for the same show and unfollowing
/// there too — which requires knowing the row exists, which is the one thing
/// the app never told them.
///
/// Returned in the order given. Which row to prefer is the caller's decision —
/// the checker wants the source with the freshest sighting — and sorting here
/// would bury that choice in a helper.
List<Subscription> subscriptionsForShow(
  List<Subscription> subs, {
  required String title,
  String? year,
}) {
  final key = crossSourceKey(title, year);
  return subs.where((s) => crossSourceKey(s.title, s.year) == key).toList();
}

/// Whether ANY of the show's rows carries an update the user has not seen.
///
/// A show that runs on both catalogs does not land on both at the same moment;
/// whichever publishes first is where [Subscription.unread] gets set, and it is
/// not reliably the catalog the user opened. Reading the flag off a single row
/// therefore hides exactly the update the badge exists to announce, and the
/// user finds the new episode by scrolling past it rather than by being told.
///
/// Identity as in [isShowSubscribed]: the badge belongs to the show, so it must
/// be computed over every row the show owns.
bool showHasUnread(
  List<Subscription> subs, {
  required String title,
  String? year,
}) {
  final key = crossSourceKey(title, year);
  return subs.any((s) => s.unread && crossSourceKey(s.title, s.year) == key);
}
