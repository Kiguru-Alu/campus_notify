import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';

/// Stored at `incidents/{id}`.
///
/// [supporterIds] lets students mark "this affects me too" rather than filing
/// a fifth report about the same dead tap, turning duplicate noise into a
/// priority signal. [isAnonymous] hides the reporter from other students but
/// not from staff, so a report is never untraceable.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    required this.supporterIds,
    required this.createdAt,
    required this.updatedAt,
    this.locationDetail,
    this.photoUrl,
    this.assignedToId,
    this.assignedToName,
    this.resolutionNote,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentStatus status;
  final String location;
  final String? locationDetail;
  final String? photoUrl;
  final String reporterId;
  final String reporterName;
  final bool isAnonymous;
  final List<String> supporterIds;
  final String? assignedToId;
  final String? assignedToName;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get supportCount => supporterIds.length;

  bool isSupportedBy(String uid) => supporterIds.contains(uid);

  /// What other students are allowed to see as the author.
  String get publicReporterName => isAnonymous ? 'Anonymous' : reporterName;

  String get fullLocation => (locationDetail == null || locationDetail!.isEmpty)
      ? location
      : '$location \u00b7 $locationDetail';

  /// A student may withdraw a report only before anyone has acted on it.
  /// Once staff have picked it up, the record is part of a work history.
  bool canBeDeletedBy(String uid) =>
      uid == reporterId && status == IncidentStatus.submitted;

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Incident(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Untitled report',
      description: (data['description'] as String?) ?? '',
      category: IncidentCategory.fromId(data['category'] as String?),
      status: IncidentStatus.fromId(data['status'] as String?),
      location: (data['location'] as String?) ?? 'Campus',
      locationDetail: data['locationDetail'] as String?,
      photoUrl: data['photoUrl'] as String?,
      reporterId: (data['reporterId'] as String?) ?? '',
      reporterName: (data['reporterName'] as String?) ?? 'Campus member',
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      supporterIds:
          (data['supporterIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => value.toString())
              .toList(growable: false),
      assignedToId: data['assignedToId'] as String?,
      assignedToName: data['assignedToName'] as String?,
      resolutionNote: data['resolutionNote'] as String?,
      // serverTimestamp() is null for a moment on the writing client, so
      // fall back rather than crashing the list that is already on screen.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  /// Shape written on creation. Timestamps are set by the server so a
  /// handset with a wrong clock cannot reorder the queue.
  static Map<String, dynamic> toCreateMap({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? locationDetail,
    String? photoUrl,
    required String reporterId,
    required String reporterName,
    required bool isAnonymous,
  }) {
    return {
      'title': title,
      'description': description,
      'category': category.id,
      'status': IncidentStatus.submitted.id,
      'location': location,
      'locationDetail': locationDetail,
      'photoUrl': photoUrl,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'isAnonymous': isAnonymous,
      'supporterIds': <String>[],
      'assignedToId': null,
      'assignedToName': null,
      'resolutionNote': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
