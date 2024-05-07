import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

final class User {
  User({
    required this.id,
    required this.name,
    required this.birthday,
    required this.email,
  });

  final int id;
  final String name;
  final DateTime birthday;
  final String email;

  int getAge() {
    final currentDate = DateTime.now();
    var age = currentDate.year - birthday.year;
    if (birthday.month > currentDate.month ||
        (birthday.month == currentDate.month &&
            birthday.day > currentDate.day)) {
      age--;
    }
    return age;
  }

  @override
  String toString() =>
      'User(id: $id, name: $name, birthday: $birthday, email: $email)';
}

abstract class Gen {
  static Arbitrary<String> name() => string(
        maxLength: 50,
        characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
      );

  static Arbitrary<DateTime> birthday() => dateTime(
        min: DateTime(1900),
        max: DateTime.now(),
      );

  static Arbitrary<String> email() => string(
        maxLength: 50,
        characterSet: CharacterSet.fromCharacters(
          '@abcdefghijklmnopqrstuvwxyz0123456789.',
        ),
      );

  static Arbitrary<User> user() => combine4(
        integer(),
        name(),
        birthday(),
        email(),
        (id, name, birthday, email) => User(
          id: id,
          name: name,
          birthday: birthday,
          email: email,
        ),
      );
}

void main() {
  property('using combine()', () {
    forAll(
      Gen.user(),
      (user) {
        print('user: $user');
      },
    );
  });

  property('User should have valid age', () {
    forAll(
      Gen.user(),
      (user) {
        final age = user.getAge();
        final currentDate = DateTime.now();
        final expectedMinAge = currentDate.year - user.birthday.year - 1;
        final expectedMaxAge = currentDate.year - user.birthday.year;
        expect(age >= expectedMinAge && age <= expectedMaxAge, isTrue);
        print(
          'User age is valid for: $age, expected: $expectedMinAge-$expectedMaxAge',
        );
      },
    );
  });
}
