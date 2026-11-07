import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/shell/app_shell.dart';
import '../shared/widgets/feedback_views.dart';
import 'theme/app_colors.dart';

/// Decides what the app shows based on the auth stream alone. There is no
/// imperative navigation on sign-in or sign-out: the stream changes and the
/// tree follows.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);

    return session.when(
      loading: () => const _Splash(),
      error: (error, _) => Scaffold(
        body: ErrorView(message: '$error'),
      ),
      data: (user) {
        if (user == null) return const SignInScreen();
        if (!user.emailVerified) return const VerifyEmailScreen();

        // The profile document carries the role, so the shell waits for it
        // rather than guessing and re-rendering.
        return ref.watch(appUserProvider).when(
              loading: () => const _Splash(),
              error: (error, _) => Scaffold(body: ErrorView(message: '$error')),
              data: (profile) =>
                  profile == null ? const _Splash() : const AppShell(),
            );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
    );
  }
}
