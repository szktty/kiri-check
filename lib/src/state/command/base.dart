import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

typedef PreconditionF = void Function();
typedef PostconditionF = void Function();

abstract class Command<S extends State> {
  Command(
    this.description, {
    this.precondition,
    this.postcondition,
  });

  final String description;
  final PreconditionF? precondition;
  final PostconditionF? postcondition;

  void run(StateContext<S> context);
}

final class Update<T> extends Command {
  // TODO: precondition, postcondition
  Update(
    super.description,
    this.bundle,
    this.arbitrary, {
    super.precondition,
    super.postcondition,
  });

  final Bundle<T> bundle;
  final Arbitrary<T> arbitrary;

  @override
  void run(StateContext context) {
    final value = context.draw(arbitrary);
    bundle.value = value;
  }
}

final class Action extends Command {
  Action(
    super.description,
    this.action, {
    this.bundles = const [],
    super.precondition,
    super.postcondition,
  });

  // TODO: require などにすべきかも
  final List<Bundle<dynamic>> bundles;
  final void Function() action;

  @override
  void run(StateContext context) {
    action();
  }
}
