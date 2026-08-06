/// How one catalog stands against the one currently feeding the grid.
///
/// The pill used to render "this row's timestamp is newer" as 快 — faster.
/// Those are opposites. When two catalogs carry the SAME episode count, the
/// one whose row is newer is the one that only just caught up; the catalog
/// that reached that count hours ago is the fast one. Olevod had episode 16
/// first and dbku posted it minutes later, and the bar said dbku was 9 hours
/// faster.
///
/// So: exactly one claim, whichever the data supports.
///  - Different counts — the delta IS the answer. A timestamp comparison on
///    top of it adds nothing and can contradict it.
///  - Same count — the older row got there first.
class SourceLead {
  const SourceLead({this.episodeDelta, this.arrivedEarlierBy});

  /// This catalog's episode count minus the reference's, when they differ.
  final int? episodeDelta;

  /// How far ahead of the reference this catalog reached the shared count.
  /// Negative means it got there later. Null when the counts differ or
  /// neither row carries a usable timestamp.
  final Duration? arrivedEarlierBy;

  bool get isEmpty => episodeDelta == null && arrivedEarlierBy == null;
}

/// [ourVodTime] / [theirVodTime] are the catalogs' own "last changed" stamps,
/// in seconds. Zero and null both mean "this catalog does not say".
SourceLead compareSourceRows({
  required int ourEpisodes,
  required int theirEpisodes,
  int? ourVodTime,
  int? theirVodTime,
}) {
  if (ourEpisodes != theirEpisodes) {
    return SourceLead(episodeDelta: ourEpisodes - theirEpisodes);
  }

  final ours = (ourVodTime ?? 0) > 0 ? ourVodTime! : null;
  final theirs = (theirVodTime ?? 0) > 0 ? theirVodTime! : null;
  if (ours == null || theirs == null || ours == theirs) {
    return const SourceLead();
  }

  // Older row, same count: this catalog was there first. The subtraction is
  // deliberately theirs-minus-ours — the sign has to come out positive when
  // OUR stamp is the older one.
  return SourceLead(arrivedEarlierBy: Duration(seconds: theirs - ours));
}
