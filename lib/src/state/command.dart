import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

abstract class Command<T extends State> {
  Command(
    this.description, {
    bool Function(T)? precondition,
    bool Function(T)? postcondition,
    T Function(T)? nextState,
  }) {
    _precondition = precondition;
    _postcondition = postcondition;
    _nextState = nextState;
  }

  final String description;

  late final bool Function(T)? _precondition;
  late final bool Function(T)? _postcondition;
  late final T Function(T)? _nextState;

  List<Command<T>> get subcommands => const [];

  bool requires(T state) {
    return _precondition?.call(state) ?? true;
  }

  bool ensures(T state) {
    return _postcondition?.call(state) ?? true;
  }

  T? nextState(T state) {
    return _nextState?.call(state);
  }

  void execute(T state);
}
