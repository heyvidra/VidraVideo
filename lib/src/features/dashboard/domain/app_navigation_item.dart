import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum AppNavigationItem {
  home(
    labelKey: 'navigation.home',
    icon: Icons.home,
    branchIndex: 0,
    sectionKey: 'navigation.section_menu',
    route: '/',
  ),
  // Order is the rail's order: 追更 / 想看 / 继续观看 / 下载 / 链接下载 —
  // the watching lifecycle, top to bottom: following, saved, started.
  subscriptions(
    labelKey: 'navigation.subscriptions',
    icon: Icons.notifications_none,
    branchIndex: 5,
    sectionKey: 'navigation.section_library',
    route: '/subscriptions',
  ),
  favorites(
    labelKey: 'navigation.favorites',
    icon: Icons.bookmark_border,
    branchIndex: 6,
    sectionKey: 'navigation.section_library',
    route: '/favorites',
  ),
  recent(
    labelKey: 'navigation.recent',
    icon: Icons.schedule,
    branchIndex: 2,
    sectionKey: 'navigation.section_library',
    route: '/recent',
  ),
  downloads(
    labelKey: 'navigation.downloads',
    icon: Icons.download,
    branchIndex: 1,
    sectionKey: 'navigation.section_library',
    route: '/downloads',
    requiresMediaFfi: true,
  ),
  linkDownload(
    labelKey: 'navigation.link_download',
    icon: Icons.add_link,
    branchIndex: 4,
    sectionKey: 'navigation.section_library',
    route: '/download-url',
    requiresMediaFfi: true,
  ),
  settings(
    labelKey: 'navigation.settings',
    icon: Icons.settings,
    branchIndex: 3,
    sectionKey: 'navigation.section_general',
    route: '/settings',
  );

  final String labelKey;
  final IconData icon;
  final int branchIndex;
  final String sectionKey;
  final String route;

  /// Entry depends on the native vidraDlp lib (libmedia_ffi); hidden on
  /// platforms/builds where it can't load (e.g. Windows until the .dll ships).
  final bool requiresMediaFfi;

  const AppNavigationItem({
    required this.labelKey,
    required this.icon,
    required this.branchIndex,
    required this.sectionKey,
    required this.route,
    this.requiresMediaFfi = false,
  });

  String get localizedLabel => tr(labelKey);
  String get localizedSection => tr(sectionKey);

  static AppNavigationItem? fromBranchIndex(int index) {
    try {
      return AppNavigationItem.values.firstWhere(
        (item) => item.branchIndex == index,
      );
    } catch (_) {
      return null;
    }
  }
}
