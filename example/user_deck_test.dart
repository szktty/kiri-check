import 'package:kiri_check/kiri_check.dart';

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

  static User user(Deck deck) {
    final drewId = deck.draw(integer());
    final drewName = deck.draw(name());
    final drewBirthday = deck.draw(birthday());
    final drewEmail = deck.draw(email());
    return User(
      id: drewId,
      name: drewName,
      birthday: drewBirthday,
      email: drewEmail,
    );
  }
}

void main() {
  property('using deck()', () {
    forAll(
      deck(),
      (deck) {
        final user = Gen.user(deck);
        print('deck user: $user');
      },
    );
  });
}
