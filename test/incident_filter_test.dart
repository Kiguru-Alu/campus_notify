import 'package:campus_notify/core/constants/incident_category.dart';
import 'package:campus_notify/core/constants/incident_status.dart';
import 'package:campus_notify/data/models/incident.dart';
import 'package:campus_notify/features/incidents/providers/incident_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Incident build({
  required String id,
  required String title,
  IncidentCategory category = IncidentCategory.facilities,
  IncidentStatus status = IncidentStatus.submitted,
  String location = 'Social Commons',
  List<String> supporters = const [],
  int daysAgo = 0,
}) {
  final created = DateTime(2026, 11, 1).subtract(Duration(days: daysAgo));
  return Incident(
    id: id,
    title: title,
    description: 'Details for $title',
    category: category,
    status: status,
    location: location,
    reporterId: 'student-1',
    reporterName: 'Test Student',
    isAnonymous: false,
    supporterIds: supporters,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final reports = [
    build(id: 'a', title: 'Water off in residence',
        category: IncidentCategory.water, location: 'Student Residence',
        daysAgo: 1, supporters: ['s2', 's3']),
    build(id: 'b', title: 'Projector will not turn on',
        status: IncidentStatus.inProgress, daysAgo: 3),
    build(id: 'c', title: 'Overflowing bin by the cafeteria',
        category: IncidentCategory.sanitation, location: 'Cafeteria',
        status: IncidentStatus.resolved, daysAgo: 2),
  ];

  test('an empty filter returns everything', () {
    expect(const IncidentFilter().apply(reports).length, 3);
  });

  test('filters by status', () {
    final result =
        const IncidentFilter(status: IncidentStatus.inProgress).apply(reports);
    expect(result.single.id, 'b');
  });

  test('filters by category', () {
    final result =
        const IncidentFilter(category: IncidentCategory.water).apply(reports);
    expect(result.single.id, 'a');
  });

  test('search matches the title', () {
    expect(const IncidentFilter(query: 'projector').apply(reports).single.id, 'b');
  });

  test('search matches the location', () {
    expect(const IncidentFilter(query: 'cafeteria').apply(reports).single.id, 'c');
  });

  test('combined filters narrow rather than widen', () {
    final result = const IncidentFilter(
      query: 'water',
      status: IncidentStatus.resolved,
    ).apply(reports);
    expect(result, isEmpty);
  });

  test('newest first is the default order', () {
    expect(const IncidentFilter().apply(reports).first.id, 'a');
  });

  test('most affected ranks by supporter count', () {
    final result =
        const IncidentFilter(sort: IncidentSort.mostSupported).apply(reports);
    expect(result.first.id, 'a');
  });
}
