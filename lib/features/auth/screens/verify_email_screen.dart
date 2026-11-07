import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _poll;
  String? _notice;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Firebase gives no push signal when the link is followed, so the app
    // polls while this screen is open and stops as soon as it leaves.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool quiet = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    final verified =
        await ref.read(authControllerProvider.notifier).checkVerification();
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!verified && !quiet) {
        _notice = 'Not verified yet. Open the link in your inbox, then retry.';
      }
    });
  }

  Future<void> _resend() async {
    final sent =
        await ref.read(authControllerProvider.notifier).resendVerification();
    if (!mounted) return;
    setState(() => _notice = sent
        ? 'Verification email sent again.'
        : 'Could not resend just now. Wait a moment and try again.');
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).value?.email ?? 'your inbox';

    return AuthScaffold(
      title: 'Check your\ninbox',
      subtitle: 'One step left before you can report.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_notice != null)
            AuthMessage(_notice!, isError: !_notice!.contains('sent')),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.navy),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sent to', style: AppType.caption()),
                      const SizedBox(height: 2),
                      Text(email, style: AppType.bodyStrong()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Verification keeps the reporting queue limited to real campus '
            'members, so facilities staff can trust what they see.',
            style: AppType.small(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _checking ? null : () => _check(),
            child: _checking
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('I have verified'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _resend,
            child: const Text('Resend the link'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
