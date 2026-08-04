/// A small in-memory TTL cache.
///
/// Exists to keep catalog browsing from re-hitting the data sources: both
/// demo sources are scrape/API endpoints that ban IPs on request storms, and
/// the UI's natural navigation (tab flips, back-and-forth into details,
/// repeated searches) used to translate one-to-one into network fetches.
/// Values are whole responses; staleness within [ttl] is an accepted trade.
class TtlCache<K, V> {
  TtlCache({
    required this.ttl,
    this.maxEntries = 64,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration ttl;

  /// Insert-time cap. Catalog keys are unbounded (every filter/page combo is
  /// a key), so without a cap a long browsing session grows this forever.
  final int maxEntries;

  final DateTime Function() _clock;
  final _entries = <K, ({V value, DateTime at})>{};

  V? get(K key) {
    final e = _entries[key];
    if (e == null) return null;
    if (_clock().difference(e.at) > ttl) {
      _entries.remove(key);
      return null;
    }
    return e.value;
  }

  void set(K key, V value) {
    // Evict oldest first. Linear scan is fine at these sizes.
    if (_entries.length >= maxEntries && !_entries.containsKey(key)) {
      K? oldest;
      DateTime? oldestAt;
      for (final MapEntry(:key, :value) in _entries.entries) {
        if (oldestAt == null || value.at.isBefore(oldestAt)) {
          oldest = key;
          oldestAt = value.at;
        }
      }
      _entries.remove(oldest);
    }
    _entries[key] = (value: value, at: _clock());
  }

  void invalidate(K key) => _entries.remove(key);

  void clear() => _entries.clear();

  int get length => _entries.length;
}
