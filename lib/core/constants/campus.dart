/// Location is a controlled list, not free text. "Near the stairs by the
/// thing" cannot be filtered on.
class Campus {
  const Campus._();

  static const List<String> locations = [
    'Learning Commons',
    'Enterprize Commons',
    'Social Commons',
    'Library',
    'Cafeteria',
    'Student Residence',
    'Sports Field',
    'Parking & Grounds',
    'Lab Wing',
    'Administration',
  ];

  /// Checked in the client for fast feedback and again in Firestore rules,
  /// which is the boundary that actually matters.
  static const String emailDomain = 'alustudent.com';
  static const String staffEmailDomain = 'alueducation.com';
}
