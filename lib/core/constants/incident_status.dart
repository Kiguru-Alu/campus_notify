/// Four states only. Extra states mean more decisions for a facilities
/// officer standing in a corridor with a phone.
enum IncidentStatus {
  submitted('submitted', 'Submitted', 'Logged and waiting for review'),
  inProgress('in_progress', 'In progress', 'A team has picked this up'),
  resolved('resolved', 'Resolved', 'Reported as fixed'),
  closed('closed', 'Closed', 'Closed without a fix');

  const IncidentStatus(this.id, this.label, this.description);

  /// Written to Firestore. Never persist `name`: renaming a value would
  /// orphan existing documents.
  final String id;
  final String label;
  final String description;

  static IncidentStatus fromId(String? id) {
    return IncidentStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => IncidentStatus.submitted,
    );
  }

  /// Ordered states shown in the detail-screen timeline.
  static const List<IncidentStatus> timeline = [
    IncidentStatus.submitted,
    IncidentStatus.inProgress,
    IncidentStatus.resolved,
  ];

  bool get isTerminal =>
      this == IncidentStatus.resolved || this == IncidentStatus.closed;
}
