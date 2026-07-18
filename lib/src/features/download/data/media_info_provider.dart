import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/media_info_service.dart';
import '../../../core/services/vidradlp/vidra_config.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/media_info.dart';

final mediaInfoServiceProvider = Provider<MediaInfoService>(
  (ref) => const MediaInfoService(),
);

/// Holds the URL-parse result for the download-by-URL screen.
/// `AsyncData(null)` = idle; `AsyncLoading` = parsing; `AsyncData(info)` = ready.
class UrlParseController extends Notifier<AsyncValue<MediaInfo?>> {
  @override
  AsyncValue<MediaInfo?> build() => const AsyncData(null);

  Future<void> parse(String url) async {
    state = const AsyncLoading();
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      final configJson = vidraClientConfigJson(cookieFile: settings.cookieFile);
      final info = await ref
          .read(mediaInfoServiceProvider)
          .extract(url, configJson: configJson);
      state = AsyncData(info);
    } on MediaInfoException catch (e, st) {
      state = AsyncError(e.message, st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() => state = const AsyncData(null);
}

final urlParseControllerProvider =
    NotifierProvider<UrlParseController, AsyncValue<MediaInfo?>>(
      UrlParseController.new,
    );
