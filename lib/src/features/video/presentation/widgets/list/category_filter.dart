import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/domain/category.dart';

/// What narrows the current category: type, area, year.
///
/// Laid out, not hidden behind menus — the whole point of a filter row is that
/// you can see what is on offer without asking. One line each, scrolling
/// sideways: the catalogs ship 20 areas and 26 years, and as wrapping pills
/// that was four rows and roughly 240px of chrome above the grid. A row that
/// scrolls stays one row however many options arrive.
///
/// The top-level categories that used to head this strip are in the rail now:
/// they are destinations, not filters.
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
    final hasType = selectedCategory.children.isNotEmpty;
    final hasArea = selectedCategory.areas.isNotEmpty;
    final hasYear = selectedCategory.years.isNotEmpty;
    if (!hasType && !hasArea && !hasYear) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasType)
          _FilterRow(
            label: tr('filter.type'),
            value: selectedSubType,
            options: selectedCategory.children.map((e) => e.name).toList(),
            onPick: (v) => onFilterChanged(v, selectedArea, selectedYear),
          ),
        if (hasArea)
          _FilterRow(
            label: tr('filter.area'),
            value: selectedArea,
            options: selectedCategory.areas,
            onPick: (v) => onFilterChanged(selectedSubType, v, selectedYear),
          ),
        if (hasYear)
          _FilterRow(
            label: tr('filter.year'),
            value: selectedYear,
            options: selectedCategory.years,
            onPick: (v) => onFilterChanged(selectedSubType, selectedArea, v),
          ),
      ],
    );
  }
}

/// One filter, spelled out: its name, then every value it can take.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onPick,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onPick;

  /// Enough for a two-character label plus its gap, so the three rows' options
  /// start on the same vertical line.
  static const _labelWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    // "All" is a value like any other and leads the row — it is the one every
    // filter starts on and the one people come back to.
    final all = <String?>[null, ...options];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, height: 1.4, color: t.fg3),
            ),
          ),
          Expanded(
            // Scrollbars are hidden app-wide (NoScrollbarBehavior); the row
            // scrolls on trackpad and shift-wheel.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in all) ...[
                    _OptionPill(
                      label: option ?? tr('filter.any'),
                      selected: option == value,
                      onTap: () => onPick(option),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One value a filter can take.
///
/// Bordered even when unselected: with no shape at all a row of these reads as
/// a sentence, and the only cue that any of it is tappable is that one word
/// happens to be coloured.
class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        hoverColor: t.fg.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? t.cyan.withValues(alpha: 0.12)
                : t.fg.withValues(alpha: 0.04),
            border: Border.all(
              color: selected ? t.cyan.withValues(alpha: 0.42) : t.edgeSoft,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? t.cyan : t.fg2,
            ),
          ),
        ),
      ),
    );
  }
}
