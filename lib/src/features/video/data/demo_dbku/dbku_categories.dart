import 'package:vidra/src/features/video/domain/category.dart';

/// Category ids are MacCMS `type_id` values, read off the site nav
/// (`/vodtype/{id}.html`). Areas and years mirror the filter bar on
/// `/vodshow/2-...`; dbku offers the same option set across categories.
///
/// ponytail: no [Category.children] — dbku's sub-genre filter keys on a name
/// ("言情"), not an int id, so it cannot ride the int-keyed children model.
/// Give Category a name-keyed sub-filter if the UI ever needs those.
final List<Category> kDbkuCategories = [
  Category(
    id: 2,
    name: "连续剧",
    enName: "lianxuju",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(
    id: 1,
    name: "电影",
    enName: "dianying",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(id: 3, name: "综艺", enName: "zongyi", areas: _kAreas, years: _kYears),
  Category(
    id: 4,
    name: "动漫",
    enName: "dongman",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(id: 13, name: "陆剧", enName: "luju", areas: _kAreas, years: _kYears),
  Category(
    id: 20,
    name: "港剧",
    enName: "gangju",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(
    id: 15,
    name: "日韩剧",
    enName: "rihanju",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(
    id: 14,
    name: "台泰剧",
    enName: "taitaiju",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(
    id: 21,
    name: "短剧",
    enName: "duanju",
    areas: _kAreas,
    years: _kYears,
  ),
];

const List<String> _kAreas = ["大陆", "香港", "台湾", "韩国", "日本", "新加坡", "泰国"];

/// 2000 to the current year, newest first.
///
/// Generated rather than typed out. Both catalogs gain a year in their own
/// filter bar every January, and a hardcoded list quietly stops offering the
/// year most of what you want to watch was made in — olevod's stopped at 2025
/// while its site was already filing 2026 shows, so a 2026 drama could not be
/// filtered to at all.
final List<String> _kYears = [
  for (var y = DateTime.now().year; y >= 2000; y--) '$y',
];
