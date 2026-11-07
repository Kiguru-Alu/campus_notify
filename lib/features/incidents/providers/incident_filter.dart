import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/incident_category.dart';
import '../../../core/constants/incident_status.dart';
import '../../../data/models/incident.dart';

/// How a list of reports is narrowed on screen. Immutable so Riverpod can
/// cheaply skip rebuilds when nothing changed.
class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.category,
    this.status,
    this.location,
    this.sort = IncidentSort.newest,
  });

  final String query;
  final IncidentCategory? category;
  final IncidentStatus? status;
  final String? location;
  final IncidentSort sort;

  bool get isActive =>
      query.trim().isNotEmpty ||
      category != null ||
      status != null ||
      location != null;

  int get activeCount => [
        category != null,
        status != null,
        location != null,
      ].where((isSet) => isSet).length;

  IncidentFilter copyWith({
    String? query,
    IncidentCategory? category,
    IncidentStatus? status,
    String? location,
    IncidentSort? sort,
    bool clearCategory = false,
    bool clearStatus = false,
    bool clearLocation = false,
  }) {
    return IncidentFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      location: clearLocation ? null : (location ?? this.location),
      sort: sort ?? this.sort,
    );
  }

  /// Pure, so it is testable without Firestore, Riverpod or a widget tree.
  List<Incident> apply(List<Incident> incidents) {
    final needle = query.trim().toLowerCase();

    final result = incidents.where((incident) {
      if (category != null && incident.category != category) return false;
      if (status != null && incident.status != status) return false;
      if (location != null && incident.location != location) return false;
      if (needle.isEmpty) return true;
      return incident.title.toLowerCase().contains(needle) ||
          incident.description.toLowerCase().contains(needle) ||
          incident.location.toLowerCase().contains(needle) ||
          incident.category.label.toLowerCase().contains(needle);
    }).toList();

    switch (sort) {
      case IncidentSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case IncidentSort.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case IncidentSort.mostSupported:
        result.sort((a, b) {
          final bySupport = b.supportCount.compareTo(a.supportCount);
          return bySupport != 0
              ? bySupport
              : b.createdAt.compareTo(a.createdAt);
        });
    }
    return result;
  }
}

enum IncidentSort {
  newest('Newest first'),
  oldest('Oldest first'),
  mostSupported('Most affected');

  const IncidentSort(this.label);
  final String label;
}

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setCategory(IncidentCategory? value) => state = value == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: value);

  void setStatus(IncidentStatus? value) => state = value == null
      ? state.copyWith(clearStatus: true)
      : state.copyWith(status: value);

  void setLocation(String? value) => state = value == null
      ? state.copyWith(clearLocation: true)
      : state.copyWith(location: value);

  void setSort(IncidentSort value) => state = state.copyWith(sort: value);

  void clear() => state = const IncidentFilter();
}

final incidentFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(
  IncidentFilterNotifier.new,
);
