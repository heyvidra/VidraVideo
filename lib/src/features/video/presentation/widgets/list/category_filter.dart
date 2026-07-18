import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vidra/src/features/video/domain/category.dart';

class CategoryFilter extends StatelessWidget {
  final Category selectedCategory;
  final List<Category> categories;

  /// null means "all" for the three sub-filters.
  final String? selectedSubType;
  final String? selectedArea;
  final String? selectedYear;
  final Function(Category) onCategoryChanged;
  final Function(String? subType, String? area, String? year) onFilterChanged;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.selectedSubType,
    required this.selectedArea,
    required this.selectedYear,
    required this.onCategoryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Level Categories
        Row(
          children: [
            Expanded(
              // Scrollbars hidden app-wide via NoScrollbarBehavior
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    final isSelected = category.id == selectedCategory.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: InkWell(
                        onTap: () => onCategoryChanged(category),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : null,
                          child: Text(
                            category.name == '无分类'
                                ? tr('filter.no_category')
                                : (category.name == '加载中...'
                                      ? tr('common.loading')
                                      : category.name),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        // Show sub-filters only if not "Live"
        if (selectedCategory.children.isNotEmpty ||
            selectedCategory.areas.isNotEmpty) ...[
          const SizedBox(height: 16),

          // 2. Sub-Categories (Type)
          if (selectedCategory.children.isNotEmpty)
            _buildFilterRow(
              context,
              tr('filter.all_types'),
              selectedCategory.children.map((e) => e.name).toList(),
              selectedSubType,
              (val) => onFilterChanged(val, selectedArea, selectedYear),
            ),

          // 3. Areas
          if (selectedCategory.areas.isNotEmpty)
            _buildFilterRow(
              context,
              tr('filter.all_areas'),
              selectedCategory.areas,
              selectedArea,
              (val) => onFilterChanged(selectedSubType, val, selectedYear),
            ),

          // 4. Years
          if (selectedCategory.years.isNotEmpty)
            _buildFilterRow(
              context,
              tr('filter.all_years'),
              selectedCategory.years,
              selectedYear,
              (val) => onFilterChanged(selectedSubType, selectedArea, val),
            ),
        ],
      ],
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    String allLabel,
    List<String> items,
    String? selectedItem,
    Function(String?) onSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // null represents "all"; its display text is the translated allLabel.
    final List<String?> allItems = [null, ...items];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        spacing: 0,
        runSpacing: 8,
        children: allItems.map((label) {
          final isSelected = label == selectedItem;
          final displayLabel = label ?? allLabel;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => onSelected(label),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(
                          isDark ? 50 : 30,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      )
                    : null,
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
