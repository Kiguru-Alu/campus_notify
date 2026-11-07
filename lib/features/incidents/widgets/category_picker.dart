import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/status_style.dart';
import '../../../core/constants/incident_category.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final IncidentCategory selected;
  final ValueChanged<IncidentCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in IncidentCategory.values)
          _CategoryTile(
            category: category,
            selected: category == selected,
            onTap: () => onSelect(category),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width -
            (AppSpacing.gutter * 2) -
            (AppSpacing.sm * 2)) /
        3;

    return SizedBox(
      width: width,
      child: Material(
        color: selected ? AppColors.navy : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.line,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  category.icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.navy,
                ),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  style: AppType.caption(
                    color: selected ? Colors.white : AppColors.ink,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
