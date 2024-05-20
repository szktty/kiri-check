import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/command/action.dart';
import 'package:kiri_check/stateful_test.dart';

abstract class Gen {
  static final title = oneOf([string(), string().map((s) => s.codeUnits)]);
  static final author = oneOf([string(), string().map((s) => s.codeUnits)]);
// TODO: isbn
}

final class BookstoreBehavior extends Behavior<BookstoreState> {
  @override
  BookstoreState createState() {
    return BookstoreState();
  }

  @override
  List<Command<BookstoreState>> generateCommands(BookstoreState s) {
    return [
      /*
      Generate(
          'add book',
          combine2(
            Gen.title,
            Gen.author,
            (title, author) => (title, author),
          ), (s, args) {
        s.store.addBook(args.$1, args.$2);
      }),
       */
      Action2('add book', Gen.title, Gen.author, (s, title, author) {
        s.store.addBook(title, author);
      }),
    ];
  }
}

final class BookstoreState extends State {
  final store = Bookstore();
}

final class Book {
  const Book(this.title, this.author);

  final dynamic title;
  final dynamic author;
}

final class Bookstore {
  final List<Book> books = [];

  void addBook(dynamic title, dynamic author) {
    books.add(Book(title, author));
  }
}
