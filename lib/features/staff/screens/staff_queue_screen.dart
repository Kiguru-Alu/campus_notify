import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/incident_status.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../incidents/providers/incident_providers.dart';
import '../../incidents/screens/incident_detail_screen.dart';
import '../../incidents/widgets/incident_card.dart';

/// The staff working view: everything unfinished, oldest first.
class StaffQueueScreen extends ConsumerWidget {
  const StaffQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(staffQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work queue'),
        titleTextStyle: AppType.headline(),
        toolbarHeight: 64,
      ),
      body: queue.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(allIncidentsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Queue is clear',
              message: 'Nothing is waiting. New reports appear here as they '
                  'come in.',
            );
          }
          final waiting = items
              .where((i) => i.status == IncidentStatus.submitted)
              .length;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              120,
            ),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _QueueSummary(open: items.length, waiting: waiting);
              }
              final incident = items[index - 1];
              return IncidentCard(
                incident: incident,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        IncidentDetailScreen(incidentId: incident.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({required this.open, required this.waiting});

  final int open;
  final int waiting;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$open open', style: AppType.display(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  waiting == 0
                      ? 'All of them have been picked up.'
                      : '$waiting still waiting to be picked up.',
                  style: AppType.small(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.engineering_outlined,
              color: Colors.white24, size: 40),
        ],
      ),
    );
  }
}
