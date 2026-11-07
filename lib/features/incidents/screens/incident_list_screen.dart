import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../providers/incident_filter.dart';
import '../providers/incident_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';
import 'report_incident_screen.dart';

/// Serves both the campus feed and "my reports". The only difference is
/// which provider it reads, so the layout, search and filtering are
/// written once.
class IncidentListScreen extends ConsumerStatefulWidget {
  const IncidentListScreen({super.key, this.mineOnly = false});

  final bool mineOnly;

  @override
  ConsumerState<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends ConsumerState<IncidentListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(incidentFilterProvider);
    final incidents = widget.mineOnly
        ? ref.watch(myIncidentsProvider).whenData(filter.apply)
        : ref.watch(filteredIncidentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mineOnly ? 'My reports' : 'Campus reports'),
        titleTextStyle: AppType.headline(),
        toolbarHeight: 64,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged:
                        ref.read(incidentFilterProvider.notifier).setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search title, place or category',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.inkFaint),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      suffixIcon: filter.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _search.clear();
                                ref
                                    .read(incidentFilterProvider.notifier)
                                    .setQuery('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterButton(count: filter.activeCount),
              ],
            ),
          ),
          if (filter.isActive) const _ActiveFilterRow(),
          Expanded(
            child: incidents.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: '$error',
                onRetry: () => ref.invalidate(allIncidentsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return filter.isActive
                      ? EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'Nothing matches',
                          message:
                              'No reports fit those filters. Loosen them to '
                              'see more.',
                          actionLabel: 'Clear filters',
                          onAction:
                              ref.read(incidentFilterProvider.notifier).clear,
                        )
                      : EmptyState(
                          icon: Icons.inbox_outlined,
                          title: widget.mineOnly
                              ? 'You have not reported anything'
                              : 'No reports yet',
                          message: widget.mineOnly
                              ? 'Anything you report will be listed here with '
                                  'its current status.'
                              : 'Be the first to flag something.',
                          actionLabel: 'Report an issue',
                          onAction: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ReportIncidentScreen(),
                            ),
                          ),
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    120,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => IncidentCard(
                    incident: items[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            IncidentDetailScreen(incidentId: items[i].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: count > 0 ? AppColors.navy : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
      child: InkWell(
        onTap: () => FilterSheet.show(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
        child: Container(
          height: 50,
          width: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
            border: Border.all(
              color: count > 0 ? AppColors.navy : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: count > 0 ? Colors.white : AppColors.ink,
              ),
              if (count > 0) ...[
                const SizedBox(width: 3),
                Text('$count', style: AppType.caption(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows what is currently narrowing the list, each one removable, so the
/// filter state is never hidden behind a sheet.
class _ActiveFilterRow extends ConsumerWidget {
  const _ActiveFilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidentFilterProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);

    final chips = <Widget>[
      if (filter.status != null)
        _RemovableChip(
          label: filter.status!.label,
          onRemove: () => notifier.setStatus(null),
        ),
      if (filter.category != null)
        _RemovableChip(
          label: filter.category!.label,
          onRemove: () => notifier.setCategory(null),
        ),
      if (filter.location != null)
        _RemovableChip(
          label: filter.location!,
          onRemove: () => notifier.setLocation(null),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: 6),
      decoration: BoxDecoration(
        color: AppColors.navyTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppType.caption(color: AppColors.navy)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 13, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}
