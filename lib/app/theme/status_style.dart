import 'package:flutter/material.dart';

import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';
import 'app_colors.dart';

/// Colour and icon mapping lives in the theme layer so the domain enums
/// stay free of Flutter imports and testable without a widget binding.
extension IncidentStatusStyle on IncidentStatus {
  Color get color => switch (this) {
        IncidentStatus.submitted => AppColors.submitted,
        IncidentStatus.inProgress => AppColors.inProgress,
        IncidentStatus.resolved => AppColors.resolved,
        IncidentStatus.closed => AppColors.closed,
      };

  Color get tint => switch (this) {
        IncidentStatus.submitted => AppColors.submittedTint,
        IncidentStatus.inProgress => AppColors.inProgressTint,
        IncidentStatus.resolved => AppColors.resolvedTint,
        IncidentStatus.closed => AppColors.closedTint,
      };

  IconData get icon => switch (this) {
        IncidentStatus.submitted => Icons.outbox_outlined,
        IncidentStatus.inProgress => Icons.engineering_outlined,
        IncidentStatus.resolved => Icons.check_rounded,
        IncidentStatus.closed => Icons.remove_rounded,
      };
}

extension IncidentCategoryStyle on IncidentCategory {
  IconData get icon => switch (this) {
        IncidentCategory.facilities => Icons.chair_outlined,
        IncidentCategory.water => Icons.water_drop_outlined,
        IncidentCategory.electricity => Icons.bolt_outlined,
        IncidentCategory.sanitation => Icons.delete_outline,
        IncidentCategory.safety => Icons.shield_outlined,
        IncidentCategory.network => Icons.wifi_outlined,
      };
}
