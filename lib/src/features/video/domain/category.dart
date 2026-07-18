class Category {
  final int id;
  final String name;
  final String? enName;
  final List<Category> children;
  final List<String> areas;
  final List<String> years;

  const Category({
    required this.id,
    required this.name,
    this.enName,
    this.children = const [],
    this.areas = const [],
    this.years = const [],
  });
}
