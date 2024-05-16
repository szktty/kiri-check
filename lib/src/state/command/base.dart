import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

abstract class Command<T extends State> {
  Command(
    this.description, {
    List<Command<T>>? dependencies,
    bool Function(T)? canExecute,
    bool Function(T)? precondition,
    bool Function(T)? postcondition,
    T Function(T)? nextState,
  }) {
    _dependencies = dependencies ?? [];
    _canExecute = canExecute;
    _precondition = precondition;
    _postcondition = postcondition;
    _nextState = nextState;
  }

  final String description;

  late final List<Command<T>> _dependencies;

  late final bool Function(T)? _canExecute;
  late final bool Function(T)? _precondition;
  late final bool Function(T)? _postcondition;
  late final T Function(T)? _nextState;

  List<Command<T>> get subcommands => const [];

  bool canExecute(T state) {
    return _canExecute?.call(state) ?? true;
  }

  bool requires(T state) {
    return _precondition?.call(state) ?? true;
  }

  bool ensures(T state) {
    return _postcondition?.call(state) ?? true;
  }

  T nextState(T state) {
    return _nextState?.call(state) ?? state;
  }

  void execute(T state);

  List<Command<T>> get dependencies => List.unmodifiable(_dependencies);

  void addDependency(Command<T> command) {
    _dependencies.add(command);
  }

  void removeDependency(Command<T> command) {
    _dependencies.remove(command);
  }
}

final class Generate<T extends State, U> extends Command<T> {
  Generate(
    super.description,
    this.arbitrary,
    this.action, {
    super.dependencies,
    super.canExecute,
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final Arbitrary<U> arbitrary;
  final void Function(T, U) action;

  @override
  void execute(T state) {
    final base = arbitrary as ArbitraryBase<U>;
    final value = base.generate(state.random);
    action(state, value);
  }
}

final class Action<T extends State> extends Command<T> {
  Action(
    super.description,
    this.action, {
    super.dependencies,
    super.canExecute,
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final void Function(T) action;

  @override
  void execute(T state) {
    action(state);
  }
}
