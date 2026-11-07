import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/incident_status.dart';

/// One entry in an incident's audit trail, at
/// `incidents/{id}/statusUpdates/{updateId}`. A subcollection rather than an
/// array field: it grows without bound and is read on one screen only, so
/// keeping it out of the parent keeps list queries small.
class StatusUpdate {
  const StatusUpdate({
    required this.id,
    required this.toStatus,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    this.fromStatus,
    this.note,
  });

  final String id;
  final IncidentStatus? fromStatus;
  final IncidentStatus toStatus;
  final String actorId;
  final String actorName;
  final String? note;
  final DateTime createdAt;

  factory StatusUpdate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final from = data['fromStatus'] as String?;
    return StatusUpdate(
      id: doc.id,
      fromStatus: from == null ? null : IncidentStatus.fromId(from),
      toStatus: IncidentStatus.fromId(data['toStatus'] as String?),
      actorId: (data['actorId'] as String?) ?? '',
      actorName: (data['actorName'] as String?) ?? 'Campus staff',
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toCreateMap({
    IncidentStatus? fromStatus,
    required IncidentStatus toStatus,
    required String actorId,
    required String actorName,
    String? note,
  }) {
    return {
      'fromStatus': fromStatus?.id,
      'toStatus': toStatus.id,
      'actorId': actorId,
      'actorName': actorName,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
