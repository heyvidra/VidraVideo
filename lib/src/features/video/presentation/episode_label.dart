import 'package:easy_localization/easy_localization.dart';

import '../domain/episode_number.dart';

/// [episodeLabel] in the interface language.
///
/// The domain function always answers 第N集 — right for stored download
/// titles and for the television, wrong on an English screen, where the play
/// button read "Continue 第5集". A title that names no number comes back as
/// the source wrote it, exactly as before.
String localizedEpisodeLabel(String? title, {required int index}) {
  final label = episodeLabel(title, index: index);
  final n = RegExp(r'^第(\d+)集$').firstMatch(label)?.group(1);
  return n == null ? label : tr('video.detail.episode_short', args: [n]);
}
