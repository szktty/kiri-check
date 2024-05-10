import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';

abstract class StateContext<S extends State> {
  S get state;

  T draw<T>(Arbitrary<T> arbitrary);
}

final class StateContextImpl<S extends State> extends StateContext<S> {
  StateContextImpl(this.property, this.test);

  final StatefulProperty<S> property;
  final PropertyTest test;

  @override
  S get state => property.state;

  @override
  T draw<T>(Arbitrary<T> arbitrary) {
    final base = arbitrary as ArbitraryBase<T>;
    return base.generate(property.random);
  }
}

final class StatefulProperty<S extends State> extends Property<S> {
  StatefulProperty(
    this.state, {
    required super.settings,
    super.setUp,
    super.tearDown,
  }) {
    maxCycles = settings.maxStatefulCycles ?? KiriCheck.maxStatefulCycles;
    /*
    maxShrinkingCycles =
        settings.maxShrinkingCycles ?? KiriCheck.maxShrinkingCycles;

     */
    maxShrinkingCycles = 50;
  }

  final S state;

  late final int maxCycles;
  late final int maxShrinkingCycles;

  @override
  void check(PropertyTest test) {
    // TODO: implement check
    print('Check state: ${state.runtimeType}');

    final initializers = state.initializeCommands;
    final commandPool = state.commandPool;

    print('Analyze commandPool...');
    // TODO: バンドルの依存関係

    print('Set up...');
    (setUp ?? state.setUp).call();

    print('Initialize state...');
    print('--------------------------------------------');
    final context = StateContextImpl(this, test);
    for (var i = 0; i < initializers.length; i++) {
      final command = initializers[i];
      print('Step #${i + 1}: ${command.description}');
      try {
        command.run(context);
      } catch (e) {
        throw PropertyException(
            'Initialization failed: Step #${i + 1}: ${command.description}: $e');
      }
    }

    print('--------------------------------------------');
    print('Run command sequence...');
    final traversal = Traversal(context, commandPool);
    try {
      while (traversal.hasNextPath) {
        traversal.nextPath();
        print('--------------------------------------------');
        print('Cycle #${traversal.currentCycle + 1}');
        while (traversal.hasNextStep) {
          final command = traversal.nextStep();
          print('Step #${traversal.currentStep + 1}: ${command.description}');
          command.precondition?.call();
          command.run(context);
          command.postcondition?.call();
        }
      }
      print('--------------------------------------------');
    } catch (e) {
      // TODO: shrink
      print('Error: $e');
      _shrink(traversal);
      print('--------------------------------------------');
    }

    print('Tear down...');
    (tearDown ?? state.tearDown).call();
  }

  // 1. パスを短縮する
  // 2. バンドルの値を短縮する
  void _shrink(Traversal traversal) {
    // TODO
    for (var cycle = 0; cycle < maxShrinkingCycles; cycle++) {
      print('--------------------------------------------');
      print('Shrinking cycle #${cycle + 1}');
      for (var path in traversal.paths) {
        final granularity = cycle + 1;
        final paths = path.shrink(granularity);
        // TODO
      }
    }
  }
}
