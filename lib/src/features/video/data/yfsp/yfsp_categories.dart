import 'package:vidra/src/features/video/domain/category.dart';

/// Snapshot of `list/AllVideoType` (top level `cid=0,1`, then one call per
/// top-level path) plus the region/year/language lists from
/// `list/GetSearchCondition`.
///
/// Held as a constant for the same reason olevod and dbku hold theirs: the
/// catalog screen needs the filter bar before the first list request, and yfsp
/// rate-limits hard enough that spending two round trips on a tree that
/// changes maybe once a year is the wrong trade. Ids are the real ones the API
/// takes — [YfspDataSource] rebuilds the `cid` path from them ("0,1,4,131"),
/// so re-snapshotting only means pasting new ids here.
const List<Category> kYfspCategories = [
  Category(
    id: 3,
    name: '电影',
    areas: _kAreas,
    years: _kYears,
    children: [
      Category(id: 19, name: '喜剧'),
      Category(id: 20, name: '爱情'),
      Category(id: 21, name: '动作'),
      Category(id: 22, name: '犯罪'),
      Category(id: 23, name: '科幻'),
      Category(id: 24, name: '奇幻'),
      Category(id: 25, name: '冒险'),
      Category(id: 26, name: '灾难'),
      Category(id: 123, name: '恐怖'),
      Category(id: 27, name: '惊悚'),
      Category(id: 28, name: '剧情'),
      Category(id: 29, name: '战争'),
      Category(id: 30, name: '歌舞'),
      Category(id: 31, name: '经典'),
      Category(id: 32, name: '悬疑'),
      Category(id: 113, name: '动画'),
      Category(id: 124, name: '同性'),
      Category(id: 125, name: '网络电影'),
    ],
  ),
  Category(
    id: 4,
    name: '电视剧',
    areas: _kAreas,
    years: _kYears,
    children: [
      Category(id: 129, name: '偶像'),
      Category(id: 146, name: '爱情'),
      Category(id: 127, name: '言情'),
      Category(id: 126, name: '古装'),
      Category(id: 141, name: '历史'),
      Category(id: 142, name: '玄幻'),
      Category(id: 136, name: '谍战'),
      Category(id: 143, name: '历险'),
      Category(id: 132, name: '都市'),
      Category(id: 144, name: '科幻'),
      Category(id: 135, name: '军旅'),
      Category(id: 133, name: '喜剧'),
      Category(id: 128, name: '武侠'),
      Category(id: 145, name: '江湖'),
      Category(id: 138, name: '罪案'),
      Category(id: 131, name: '青春'),
      Category(id: 130, name: '家庭'),
      Category(id: 134, name: '战争'),
      Category(id: 137, name: '悬疑'),
      Category(id: 139, name: '穿越'),
      Category(id: 140, name: '宫廷'),
      Category(id: 147, name: '神话'),
      Category(id: 148, name: '商战'),
      Category(id: 149, name: '警匪'),
      Category(id: 150, name: '动作'),
      Category(id: 151, name: '惊悚'),
      Category(id: 152, name: '剧情'),
      Category(id: 153, name: '同性'),
      Category(id: 154, name: '奇幻'),
    ],
  ),
  Category(
    id: 5,
    name: '综艺',
    areas: _kAreas,
    years: _kYears,
    children: [
      Category(id: 39, name: '真人秀'),
      Category(id: 38, name: '选秀'),
      Category(id: 94, name: '网综'),
      Category(id: 43, name: '脱口秀'),
      Category(id: 40, name: '搞笑'),
      Category(id: 91, name: '竞技'),
      Category(id: 33, name: '情感'),
      Category(id: 34, name: '访谈'),
      Category(id: 44, name: '演唱会'),
      Category(id: 92, name: '晚会'),
      Category(id: 45, name: '其它'),
    ],
  ),
  Category(
    id: 6,
    name: '动漫',
    areas: _kAreas,
    years: _kYears,
    children: [
      Category(id: 46, name: '热血'),
      Category(id: 47, name: '格斗'),
      Category(id: 48, name: '机战'),
      Category(id: 49, name: '少女'),
      Category(id: 51, name: '竞技'),
      Category(id: 52, name: '科幻'),
      Category(id: 53, name: '魔幻'),
      Category(id: 54, name: '爆笑'),
      Category(id: 55, name: '推理'),
      Category(id: 121, name: '冒险'),
      Category(id: 120, name: '恋爱'),
      Category(id: 119, name: '校园'),
      Category(id: 118, name: '治愈'),
      Category(id: 117, name: '泡面'),
      Category(id: 116, name: '穿越'),
      Category(id: 56, name: '灵异'),
      Category(id: 122, name: '耽美'),
      Category(id: 57, name: '剧场版'),
      Category(id: 58, name: '其它'),
    ],
  ),
  Category(
    id: 95,
    name: '体育',
    areas: _kAreas,
    years: _kYears,
    children: [
      Category(id: 99, name: '奥运'),
      Category(id: 98, name: '综合'),
      Category(id: 97, name: '篮球'),
      Category(id: 96, name: '足球'),
    ],
  ),
  Category(
    id: 7,
    name: '纪录片',
    areas: _kAreas,
    years: _kYears,
    children: [
      Category(id: 50, name: '文化'),
      Category(id: 59, name: '探索'),
      Category(id: 60, name: '军事'),
      Category(id: 61, name: '解密'),
      Category(id: 62, name: '科技'),
      Category(id: 63, name: '历史'),
      Category(id: 64, name: '人物'),
      Category(id: 66, name: '自然'),
      Category(id: 67, name: '其它'),
    ],
  ),
];

const List<String> _kAreas = [
  '大陆',
  '香港',
  '台湾',
  '日本',
  '韩国',
  '欧美',
  '英国',
  '泰国',
  '其它',
];

/// yfsp's own year filter is a set of BUCKETS, not years — its filter bar
/// offers exactly these. A plain year ("2024") is also accepted and returns
/// that year, but the buckets are what the site exposes and what the counts
/// line up with, so they are what ships.
const List<String> _kYears = ['今年', '去年', '更早', '90年代', '80年代', '怀旧'];
