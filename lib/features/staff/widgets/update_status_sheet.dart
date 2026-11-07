import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/status_style.dart';
import '../../../core/constants/incident_status.dart';
import '../../../data/models/incident.dart';
import '../../incidents/providers/incident_providers.dart';

/// Staff-only control for moving a report through its lifecycle.
class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});

  final Incident incident;

  static Future<void> show(BuildContext context, Incident incident) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: UpdateStatusSheet(incident: incident),
      ),
    );
  }

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  late IncidentStatus _selected = widget.incident.status;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref.read(incidentControllerProvider.notifier).changeStatus(
          incident: widget.incident,
          to: _selected,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Status updated to ${_selected.label.toLowerCase()}'
              : '${ref.read(incidentControllerProvider).error}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(incidentControllerProvider).isLoading;
    // A note is required when closing a report without fixing it: a student
    // deserves a reason, not a silent dismissal.
    final noteRequired = _selected == IncidentStatus.closed;
    final canSave = _selected != widget.incident.status &&
        (!noteRequired || _note.text.trim().isNotEmpty);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update status', style: AppType.headline()),
            const SizedBox(height: 2),
            Text(widget.incident.title, style: AppType.small()),
            const SizedBox(height: AppSpacing.lg),
            for (final status in IncidentStatus.values)
              _StatusOption(
                status: status,
                selected: _selected == status,
                onTap: () => setState(() => _selected = status),
              ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _note,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: noteRequired
                    ? 'Why is this being closed?'
                    : 'Note for the reporter (optional)',
                hintText: 'What was done, or what happens next.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: busy || !canSave ? null : _save,
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Save update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final IncidentStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? status.tint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
            border: Border.all(
              color: selected ? status.color : AppColors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(status.icon, size: 18, color: status.color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.label, style: AppType.smallStrong()),
                    Text(status.description, style: AppType.caption()),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    size: 18, color: status.color),
            ],
          ),
        ),
      ),
    );
  }
}
