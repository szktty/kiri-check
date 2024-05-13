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

    // TODO: 毎回状態の初期化が必要
    // TODO: エラー時のバンドルの状態を保存しておき、再利用したい
    // 乱数の状態を再現できないものか
    // バンドル側で、ステップと値を結びつけて保持しておけばいいのでは
    print('--------------------------------------------');
    print('Run command sequence...');
    final traversal = Traversal(context, commandPool);
    TraversalPath? shrunkPath;
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
      shrunkPath = _shrinkPath(traversal);

      print('--------------------------------------------');
    }

    print('Tear down...');
    (tearDown ?? state.tearDown).call();

    // TODO: return shrunkPath
  }

  // 1. パスを短縮する
  // 2. バンドルの値を短縮する
  TraversalPath _shrinkPath(Traversal traversal) {
    // TODO
    final start = traversal.currentPath!;
    var granularity = 1;
    var cycle = 0;
    var failed = start;
    while (cycle < maxShrinkingCycles) {
      print('--------------------------------------------');
      final paths = start.shrink(granularity);
      for (final path in paths) {
        print('Shrink cycle ${cycle + 1}');
        for (var i = 0; i < path.steps.length; i++) {
          // TODO: 最後にエラーになったパスの短縮の繰り返し
          final step = path.steps[i];
          final command = step.command;
          print('Shrink step ${i + 1}: ${command.description}');
          try {
            command.precondition?.call();
            command.run(traversal.context);
            command.postcondition?.call();
          } catch (e) {
            print('Error: $e');
            failed = path;
            continue;
          }
          // passのシュリンク終了
          _shrinkBundles(path);
          return failed;
        }
        cycle++;
      }
    }
    return failed;
  }

  void _shrinkBundles(TraversalPath path) {
    // TODO
    print('Shrink bundles...');
  }
}
