import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

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
    // TODO: 初回は getFirst を使うべき？
    // TODO: シュリンクのために記録する
    final base = arbitrary as ArbitraryBase<T>;
    return base.generate(property.random);
  }
}

final class StatefulProperty<S extends State> extends Property<S> {
  StatefulProperty(this.state, {required super.settings});

  final S state;

  @override
  void check(PropertyTest test) {
    // TODO: implement check
    print('Check state: ${state.runtimeType}');

    final initializers = state.initialize();
    final commands = state.build();
    print('Initialize commands: ${initializers.length}');
    print('Build commands: ${commands.length}');

    print('Analyze commands...');
    // TODO: バンドルの依存関係

    print('Set up...');
    state.setUp();

    print('Initialize state...');
    final context = StateContextImpl(this, test);
    for (var i = 0; i < initializers.length; i++) {
      final command = initializers[i];
      // TODO: step でいいのか？
      print('Step #$i: ${command.description}');
      command.run(context);
    }

    print('Run commands...');
    final traversal = Traversal(context, commands);
    while (traversal.hasNextPath) {
      traversal.nextPath();
      print('--------------------------------------------');
      print('Cycle #${traversal.currentCycle}');
      while (traversal.hasNextStep) {
        final command = traversal.nextStep();
        print('Step #${traversal.currentStep}: ${command.description}');
        // TODO: preconditionを評価する
        command.run(context);

        // TODO: postconditionを評価する
      }
    }
    print('--------------------------------------------');

    // TODO: シュリンク

    print('Tear down...');
    state.tearDown();
  }
}
