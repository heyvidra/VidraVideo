import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:vidra/src/config/ambient_background.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/subscription/presentation/subscription_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/presentation/video_list_provider.dart';
import '../../../core/services/vidradlp/vidradlp_ffi.dart';
import '../domain/app_navigation_item.dart';

/// The design's rail width. Narrower than it was, and it can afford to be:
/// the rows lost their icons.
const double kSidebarWidth = 186;

// ponytail: memoized — vidradlpLibraryAvailable() attempts a dylib open;
// resolve it once for the app's lifetime instead of per sidebar rebuild.
final bool _mediaFfiAvailable = vidradlpLibraryAvailable();

/// Which catalog row the rail is pointing at: null for 首页, otherwise a
/// category id.
///
/// The list screen's own filter cannot answer this — 首页 and the first
/// category resolve to the same filter, so keying the highlight off the filter
/// lit two rows at once. This records what was actually clicked.
final railCategoryProvider = NotifierProvider<RailCategoryNotifier, int?>(
  RailCategoryNotifier.new,
);

/// The running build's version, read off the bundle rather than retyped from
/// pubspec — a hand-copied constant is wrong one release after someone forgets.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});

class RailCategoryNotifier extends Notifier<int?> {
  @override
  int? build() {
    // A pick belongs to the catalog that produced it. Switching source keeps
    // the id but not its meaning: the new catalog either has no such row —
    // nothing lights up, and 首页 does not light up either — or reuses the id
    // for a different one, which lights the wrong row. Both disagree with the
    // grid, which resets to the new catalog's first category.
    ref.watch(activeDataSourceIdProvider);
    return null;
  }

  @override
  set state(int? value) => super.state = value;
}

/// The left rail.
///
/// Categories live HERE now, not in a filter strip above the grid. They are
/// destinations — "show me the dramas" is the same kind of statement as "show
/// me my downloads" — and a horizontal strip of them was competing with the
/// grid for the first 60px of every catalog screen. The strip keeps the
/// sub-filters (type / area / year), which genuinely are filters.
class Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    // A reload of this provider is a source change, not a refresh of the same
    // catalog — Riverpod keeps handing back the previous source's rows until
    // the new ones land, and keeps handing them back forever if the fetch
    // fails. Rows from a catalog you are no longer browsing read as this
    // source's rows and open the wrong lists; no rows reads as loading.
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.isLoading || categoriesAsync.hasError
        ? const <Category>[]
        : categoriesAsync.value ?? const <Category>[];
    final onCatalog = selectedIndex == 0;
    final railPick = ref.watch(railCategoryProvider);
    final unread = ref.watch(unreadSubscriptionCountProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: kSidebarWidth,
        child: GlassPanel(
          radius: 20,
          blur: 11,
          saturation: 1.5,
          border: t.edgeSoft,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RailHeading(tr('navigation.section_menu')),
                      _RailRow(
                        label: tr('navigation.home'),
                        selected: onCatalog && railPick == null,
                        onTap: () {
                          ref.read(railCategoryProvider.notifier).state = null;
                          if (categories.isNotEmpty) {
                            ref.read(videoListFilterProvider.notifier).state =
                                VideoListFilter(category: categories.first);
                          }
                          onDestinationSelected(0);
                        },
                      ),
                      for (final c in categories)
                        _RailRow(
                          label: c.name,
                          selected: onCatalog && railPick == c.id,
                          onTap: () {
                            ref.read(railCategoryProvider.notifier).state =
                                c.id;
                            ref.read(videoListFilterProvider.notifier).state =
                                VideoListFilter(category: c);
                            onDestinationSelected(0);
                          },
                        ),

                      const _RailSeparator(),
                      _RailHeading(tr('navigation.section_library')),
                      for (final item in AppNavigationItem.values)
                        if (item != AppNavigationItem.home &&
                            item != AppNavigationItem.settings &&
                            (!item.requiresMediaFfi || _mediaFfiAvailable))
                          _RailRow(
                            label: item.localizedLabel,
                            selected: selectedIndex == item.branchIndex,
                            badge:
                                item == AppNavigationItem.subscriptions &&
                                    unread > 0
                                ? '$unread'
                                : null,
                            onTap: () =>
                                onDestinationSelected(item.branchIndex),
                          ),

                      const _RailSeparator(),
                      _RailRow(
                        label: AppNavigationItem.settings.localizedLabel,
                        selected:
                            selectedIndex ==
                            AppNavigationItem.settings.branchIndex,
                        onTap: () => onDestinationSelected(
                          AppNavigationItem.settings.branchIndex,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _RailFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mark and the build, at the foot of the rail.
///
/// The wordmark on the toolbar names the window; this names the PRODUCT, and
/// the version beside it is the first thing anyone is asked for when something
/// goes wrong. Bottom of the rail because neither is navigation — putting them
/// at the top pushed the actual destinations 40px down the panel.
class _RailFooter extends ConsumerWidget {
  const _RailFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final version = ref.watch(appVersionProvider).value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 22,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(width: 9),
          if (version != null)
            Text(
              version,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: t.fg3,
                fontFeatures: VidraType.data,
              ),
            ),
        ],
      ),
    );
  }
}

/// `.rail-h` — a quiet all-caps label, not a heading. It groups the rows under
/// it; at the rows' own weight it would be a third thing competing for the eye
/// in a column of ten.
class _RailHeading extends StatelessWidget {
  const _RailHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
      child: Text(text.toUpperCase(), style: VidraType.eyebrow(t.fg3)),
    );
  }
}

class _RailSeparator extends StatelessWidget {
  const _RailSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: VidraTokens.of(context).edgeSoft),
      ),
    );
  }
}

/// One destination. Selection is the row itself lighting up — a filled pill
/// with the raised glass fill — rather than a marker bolted to its end.
class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: t.fg.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: t.glass3,
                    ),
                    border: Border.all(color: t.edgeSoft),
                    boxShadow: t.drop1,
                  )
                : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? t.fg : t.fg2,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: t.amber,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(color: t.amberGlow, blurRadius: 12),
                      ],
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: t.onAmber,
                        fontFeatures: VidraType.data,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
