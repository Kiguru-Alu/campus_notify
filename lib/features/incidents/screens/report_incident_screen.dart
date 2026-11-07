import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/campus.dart';
import '../../../core/utils/validators.dart';
import '../providers/incident_providers.dart';
import '../widgets/category_picker.dart';
import '../widgets/photo_field.dart';
import 'incident_detail_screen.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _locationMissing = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final draft = ref.read(reportDraftProvider);
    final formValid = _formKey.currentState!.validate();
    setState(() => _locationMissing = draft.location == null);
    if (!formValid || draft.location == null) return;

    FocusScope.of(context).unfocus();
    final id = await ref.read(incidentControllerProvider.notifier).submitReport(
          title: _title.text,
          description: _description.text,
        );
    if (!mounted) return;

    if (id == null) {
      final error = ref.read(incidentControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return;
    }

    // Straight to the report that was just filed, so the student sees the
    // thing they created rather than a confirmation they have to dismiss.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => IncidentDetailScreen(incidentId: id, justCreated: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);
    final notifier = ref.read(reportDraftProvider.notifier);
    final busy = ref.watch(incidentControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an issue'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: busy ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.xxxl,
            ),
            children: [
              const _FieldLabel('What kind of issue?'),
              CategoryPicker(
                selected: draft.category,
                onSelect: notifier.setCategory,
              ),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('Title'),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Water has been off since this morning',
                ),
                validator: Validators.incidentTitle,
              ),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('What is happening?'),
              TextFormField(
                controller: _description,
                maxLines: 5,
                maxLength: 1200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'When it started, who it affects, anything the '
                      'team should bring with them.',
                ),
                validator: Validators.incidentDescription,
              ),
              const SizedBox(height: AppSpacing.sm),

              const _FieldLabel('Where is it?'),
              DropdownButtonFormField<String>(
                initialValue: draft.location,
                isExpanded: true,
                hint: const Text('Pick a building or area'),
                decoration: InputDecoration(
                  errorText: _locationMissing ? 'Choose a location' : null,
                ),
                items: [
                  for (final location in Campus.locations)
                    DropdownMenuItem(value: location, child: Text(location)),
                ],
                onChanged: (value) {
                  notifier.setLocation(value);
                  if (_locationMissing) setState(() => _locationMissing = false);
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('Photo'),
              PhotoField(photo: draft.photo, onChanged: notifier.setPhoto),
              const SizedBox(height: AppSpacing.xl),

              _AnonymousToggle(
                value: draft.isAnonymous,
                onChanged: notifier.setAnonymous,
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
                    : const Text('Send report'),
              ),
              if (busy && draft.hasPhoto) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Uploading your photo. Keep the app open.',
                  textAlign: TextAlign.center,
                  style: AppType.caption(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Text(text, style: AppType.subtitle()),
    );
  }
}

/// Anonymity is offered because students hesitate to attach their name to
/// safety and sanitation reports. Staff still see the reporter.
class _AnonymousToggle extends StatelessWidget {
  const _AnonymousToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hide my name', style: AppType.smallStrong()),
                const SizedBox(height: 2),
                Text(
                  'Other students see "Anonymous". Facilities staff still '
                  'see who reported it.',
                  style: AppType.caption(),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.navy,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
