import 'package:campus_notify/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('campusEmail', () {
    test('accepts a student address', () {
      expect(Validators.campusEmail('b.mahui@alustudent.com'), isNull);
    });

    test('accepts a staff address', () {
      expect(Validators.campusEmail('facilities@alueducation.com'), isNull);
    });

    test('rejects an outside domain', () {
      expect(Validators.campusEmail('someone@gmail.com'), isNotNull);
    });

    test('rejects malformed input', () {
      expect(Validators.campusEmail('not-an-email'), isNotNull);
    });
  });

  group('password', () {
    test('rejects anything under eight characters', () {
      expect(Validators.password('ab1'), isNotNull);
    });

    test('rejects letters with no digit', () {
      expect(Validators.password('passwordonly'), isNotNull);
    });

    test('accepts a mixed password of sufficient length', () {
      expect(Validators.password('campus2026'), isNull);
    });
  });

  group('incident fields', () {
    test('rejects a title that is too short to act on', () {
      expect(Validators.incidentTitle('Tap'), isNotNull);
    });

    test('rejects a description with no useful detail', () {
      expect(Validators.incidentDescription('broken'), isNotNull);
    });

    test('accepts a description a technician could work from', () {
      expect(
        Validators.incidentDescription(
          'No water on the second floor of the residence since 6am today.',
        ),
        isNull,
      );
    });
  });
}
