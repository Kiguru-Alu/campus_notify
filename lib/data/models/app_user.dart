import 'package:cloud_firestore/cloud_firestore.dart';

/// Two roles only: a reporter and a resolver.
enum UserRole {
  student('student', 'Student'),
  staff('staff', 'Campus staff');

  const UserRole(this.id, this.label);

  final String id;
  final String label;

  static UserRole fromId(String? id) => UserRole.values.firstWhere(
        (role) => role.id == id,
        orElse: () => UserRole.student,
      );
}

/// Stored at `users/{uid}`. Firebase Auth owns credentials, this owns
/// everything else. Role lives here rather than in a custom auth claim
/// because claims need Cloud Functions, which need the Blaze plan.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.programme,
    this.photoUrl,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? programme;
  final String? photoUrl;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      fullName: (data['fullName'] as String?)?.trim() ?? 'Campus member',
      email: (data['email'] as String?) ?? '',
      role: UserRole.fromId(data['role'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      programme: data['programme'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'fullName': fullName,
        'email': email,
        'role': role.id,
        'programme': programme,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

  AppUser copyWith({String? fullName, String? programme, String? photoUrl}) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role,
      createdAt: createdAt,
      programme: programme ?? this.programme,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
