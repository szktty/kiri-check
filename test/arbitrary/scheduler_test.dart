import 'dart:async';

import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary/combinator/scheduler.dart';
import 'package:test/test.dart';

// Increments the counter over two awaits. Dart itself runs the
// continuations of two increments one after another, so no increment
// is lost unless the second one runs entirely between the read and
// the write of the first one.
final class Counter {
  int value = 0;

  Future<void> incrementOnce() async {
    final current = value;
    await Future<void>.value();
    value = current + 1;
  }

  Future<void> incrementTwice() async {
    await Future<void>.value();
    await Future<void>.value();
    value++;
  }
}

Future<int> runCounter(Scheduler s) async {
  final counter = Counter();
  await s.run(
    () => Future.wait([counter.incrementOnce(), counter.incrementTwice()]),
  );
  return counter.value;
}

void main() {
  group('run', () {
    test('returns the result of the body', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      expect(await s.run(() async => 42), 42);
      expect(await s.run(() => 'sync'), 'sync');
    });

    test('runs in the order Dart uses without choices', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      expect(await runCounter(s), 2);
      expect(s.trace, everyElement(0));
    });

    test('runs in the order of the choices', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const [1, 1]);
      expect(await runCounter(s), 1);
      expect(s.trace.take(2), [1, 1]);
    });

    test('follows the same schedule in each run', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const [], seed: 123);
      final first = await runCounter(s);
      final trace = s.trace;
      expect(await runCounter(s), first);
      expect(s.trace, trace);
    });

    test('rethrows an error of the body', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      await expectLater(
        s.run(() async {
          await Future<void>.value();
          throw StateError('body');
        }),
        throwsStateError,
      );
    });

    test('throws an error not handled by the body', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      await expectLater(
        s.run(() {
          scheduleMicrotask(() => throw StateError('microtask'));
        }),
        throwsStateError,
      );
    });

    test('runs the microtasks left by the body', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      var ran = false;
      await s.run(() {
        scheduleMicrotask(() => ran = true);
      });
      expect(ran, isTrue);
    });

    test('fails when the steps exceed the maximum', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      await expectLater(
        s.run(() async {
          for (;;) {
            await Future<void>.value();
          }
        }),
        throwsStateError,
      );
    });

    test('cannot run nested', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      await expectLater(
        s.run(() => s.run(() {})),
        throwsStateError,
      );
    });

    test('waits for futures completed outside of the zone', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      final completer = Completer<int>();
      Timer(const Duration(milliseconds: 10), () => completer.complete(1));
      expect(await s.run(() => completer.future), 1);
    });
  });

  group('timer', () {
    test('runs on virtual time', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      final watch = Stopwatch()..start();
      await s.run(() => Future<void>.delayed(const Duration(hours: 1)));
      expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
      expect(s.elapsed, const Duration(hours: 1));
    });

    test('runs in the order of the due time', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      final order = <int>[];
      await s.run(
        () => Future.wait([
          Future<void>.delayed(
            const Duration(seconds: 2),
            () => order.add(2),
          ),
          Future<void>.delayed(
            const Duration(seconds: 1),
            () => order.add(1),
          ),
          Future<void>(() => order.add(0)),
        ]),
      );
      expect(order, [0, 1, 2]);
    });

    test('runs periodically until cancelled', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      final ticks = <int>[];
      await s.run(() {
        final completer = Completer<void>();
        Timer.periodic(const Duration(seconds: 1), (timer) {
          ticks.add(timer.tick);
          if (timer.tick == 3) {
            timer.cancel();
            completer.complete();
          }
        });
        return completer.future;
      });
      expect(ticks, [1, 2, 3]);
      expect(s.elapsed, const Duration(seconds: 3));
    });

    test('cancels the timers left by the body', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      late Timer timer;
      await s.run(() {
        timer = Timer(const Duration(seconds: 1), () {});
      });
      expect(timer.isActive, isFalse);
    });
  });

  group('shrink', () {
    test('has nothing to shrink before running', () {
      final arbitrary = SchedulerArbitrary(maxSteps: 100);
      final s = SchedulerImpl(maxSteps: 100, choices: const [0, 3, 0, 2]);
      // Not run yet, the scheduler has no trace to shrink.
      expect(arbitrary.calculateDistance(s).isEmpty, isTrue);
      expect(arbitrary.shrink(s, arbitrary.calculateDistance(s)), isEmpty);
    });

    test('shrinks the choices of the last run', () async {
      final arbitrary = SchedulerArbitrary(maxSteps: 100);
      final s = SchedulerImpl(maxSteps: 100, choices: const [1, 1]);
      await runCounter(s);
      final distance = arbitrary.calculateDistance(s);
      expect(distance.isEmpty, isFalse);
      final shrunk = arbitrary
          .shrink(s, distance)
          .cast<SchedulerImpl>()
          .map((e) => e.choices)
          .toList();
      expect(
        shrunk,
        containsAll(<List<int>>[
          [],
          [1],
          [0, 1],
        ]),
      );
      expect(shrunk, isNot(contains([1, 1])));
    });
  });

  group('describe', () {
    test(
      'shows where the reordered microtasks wait',
      () async {
        final s = SchedulerImpl(maxSteps: 100, choices: const [1, 1]);
        await runCounter(s);
        final description = s.toString();
        expect(description, startsWith('Scheduler(choices: [1, 1], steps: '));
        expect(description, contains('step 1: ran microtask waiting at'));
        expect(description, contains('Counter.incrementTwice'));
        expect(description, contains('before microtask waiting at'));
        expect(description, contains('Counter.incrementOnce'));
      },
      testOn: 'vm',
    );

    test('shows the reordered microtasks', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const [1, 1]);
      await runCounter(s);
      expect(s.toString(), contains('step 1: ran microtask'));
    });

    test('shows nothing reordered in the order Dart uses', () async {
      final s = SchedulerImpl(maxSteps: 100, choices: const []);
      await runCounter(s);
      expect(s.toString(), isNot(contains('ran')));
    });
  });

  group('schedule', () {
    Future<List<int>> runScheduled(Scheduler s) async {
      final order = <int>[];
      await s.run(
        () => Future.wait([
          s.schedule(Future.value(1), label: 'one').then(order.add),
          s.schedule(Future.value(2), label: 'two').then(order.add),
          s.schedule(Future.value(3), label: 'three').then(order.add),
        ]),
      );
      return order;
    }

    test('completes in the order of scheduling without choices', () async {
      final s = Scheduler.withChoices(const [], microtasks: false);
      expect(await runScheduled(s), [1, 2, 3]);
    });

    test('completes in the order of the choices', () async {
      final s = Scheduler.withChoices(const [2, 1], microtasks: false);
      expect(await runScheduled(s), [3, 2, 1]);
      expect(s.toString(), contains("ran scheduled 'three'"));
      expect(s.toString(), contains("before scheduled 'one'"));
    });

    test('does not reorder microtasks if disabled', () async {
      final s = SchedulerImpl(
        maxSteps: 100,
        microtasks: false,
        choices: const [],
        seed: 123,
      );
      expect(await runCounter(s), 2);
      expect(s.trace, isEmpty);
    });

    test('waits for the scheduled future to complete', () async {
      final s = Scheduler.withChoices(const [], microtasks: false);
      final order = <int>[];
      await s.run(
        () => Future.wait([
          s
              .schedule(
                Future<int>.delayed(const Duration(seconds: 1), () => 1),
              )
              .then(order.add),
          s.schedule(Future.value(2)).then(order.add),
        ]),
      );
      expect(order, [1, 2]);
    });

    test('completes with the error of the future', () async {
      final s = Scheduler.withChoices(const []);
      await expectLater(
        s.run(() => s.schedule(Future<int>.error(StateError('error')))),
        throwsStateError,
      );
    });

    test('cannot be called outside of run', () {
      final s = Scheduler.withChoices(const []);
      expect(() => s.schedule(Future.value(1)), throwsStateError);
    });
  });

  group('withChoices', () {
    test('rejects negative choices', () {
      expect(() => Scheduler.withChoices(const [-1]), throwsRangeError);
    });

    test('rejects non-positive max steps', () {
      expect(
        () => Scheduler.withChoices(const [], maxSteps: 0),
        throwsArgumentError,
      );
    });
  });

  group('property', () {
    property('finds a race of scheduled futures', () {
      SchedulerImpl? falsified;
      forAll(
        scheduler(microtasks: false),
        (s) async {
          // Saves the latest value, but a stale response may overwrite it.
          var saved = 0;
          Future<void> save(int value) async {
            final response = await s.schedule(Future.value(value));
            saved = response;
          }

          await s.run(() => Future.wait([save(1), save(2)]));
          expect(saved, 2);
        },
        onFalsify: (s) => falsified = s as SchedulerImpl,
        ignoreFalsify: true,
        tearDownAll: () {
          expect(falsified, isNotNull);
          expect(falsified!.trace, [1]);
        },
      );
    });

    property('finds a lost increment and shrinks the schedule', () {
      SchedulerImpl? falsified;
      forAll(
        scheduler(),
        (s) async {
          expect(await runCounter(s), 2);
        },
        onFalsify: (s) => falsified = s as SchedulerImpl,
        ignoreFalsify: true,
        tearDownAll: () {
          expect(falsified, isNotNull);
          expect(falsified!.trace.take(2), [1, 1]);
          expect(falsified!.trace.skip(2), everyElement(0));
        },
      );
    });

    property('passes when the code is correct', () {
      forAll(scheduler(), (s) async {
        final counter = Counter();
        await s.run(
          () =>
              Future.wait([counter.incrementTwice(), counter.incrementTwice()]),
        );
        expect(counter.value, 2);
      });
    });

    property('shrinks with other arbitraries', () {
      (int, SchedulerImpl)? falsified;
      forAll(
        combine2(integer(min: 0, max: 100), scheduler()),
        (pair) async {
          final (n, s) = pair;
          final counter = Counter();
          await s.run(
            () => Future.wait([
              counter.incrementOnce(),
              counter.incrementTwice(),
            ]),
          );
          expect(counter.value == 2 || n < 10, isTrue);
        },
        onFalsify: (pair) => falsified = (pair.$1, pair.$2 as SchedulerImpl),
        ignoreFalsify: true,
        tearDownAll: () {
          expect(falsified, isNotNull);
          expect(falsified!.$1, 10);
        },
      );
    });

    property('reproduces with the same seed', () {
      final traces = <List<List<int>>>[[], []];
      for (final i in [0, 1]) {
        forAll(
          scheduler(),
          (s) async {
            await runCounter(s);
            traces[i].add((s as SchedulerImpl).trace);
          },
          seed: 42,
          maxExamples: 20,
          tearDownAll: () {
            if (i == 1) {
              expect(traces[1], traces[0]);
            }
          },
        );
      }
    });
  });
}
