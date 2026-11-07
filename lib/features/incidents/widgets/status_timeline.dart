import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/status_style.dart';
import '../../../core/constants/incident_status.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/status_update.dart';

/// The audit trail as a work-order progression. Entries that happened are
/// drawn solid with who did it; the state the report has not reached yet is
/// drawn as an outline, so a student can see what is still owed to them.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.updates,
    required this.current,
  });

  final List<StatusUpdate> updates;
  final IncidentStatus current;

  @override
  Widget build(BuildContext context) {
    final pending = current.isTerminal
        ? const <IncidentStatus>[]
        : IncidentStatus.timeline
            .skipWhile((status) => status != current)
            .skip(1)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < updates.length; i++)
          _Row(
            status: updates[i].toStatus,
            title: updates[i].toStatus.label,
            subtitle: _subtitleFor(updates[i]),
            note: updates[i].note,
            done: true,
            isLast: i == updates.length - 1 && pending.isEmpty,
          ),
        for (var i = 0; i < pending.length; i++)
          _Row(
            status: pending[i],
            title: pending[i].label,
            subtitle: pending[i].description,
            done: false,
            isLast: i == pending.length - 1,
          ),
      ],
    );
  }

  String _subtitleFor(StatusUpdate update) {
    return '${Formatters.absolute(update.createdAt)} \u00b7 ${update.actorName}';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.isLast,
    this.note,
  });

  final IncidentStatus status;
  final String title;
  final String subtitle;
  final String? note;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? status.color : AppColors.lineStrong;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.6),
                ),
                child: Icon(
                  status.icon,
                  size: 13,
                  color: done ? Colors.white : AppColors.inkFaint,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.6,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: done ? color.withValues(alpha: 0.35) : AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.smallStrong(
                      color: done ? AppColors.ink : AppColors.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppType.caption()),
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(note!, style: AppType.small()),
                    ),
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
