import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/campus.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _programme = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Drives the live role preview below the email field.
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _programme.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _isStaffAddress =>
      _email.text.trim().toLowerCase().endsWith('@${Campus.staffEmailDomain}');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final created = await ref.read(authControllerProvider.notifier).signUp(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
          programme: _programme.text,
        );
    // On success the account is signed in but unverified, so AuthGate
    // swaps itself to the verification screen. This route just closes.
    if (created && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    final busy = controller.isLoading;

    return AuthScaffold(
      title: 'Create your\naccount',
      subtitle: 'Only ALU addresses can register.',
      onBack: busy ? null : () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.hasError) AuthMessage('${controller.error}'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: Validators.fullName,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Campus email',
                hintText: 'you@alustudent.com',
              ),
              validator: Validators.campusEmail,
            ),
            if (_isStaffAddress) ...[
              const SizedBox(height: AppSpacing.sm),
              const _RoleNotice(),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _programme,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Programme or department (optional)',
                hintText: 'BSc Software Engineering',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters, with a number',
                helperStyle: AppType.caption(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.inkFaint,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) =>
                  Validators.confirmPassword(value, _password.text),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'We send a verification link to your inbox. You will need it '
              'before you can post a report.',
              textAlign: TextAlign.center,
              style: AppType.caption(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Role is derived from the email domain, so the app says so rather than
/// granting staff powers silently.
class _RoleNotice extends StatelessWidget {
  const _RoleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: AppColors.navy),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This address registers as campus staff, with permission to '
              'update report statuses.',
              style: AppType.caption(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}
