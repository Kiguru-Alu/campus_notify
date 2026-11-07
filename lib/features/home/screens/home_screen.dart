import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/alu_pattern.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../auth/providers/auth_providers.dart';
import '../../incidents/providers/incident_providers.dart';
import '../../incidents/screens/incident_detail_screen.dart';
import '../../incidents/screens/report_incident_screen.dart';
import '../../incidents/widgets/incident_card.dart';
import '../widgets/stat_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appUserProvider).value;
    final isStaff = ref.watch(isStaffProvider);
    final stats = isStaff
        ? ref.watch(campusStatsProvider)
        : ref.watch(myStatsProvider);
    final recent = ref.watch(allIncidentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        // Firestore streams update on their own; the pull gesture exists
        // because people expect it, and it re-subscribes after a dropout.
        onRefresh: () async => ref.invalidate(allIncidentsProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                name: profile?.fullName ?? '',
                isStaff: isStaff,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xl,
                AppSpacing.gutter,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    isStaff ? 'Across campus' : 'Your reports',
                    style: AppType.title(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      StatTile(
                        value: stats.submitted,
                        label: 'Waiting',
                        accent: AppColors.submitted,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatTile(
                        value: stats.inProgress,
                        label: 'In progress',
                        accent: AppColors.inProgress,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatTile(
                        value: stats.resolved,
                        label: 'Resolved',
                        accent: AppColors.resolved,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader('Latest on campus'),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            recent.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: LoadingView(),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: ErrorView(
                    message: '$error',
                    onRetry: () => ref.invalidate(allIncidentsProvider),
                  ),
                ),
              ),
              data: (incidents) {
                if (incidents.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Nothing reported yet',
                        message:
                            'When something on campus breaks, this is where '
                            'it shows up.',
                        actionLabel: 'Report an issue',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReportIncidentScreen(),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final latest = incidents.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    120,
                  ),
                  sliver: SliverList.separated(
                    itemCount: latest.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) => IncidentCard(
                      incident: latest[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              IncidentDetailScreen(incidentId: latest[i].id),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.isStaff});

  final String name;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusSheet),
                  ),
                  child: const AluPattern(),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              Formatters.initials(name),
                              style: AppType.smallStrong(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $firstName',
                                  style:
                                      AppType.subtitle(color: Colors.white),
                                ),
                                Text(
                                  isStaff ? 'Campus staff' : 'Student',
                                  style: AppType.caption(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        isStaff
                            ? 'Keep the queue moving.'
                            : 'See something broken?\nTell someone who can fix it.',
                        style: AppType.display(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isStaff
                            ? 'Reports waiting longest appear first in your queue.'
                            : 'Reports go straight to the facilities team.',
                        style: AppType.small(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
