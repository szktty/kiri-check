import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

// TODO: 最終的にexampleに移す
// SQLiteを使う

abstract class Gen {
  // TODO: dynamicは必要？
  static Arbitrary<dynamic> title() =>
      oneOf([string(), string().map((s) => s.codeUnits)]);

  static Arbitrary<dynamic> author() =>
      oneOf([string(), string().map((s) => s.codeUnits)]);

  static Arbitrary<String> isbn() => combine5(
        constantFrom(['978', '979']),
        integer(min: 0, max: 9999).map((v) => v.toString()),
        integer(min: 0, max: 9999).map((v) => v.toString()),
        integer(min: 0, max: 999).map((v) => v.toString()),
        frequency([
          (10, integer(min: 0, max: 9).map((v) => v.toString())),
          (1, constant('X')),
        ]),
        (a, b, c, d, e) => '$a-$b-$c-$d-$e',
      );
}

final class BookstoreBehavior extends Behavior<BookstoreState> {
  @override
  BookstoreState createState() {
    return BookstoreState();
  }

  @override
  List<Command<BookstoreState>> generateCommands(BookstoreState s) {
    return [
      Action3(
        'add book',
        Gen.title(),
        Gen.author(),
        Gen.isbn(),
        (s, title, author, isbn) {
          s.store.addBook(title, author, isbn);
        },
      ),
    ];
  }
}

final class BookstoreState extends State {
  final store = Bookstore();
}

final class Book {
  const Book(this.title, this.author, this.isbn);

  final dynamic title;
  final dynamic author;
  final String isbn;
}

final class Bookstore {
  final List<Book> books = [];

  void addBook(dynamic title, dynamic author, String isbn) {
    books.add(Book(title, author, isbn));
  }
}

void main() {
  property('basic', () {
    forAllStates(BookstoreBehavior(), (s) {});
  });
}
