import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

Object fizzbuzzGood(int n) {
  if (n % 3 == 0 && n % 5 == 0) {
    return 'FizzBuzz';
  } else if (n % 3 == 0) {
    return 'Fizz';
  } else if (n % 5 == 0) {
    return 'Buzz';
  } else {
    return n;
  }
}

Object fizzbuzzBad(int n) {
  if (n % 3 == 0) {
    return 'Fizz';
  } else if (n % 5 == 0) {
    return 'Buzz';
  } else if (n % 3 == 0 && n % 5 == 0) {
    return 'FizzBuzz';
  } else {
    return n;
  }
}

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  property('FizzBuzz (good)', () {
    forAll(
      integer(min: 0, max: 100),
      (n) {
        final result = fizzbuzzGood(n);
        if (n % 15 == 0) {
          expect(result, 'FizzBuzz');
        } else if (n % 3 == 0) {
          expect(result, 'Fizz');
        } else if (n % 5 == 0) {
          expect(result, 'Buzz');
        } else {
          expect(result, n);
        }
      },
    );
  });

  property('FizzBuzz (bad)', () {
    forAll(
      integer(min: 1, max: 100),
      (n) {
        final result = fizzbuzzBad(n);
        if (n % 15 == 0) {
          expect(result, 'FizzBuzz');
        } else if (n % 3 == 0) {
          expect(result, 'Fizz');
        } else if (n % 5 == 0) {
          expect(result, 'Buzz');
        } else {
          expect(result, n);
        }
      },
    );
  });
}
