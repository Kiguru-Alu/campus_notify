import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';
import '../models/incident.dart';
import '../models/status_update.dart';

class IncidentFailure implements Exception {
  const IncidentFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// All Firestore access for incidents.
///
/// Query strategy: one broad ordered stream, with filtering derived on the
/// client. Firestore has no full-text search and each extra `where` with an
/// `orderBy` costs a composite index, so this keeps the index footprint at
/// one and makes filters instant with no extra reads. Good to a few thousand
/// documents; past that it needs server-side pagination and a search index.
class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _feedLimit = 200;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  CollectionReference<Map<String, dynamic>> _updatesOf(String incidentId) =>
      _incidents.doc(incidentId).collection('statusUpdates');

  /// Every report on campus, newest first.
  Stream<List<Incident>> watchAll() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .limit(_feedLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Incident.fromDoc).toList());
  }

  /// Reports filed by one student. This is the app's only compound query
  /// and the reason `firestore.indexes.json` exists.
  Stream<List<Incident>> watchMine(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Incident.fromDoc).toList());
  }

  Stream<Incident?> watchOne(String incidentId) {
    return _incidents.doc(incidentId).snapshots().map(
          (doc) => doc.exists ? Incident.fromDoc(doc) : null,
        );
  }

  Stream<List<StatusUpdate>> watchStatusUpdates(String incidentId) {
    return _updatesOf(incidentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StatusUpdate.fromDoc).toList());
  }

  /// One atomic batch, so an incident can never exist without a trail.
  Future<String> create({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? locationDetail,
    String? photoUrl,
    required String reporterId,
    required String reporterName,
    required bool isAnonymous,
  }) async {
    try {
      final docRef = _incidents.doc();
      final batch = _firestore.batch();

      batch.set(
        docRef,
        Incident.toCreateMap(
          title: title.trim(),
          description: description.trim(),
          category: category,
          location: location,
          locationDetail: locationDetail?.trim(),
          photoUrl: photoUrl,
          reporterId: reporterId,
          reporterName: reporterName,
          isAnonymous: isAnonymous,
        ),
      );

      batch.set(
        _updatesOf(docRef.id).doc(),
        StatusUpdate.toCreateMap(
          toStatus: IncidentStatus.submitted,
          actorId: reporterId,
          actorName: reporterName,
          note: 'Report submitted',
        ),
      );

      await batch.commit();
      return docRef.id;
    } on FirebaseException catch (error) {
      throw IncidentFailure(_describe(error));
    }
  }

  /// Firestore rules reject this from any non-staff account. The UI hides
  /// the control, but the rule is the control.
  Future<void> changeStatus({
    required String incidentId,
    required IncidentStatus from,
    required IncidentStatus to,
    required String actorId,
    required String actorName,
    String? note,
  }) async {
    try {
      final batch = _firestore.batch();

      batch.update(_incidents.doc(incidentId), {
        'status': to.id,
        'assignedToId': actorId,
        'assignedToName': actorName,
        'resolutionNote': to.isTerminal ? note : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        _updatesOf(incidentId).doc(),
        StatusUpdate.toCreateMap(
          fromStatus: from,
          toStatus: to,
          actorId: actorId,
          actorName: actorName,
          note: note,
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw IncidentFailure(_describe(error));
    }
  }

  /// An array union rather than a counter, so one student cannot inflate a
  /// report by tapping twice and the write needs no transaction.
  Future<void> toggleSupport({
    required String incidentId,
    required String uid,
    required bool isSupporting,
  }) async {
    try {
      await _incidents.doc(incidentId).update({
        'supporterIds': isSupporting
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
      });
    } on FirebaseException catch (error) {
      throw IncidentFailure(_describe(error));
    }
  }

  Future<void> updateDetails({
    required String incidentId,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? locationDetail,
  }) async {
    try {
      await _incidents.doc(incidentId).update({
        'title': title.trim(),
        'description': description.trim(),
        'category': category.id,
        'location': location,
        'locationDetail': locationDetail?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw IncidentFailure(_describe(error));
    }
  }

  /// Rules allow this only for the author of a still-`submitted` report.
  Future<void> delete(String incidentId) async {
    try {
      final updates = await _updatesOf(incidentId).get();
      final batch = _firestore.batch();
      for (final doc in updates.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_incidents.doc(incidentId));
      await batch.commit();
    } on FirebaseException catch (error) {
      throw IncidentFailure(_describe(error));
    }
  }

  String _describe(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to do that.',
      'unavailable' || 'deadline-exceeded' =>
        'Cannot reach the server. Check your connection.',
      'not-found' => 'That report no longer exists.',
      _ => 'Something went wrong. Try again.',
      'failed-precondition' =>
      'This list is not available yet. Try again shortly.',
    };
  }
}
