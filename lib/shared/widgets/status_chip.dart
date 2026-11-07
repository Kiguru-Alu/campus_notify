import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/status_style.dart';
import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.compact = false});

  final IncidentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 11 : 13, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: AppType.caption(color: status.color).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10.5 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip(this.category, {super.key});

  final IncidentCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navyTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 12, color: AppColors.navy),
          const SizedBox(width: 4),
          Text(category.label, style: AppType.caption(color: AppColors.navy)),
        ],
      ),
    );
  }
}

/// Location rendered as a wayfinding marker rather than plain text.
class LocationChip extends StatelessWidget {
  const LocationChip(this.label, {super.key, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : AppColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption(color: color),
          ),
        ),
      ],
    );
  }
}
