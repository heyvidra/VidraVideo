// Episode identity that survives a source switch.
//
// The two catalogs describe the same show differently: olevod files 第1集 where
// dbku files 第01集, and their lists are not even the same length (14 against
// 15 on the titles compared locally). Position in the episode ARRAY is
// therefore not shared identity — carrying watch progress across by index
// silently moves the viewer a whole instalment, which reads as the app losing
// their place rather than as two catalogs disagreeing. The number a show states
// about ITSELF is the only key both sides already agree on.

/// Full-width forms are folded before matching so 第１２集 and 第12集 are one
/// episode. Only the ASCII-equivalent block is touched; 集 and friends are
/// outside it and pass through unharmed.
String _foldFullWidth(String s) {
  const offset = 0xFEE0;
  bool wide(int c) => c >= 0xFF01 && c <= 0xFF5E;
  if (!s.codeUnits.any(wide)) return s;
  return String.fromCharCodes(s.codeUnits.map((c) => wide(c) ? c - offset : c));
}

/// 第N集 with the unit spelled any of the four ways the sources use, and any
/// spacing between the parts (第 12 集 occurs). Trailing text is tolerated
/// because one catalog suffixes 第12集(粤语) — still episode 12.
final RegExp _ordinal = RegExp(r'^第\s*(\d{1,4})\s*[集話话期]');

/// A bare number is only an episode when it is the WHOLE title. Matching it
/// loosely would turn 1080P 抢先版 into episode 1080.
final RegExp _bare = RegExp(r'^(\d{1,4})$');

final RegExp _ep = RegExp(r'^EP\.?\s*(\d{1,4})$', caseSensitive: false);

int? _numberIn(String title) {
  final t = _foldFullWidth(title).trim();
  if (t.isEmpty) return null;
  final m = _ordinal.firstMatch(t) ?? _bare.firstMatch(t) ?? _ep.firstMatch(t);
  if (m == null) return null;
  final n = int.tryParse(m.group(1)!);
  // Numbering is 1-based everywhere it is consumed; a zero would hand any
  // caller that converts back with n - 1 a negative row.
  return (n == null || n < 1) ? null : n;
}

/// The episode number [title] claims for itself, 1-based, or null when it
/// claims none.
///
/// Refusing is the load-bearing half. Both catalogs park a film's audio tracks
/// and mirrors in the same episode list, named 立即播放 / 粤语播放 / HD /
/// 抢先版 — alternatives, not instalments. Numbering those by their position
/// would join "the Cantonese track" on one source to "episode 2" on the other
/// and write progress onto something the viewer never opened, so anything not
/// recognisably an ordinal comes back null and the caller keeps the two lists
/// apart.
///
/// [index] is consulted only for a blank title: a source that ships an unnamed
/// list is still counting in order, so position is all the numbering there is.
/// [episodic] is [isEpisodicType] of the show — for a film the answer is always
/// null, because there is no sequence to align and its list entries are ways to
/// play one thing.
int? episodeNumberOf(
  String? title, {
  required int index,
  required bool episodic,
}) {
  if (!episodic) return null;
  final raw = title ?? '';
  if (raw.trim().isEmpty) return index + 1;
  return _numberIn(raw);
}

/// What the episode tile prints.
///
/// Zero padding is normalised away: 第01集 and 第1集 are the same episode, and
/// the two detail pages of one show rendering them differently was the most
/// visible way the sources disagreed. A title that denotes no number is printed
/// exactly as the source wrote it, because 粤语播放 is information the viewer
/// needs and 第3集 in its place would be a fabrication.
///
/// Deliberately free of easy_localization — this is domain code, reached from
/// providers and tests with no localisation delegate loaded. A caller that
/// wants the localised wording still has the 'video.detail.episode_prefix' key
/// and the number from [episodeNumberOf].
String episodeLabel(String? title, {required int index}) {
  final raw = title ?? '';
  if (raw.trim().isEmpty) return '第${index + 1}集';
  final n = _numberIn(raw);
  return n == null ? raw : '第$n集';
}
