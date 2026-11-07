import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/status_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/incident.dart';
import '../../../shared/widgets/status_chip.dart';

/// A report rendered as a maintenance tag: a status colour bar down the
/// left edge, the reference code, and where the problem is.
class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.line),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: incident.status.color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (incident.photoUrl != null) ...[
                          _Thumbnail(url: incident.photoUrl!),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(child: _Body(incident: incident)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                Formatters.reference(incident.id),
                style: AppType.code(),
              ),
            ),
            StatusChip(incident.status, compact: true),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          incident.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.subtitle(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(child: LocationChip(incident.fullLocation)),
            const SizedBox(width: AppSpacing.md),
            Text(
              Formatters.relative(incident.createdAt),
              style: AppType.caption(),
            ),
            if (incident.supportCount > 0) ...[
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.group_outlined,
                  size: 13, color: AppColors.inkFaint),
              const SizedBox(width: 3),
              Text('${incident.supportCount}', style: AppType.caption()),
            ],
          ],
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 58,
        width: 58,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.canvas),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.canvas,
          child: const Icon(Icons.broken_image_outlined,
              size: 18, color: AppColors.inkFaint),
        ),
      ),
    );
  }
}
