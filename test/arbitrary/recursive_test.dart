import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

abstract class Tree {}

final class Leaf extends Tree {
  Leaf(this.value);

  final int value;

  @override
  String toString() => 'Leaf($value)';
}

final class Node extends Tree {
  Node(this.children);

  final List<Tree> children;

  @override
  String toString() => 'Node($children)';
}

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  group('generation', () {
    property('dynamic', () {
      testForAll(
        recursive<dynamic>(integer, (f) => () => list(f())),
        (value) {
          expect(value, anyOf(isEmpty, isA<int>(), isA<List<dynamic>>()));
        },
      );
    });

    property('tree', () {
      testForAll(
        recursive<Tree>(
          () => integer().map(Leaf.new),
          (f) => () => list(f()).map(Node.new),
        ),
        (value) {
          expect(value, anyOf(isA<Leaf>(), isA<Node>()));
        },
      );
    });
  });

  group('shrink', () {
    property('range', () {
      testForAll(
        recursive<dynamic>(
          () => integer(min: 0, max: 10000),
          (f) => () => list(f()),
        ),
        (value) {
          if (value is! int) {
            return;
          }
          expect(value, lessThanOrEqualTo(100));
        },
        onFalsify: (value) {
          expect(value, isA<int>());
          expect(value, lessThanOrEqualTo(200));
        },
        ignoreFalsify: true,
      );
    });

    property('depth', () {
      testForAll(
        recursive<dynamic>(
          () => integer(min: 0, max: 10000),
          (f) => () => list(f()),
          maxDepth: 5,
        ),
        (value) {
          if (value is int) {
            return;
          } else if (value is List<dynamic> && value.isEmpty) {
            return;
          }
          expect(listDepth(value), lessThanOrEqualTo(2));
        },
        onFalsify: (value) {
          expect(listDepth(value), lessThanOrEqualTo(3));
        },
        ignoreFalsify: true,
      );
    });
  });
}

int listDepth(dynamic base) {
  var value = base;
  var depth = 0;
  while (value is List<dynamic> && value.isNotEmpty) {
    value = value.first;
    depth++;
  }
  return depth;
}
