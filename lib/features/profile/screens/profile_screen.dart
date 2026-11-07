import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_user.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../auth/providers/auth_providers.dart';
import '../../incidents/providers/incident_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appUserProvider);
    final isStaff = ref.watch(isStaffProvider);
    final stats =
        isStaff ? ref.watch(staffStatsProvider) : ref.watch(myStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        titleTextStyle: AppType.headline(),
        toolbarHeight: 64,
      ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: '$error'),
        data: (user) {
          if (user == null) return const LoadingView();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              120,
            ),
            children: [
              _IdentityCard(user: user),
              const SizedBox(height: AppSpacing.xl),
              Text(isStaff ? 'Your workload' : 'Your activity',
                  style: AppType.subtitle()),
              const SizedBox(height: AppSpacing.md),
              _ActivityRow(
                label: isStaff ? 'Reports handled' : 'Reports filed',
                value: '${stats.total}',
                icon: Icons.description_outlined,
              ),
              _ActivityRow(
                label: isStaff ? 'Currently open' : 'Being worked on',
                value: '${stats.inProgress}',
                icon: Icons.engineering_outlined,
              ),
              _ActivityRow(
                label: 'Resolved',
                value: '${stats.resolved}',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.lineStrong),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sign out?', style: AppType.title()),
        content: Text('You will need your password to get back in.',
            style: AppType.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              Formatters.initials(user.fullName),
              style: AppType.title(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.subtitle(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isStaff
                            ? AppColors.redTint
                            : AppColors.navyTint,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        user.role.label,
                        style: AppType.caption(
                          color: user.isStaff ? AppColors.red : AppColors.navy,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(user.email, style: AppType.caption()),
                if (user.programme != null) ...[
                  const SizedBox(height: 2),
                  Text(user.programme!, style: AppType.caption()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppType.body())),
          Text(value, style: AppType.title()),
        ],
      ),
    );
  }
}
