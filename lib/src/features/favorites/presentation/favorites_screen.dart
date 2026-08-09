import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/poster_card_action.dart';
import '../../../common/screen_chrome.dart';
import 'favorites_provider.dart';
import '../../video/presentation/widgets/cards/popular_video_card.dart';

/// 想看 — shows saved for later, as a wall of the same poster cards every
/// other list uses. A card opens the detail page (its default tap); nothing
/// here starts playback, because nothing here has been started.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ScreenHeader(
            title: tr('favorites.title'),
            count: favoritesAsync.value?.isNotEmpty == true
                ? '${favoritesAsync.value!.length}'
                : null,
          ),
          Expanded(
            child: favoritesAsync.when(
              data: (favorites) {
                if (favorites.isEmpty) {
                  return ScreenEmpty(
                    icon: Icons.bookmark_border_rounded,
                    title: tr('favorites.empty'),
                    hint: tr('favorites.empty_hint'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    kContentGutter,
                    0,
                    kContentGutter,
                    24,
                  ),
                  gridDelegate: kPosterGrid,
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final video = favorites[index];
                    return PopularVideoCard(
                      key: ValueKey('favorite_${video.sourceId}_${video.apiId}'),
                      video: video,
                      trailing: PosterCardAction(
                        icon: Icons.close_rounded,
                        tooltip: tr('favorites.remove'),
                        onTap: () =>
                            ref.read(favoritesProvider.notifier).remove(video),
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => Center(
                child: Text(tr('common.error', args: [err.toString()])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

