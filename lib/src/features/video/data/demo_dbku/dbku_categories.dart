import 'package:vidra/src/features/video/domain/category.dart';

/// Category ids are MacCMS `type_id` values, read off the site nav
/// (`/vodtype/{id}.html`). Areas and years mirror the filter bar on
/// `/vodshow/2-...`; dbku offers the same option set across categories.
///
/// ponytail: no [Category.children] — dbku's sub-genre filter keys on a name
/// ("言情"), not an int id, so it cannot ride the int-keyed children model.
/// Give Category a name-keyed sub-filter if the UI ever needs those.
const List<Category> kDbkuCategories = [
  Category(
    id: 2,
    name: "连续剧",
    enName: "lianxuju",
    areas: _kAreas,
    years: _kYears,
  ),
  Category(id: 1, name: "电影", enName: "dianying", areas: _kAreas, years: _kYears),
  Category(id: 3, name: "综艺", enName: "zongyi", areas: _kAreas, years: _kYears),
  Category(id: 4, name: "动漫", enName: "dongman", areas: _kAreas, years: _kYears),
  Category(id: 13, name: "陆剧", enName: "luju", areas: _kAreas, years: _kYears),
  Category(id: 20, name: "港剧", enName: "gangju", areas: _kAreas, years: _kYears),
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
  Category(id: 21, name: "短剧", enName: "duanju", areas: _kAreas, years: _kYears),
];

const List<String> _kAreas = [
  "大陆",
  "香港",
  "台湾",
  "韩国",
  "日本",
  "新加坡",
  "泰国",
];

const List<String> _kYears = [
  "2026",
  "2025",
  "2024",
  "2023",
  "2022",
  "2021",
  "2020",
  "2019",
  "2018",
  "2017",
];
