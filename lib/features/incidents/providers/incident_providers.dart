import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/incident_category.dart';
import '../../../core/constants/incident_status.dart';
import '../../../data/models/incident.dart';
import '../../../data/models/selected_photo.dart';
import '../../../data/models/status_update.dart';
import '../../../data/repositories/image_repository.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../auth/providers/auth_providers.dart';
import 'incident_filter.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository();
});

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  final repository = ImageRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

//  Raw data streams

/// One Firestore listener serves every screen that lists reports. Riverpod
/// disposes it when nothing is watching, so filtering never costs a read.
final allIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  return ref.watch(incidentRepositoryProvider).watchAll();
});

final myIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Incident>[]);
  return ref.watch(incidentRepositoryProvider).watchMine(uid);
});

final incidentProvider =
    StreamProvider.family<Incident?, String>((ref, incidentId) {
  return ref.watch(incidentRepositoryProvider).watchOne(incidentId);
});

final statusUpdatesProvider =
    StreamProvider.family<List<StatusUpdate>, String>((ref, incidentId) {
  return ref.watch(incidentRepositoryProvider).watchStatusUpdates(incidentId);
});

// Derived views

/// The argument for Riverpod in one provider: search and filter are a pure
/// transformation of state that already exists, so they cost no extra query,
/// no extra listener, and no state copied into a widget.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  return ref.watch(allIncidentsProvider).whenData(filter.apply);
});

/// Counts for the dashboard tiles.
class IncidentStats {
  const IncidentStats({
    required this.total,
    required this.submitted,
    required this.inProgress,
    required this.resolved,
  });

  final int total;
  final int submitted;
  final int inProgress;
  final int resolved;

  static const empty =
      IncidentStats(total: 0, submitted: 0, inProgress: 0, resolved: 0);

  factory IncidentStats.from(List<Incident> incidents) {
    var submitted = 0;
    var inProgress = 0;
    var resolved = 0;
    for (final incident in incidents) {
      switch (incident.status) {
        case IncidentStatus.submitted:
          submitted++;
        case IncidentStatus.inProgress:
          inProgress++;
        case IncidentStatus.resolved:
          resolved++;
        case IncidentStatus.closed:
          break;
      }
    }
    return IncidentStats(
      total: incidents.length,
      submitted: submitted,
      inProgress: inProgress,
      resolved: resolved,
    );
  }
}

final myStatsProvider = Provider<IncidentStats>((ref) {
  return ref.watch(myIncidentsProvider).maybeWhen(
        data: IncidentStats.from,
        orElse: () => IncidentStats.empty,
      );
});

/// Staff have filed nothing, so their profile counts work handled rather
/// than reports made.
final staffStatsProvider = Provider<IncidentStats>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return IncidentStats.empty;
  return ref.watch(allIncidentsProvider).maybeWhen(
        data: (incidents) => IncidentStats.from(
          incidents.where((i) => i.assignedToId == uid).toList(),
        ),
        orElse: () => IncidentStats.empty,
      );
});

final campusStatsProvider = Provider<IncidentStats>((ref) {
  return ref.watch(allIncidentsProvider).maybeWhen(
        data: IncidentStats.from,
        orElse: () => IncidentStats.empty,
      );
});

/// Anything unfinished, oldest first: the longest wait goes to the top.
final staffQueueProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  return ref.watch(allIncidentsProvider).whenData((incidents) {
    final open = incidents
        .where((incident) => !incident.status.isTerminal)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return open;
  });
});

// --- Report draft ----------------------------------------------------------

/// The non-text part of the report form. Title and description stay in
/// TextEditingControllers; everything other widgets react to lives here.
class ReportDraft {
  const ReportDraft({
    this.category = IncidentCategory.facilities,
    this.location,
    this.photo,
    this.isAnonymous = false,
  });

  final IncidentCategory category;
  final String? location;
  final SelectedPhoto? photo;
  final bool isAnonymous;

  bool get hasPhoto => photo != null;

  ReportDraft copyWith({
    IncidentCategory? category,
    String? location,
    SelectedPhoto? photo,
    bool? isAnonymous,
    bool clearPhoto = false,
  }) {
    return ReportDraft(
      category: category ?? this.category,
      location: location ?? this.location,
      photo: clearPhoto ? null : (photo ?? this.photo),
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}

class ReportDraftNotifier extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void setCategory(IncidentCategory value) =>
      state = state.copyWith(category: value);

  void setLocation(String? value) => state = state.copyWith(location: value);

  void setPhoto(SelectedPhoto? value) => state = value == null
      ? state.copyWith(clearPhoto: true)
      : state.copyWith(photo: value);

  void setAnonymous(bool value) => state = state.copyWith(isAnonymous: value);

  void reset() => state = const ReportDraft();
}

final reportDraftProvider =
    NotifierProvider<ReportDraftNotifier, ReportDraft>(ReportDraftNotifier.new);

// --- Write actions ---------------------------------------------------------

/// Every write goes through here, so loading and error handling are written
/// once instead of in each screen.
class IncidentController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  IncidentRepository get _incidents => ref.read(incidentRepositoryProvider);

  /// Photo first, then the document: a failed upload must not leave a report
  /// that silently lost its evidence.
  Future<String?> submitReport({
    required String title,
    required String description,
  }) async {
    final draft = ref.read(reportDraftProvider);
    final profile = ref.read(appUserProvider).value;
    if (profile == null) return null;
    if (draft.location == null) return null;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      String? photoUrl;
      if (draft.photo != null) {
        photoUrl = await ref.read(imageRepositoryProvider).uploadIncidentPhoto(
              bytes: draft.photo!.bytes,
              filename: draft.photo!.filename,
            );
      }
      return _incidents.create(
        title: title,
        description: description,
        category: draft.category,
        location: draft.location!,
        photoUrl: photoUrl,
        reporterId: profile.uid,
        reporterName: profile.fullName,
        isAnonymous: draft.isAnonymous,
      );
    });

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }

    state = const AsyncData(null);
    ref.read(reportDraftProvider.notifier).reset();
    return result.value;
  }

  Future<bool> changeStatus({
    required Incident incident,
    required IncidentStatus to,
    String? note,
  }) async {
    final profile = ref.read(appUserProvider).value;
    if (profile == null || !profile.isStaff) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _incidents.changeStatus(
        incidentId: incident.id,
        from: incident.status,
        to: to,
        actorId: profile.uid,
        actorName: profile.fullName,
        note: note,
      ),
    );
    return !state.hasError;
  }

  Future<void> toggleSupport(Incident incident) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || uid == incident.reporterId) return;
    state = await AsyncValue.guard(
      () => _incidents.toggleSupport(
        incidentId: incident.id,
        uid: uid,
        isSupporting: incident.isSupportedBy(uid),
      ),
    );
  }

  Future<bool> deleteReport(Incident incident) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || !incident.canBeDeletedBy(uid)) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _incidents.delete(incident.id));
    return !state.hasError;
  }
}

final incidentControllerProvider =
    AsyncNotifierProvider<IncidentController, void>(IncidentController.new);
