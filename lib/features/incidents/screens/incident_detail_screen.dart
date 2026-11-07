import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/incident.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../staff/widgets/update_status_sheet.dart';
import '../providers/incident_providers.dart';
import '../widgets/status_timeline.dart';

class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
    this.justCreated = false,
  });

  final String incidentId;
  final bool justCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    final isStaff = ref.watch(isStaffProvider);
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
        actions: [
          incident.maybeWhen(
            data: (value) => value == null
                ? const SizedBox.shrink()
                : _OverflowMenu(incident: value),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: incident.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: '$error'),
        data: (value) {
          if (value == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Report not found',
              message: 'It may have been withdrawn by the person who filed it.',
            );
          }
          return _Body(
            incident: value,
            isStaff: isStaff,
            uid: uid,
            justCreated: justCreated,
          );
        },
      ),
      bottomNavigationBar: incident.maybeWhen(
        data: (value) => value == null || !isStaff
            ? null
            : _StaffActionBar(incident: value),
        orElse: () => null,
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.incident,
    required this.isStaff,
    required this.uid,
    required this.justCreated,
  });

  final Incident incident;
  final bool isStaff;
  final String? uid;
  final bool justCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updates = ref.watch(statusUpdatesProvider(incident.id));
    final isOwn = uid == incident.reporterId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      children: [
        if (justCreated) const _SubmittedBanner(),
        Row(
          children: [
            Expanded(
              child: Text(Formatters.reference(incident.id),
                  style: AppType.code()),
            ),
            StatusChip(incident.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(incident.title, style: AppType.headline()),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CategoryChip(incident.category),
            LocationChip(incident.fullLocation),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Filed by ${isStaff ? incident.reporterName : incident.publicReporterName}'
          ' \u00b7 ${Formatters.absolute(incident.createdAt)}',
          style: AppType.caption(),
        ),
        if (isStaff && incident.isAnonymous) ...[
          const SizedBox(height: 4),
          Text(
            'Hidden from other students',
            style: AppType.caption(color: AppColors.inProgress),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        if (incident.photoUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: CachedNetworkImage(
              imageUrl: incident.photoUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: AppColors.canvas,
                child: const LoadingView(),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 120,
                color: AppColors.canvas,
                alignment: Alignment.center,
                child: Text('Photo could not be loaded',
                    style: AppType.small()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        Text('Description', style: AppType.subtitle()),
        const SizedBox(height: AppSpacing.sm),
        Text(incident.description, style: AppType.body()),

        const SizedBox(height: AppSpacing.xl),
        if (!isOwn) _SupportButton(incident: incident, uid: uid),
        if (incident.supportCount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            '${incident.supportCount} other '
            '${incident.supportCount == 1 ? "person says" : "people say"} '
            'this affects them.',
            style: AppType.small(),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Progress', style: AppType.subtitle()),
              const SizedBox(height: AppSpacing.lg),
              updates.when(
                loading: () => const LoadingView(),
                error: (error, _) => Text('$error', style: AppType.small()),
                data: (items) => StatusTimeline(
                  updates: items,
                  current: incident.status,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  const _SubmittedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.resolvedTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.resolved),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Report sent. You will see every status change here.',
              style: AppType.small(color: AppColors.resolved),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportButton extends ConsumerWidget {
  const _SupportButton({required this.incident, required this.uid});

  final Incident incident;
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supporting = uid != null && incident.isSupportedBy(uid!);

    return OutlinedButton.icon(
      onPressed: () =>
          ref.read(incidentControllerProvider.notifier).toggleSupport(incident),
      icon: Icon(
        supporting ? Icons.how_to_reg_rounded : Icons.group_add_outlined,
        size: 18,
      ),
      label: Text(
        supporting ? 'You marked this as affecting you' : 'This affects me too',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: supporting ? AppColors.navy : AppColors.ink,
        side: BorderSide(
          color: supporting ? AppColors.navy : AppColors.lineStrong,
        ),
      ),
    );
  }
}

class _StaffActionBar extends StatelessWidget {
  const _StaffActionBar({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: () => UpdateStatusSheet.show(context, incident),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Update status'),
        ),
      ),
    );
  }
}

/// Withdrawal lives behind the overflow menu, and only appears while the
/// report is still untouched.
class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    if (uid == null || !incident.canBeDeletedBy(uid)) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (_) => _confirmDelete(context, ref),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Text('Withdraw report',
              style: AppType.body(color: AppColors.danger)),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Withdraw this report?', style: AppType.title()),
        content: Text(
          'It disappears from the campus feed and the facilities queue.',
          style: AppType.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Withdraw',
                style: AppType.smallStrong(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final removed = await ref
        .read(incidentControllerProvider.notifier)
        .deleteReport(incident);
    if (removed && context.mounted) Navigator.of(context).pop();
  }
}
