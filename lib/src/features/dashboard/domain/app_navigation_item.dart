import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum AppNavigationItem {
  home(
    labelKey: 'navigation.home',
    icon: Icons.home,
    sectionKey: 'navigation.section_menu',
    route: '/',
  ),
  // Order is the rail's order: 追更 / 想看 / 继续观看 / 下载 / 链接下载 —
  // the watching lifecycle, top to bottom: following, saved, started.
  subscriptions(
    labelKey: 'navigation.subscriptions',
    icon: Icons.notifications_none,
    sectionKey: 'navigation.section_library',
    route: '/subscriptions',
  ),
  favorites(
    labelKey: 'navigation.favorites',
    icon: Icons.bookmark_border,
    sectionKey: 'navigation.section_library',
    route: '/favorites',
  ),
  recent(
    labelKey: 'navigation.recent',
    icon: Icons.schedule,
    sectionKey: 'navigation.section_library',
    route: '/recent',
  ),
  downloads(
    labelKey: 'navigation.downloads',
    icon: Icons.download,
    sectionKey: 'navigation.section_library',
    route: '/downloads',
    requiresMediaFfi: true,
  ),
  linkDownload(
    labelKey: 'navigation.link_download',
    icon: Icons.add_link,
    sectionKey: 'navigation.section_library',
    route: '/download-url',
    requiresMediaFfi: true,
  ),
  settings(
    labelKey: 'navigation.settings',
    icon: Icons.settings,
    sectionKey: 'navigation.section_general',
    route: '/settings',
  );

  final String labelKey;
  final IconData icon;
  final String sectionKey;
  final String route;

  /// Entry depends on the native vidraDlp lib (libmedia_ffi); hidden on
  /// platforms/builds where it can't load (e.g. Windows until the .dll ships).
  final bool requiresMediaFfi;

  const AppNavigationItem({
    required this.labelKey,
    required this.icon,
    required this.sectionKey,
    required this.route,
    this.requiresMediaFfi = false,
  });

  String get localizedLabel => tr(labelKey);
  String get localizedSection => tr(sectionKey);

  /// Which rail entry [location] belongs to. The route IS the identity —
  /// this replaced a parallel set of hand-numbered branch indexes that had
  /// to be edited in three files to add one entry.
  static AppNavigationItem forLocation(String location) {
    for (final item in AppNavigationItem.values) {
      if (item.route != '/' && location.startsWith(item.route)) return item;
    }
    return AppNavigationItem.home;
  }
}
