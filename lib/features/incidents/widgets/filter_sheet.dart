import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/campus.dart';
import '../../../core/constants/incident_category.dart';
import '../../../core/constants/incident_status.dart';
import '../providers/incident_filter.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidentFilterProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter reports', style: AppType.headline()),
                  if (filter.isActive)
                    TextButton(
                      onPressed: notifier.clear,
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _GroupLabel('Status'),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final status in IncidentStatus.values)
                    _Pill(
                      label: status.label,
                      selected: filter.status == status,
                      onTap: () => notifier.setStatus(
                        filter.status == status ? null : status,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _GroupLabel('Category'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final category in IncidentCategory.values)
                    _Pill(
                      label: category.label,
                      selected: filter.category == category,
                      onTap: () => notifier.setCategory(
                        filter.category == category ? null : category,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _GroupLabel('Location'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final location in Campus.locations)
                    _Pill(
                      label: location,
                      selected: filter.location == location,
                      onTap: () => notifier.setLocation(
                        filter.location == location ? null : location,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _GroupLabel('Order'),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final sort in IncidentSort.values)
                    _Pill(
                      label: sort.label,
                      selected: filter.sort == sort,
                      onTap: () => notifier.setSort(sort),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Show results'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppType.smallStrong()),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.canvas,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppType.small(
              color: selected ? Colors.white : AppColors.ink,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
