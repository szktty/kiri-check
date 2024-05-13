import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

// ignore: one_member_abstracts
abstract class Behavior {
  @protected
  @factory
  State<Behavior> createState();

  State<Behavior> _createState() => createState().._behavior = this;
}

abstract class State<T extends Behavior> {
  T get behavior => _behavior!;

  late T? _behavior;

  @protected
  List<Command> get commandPool;

  @protected
  List<Command> get initializeCommands;

  @protected
  void setUp() {}

  @protected
  void tearDown() {}
}

class Bundle<T> {
  Bundle(this.description);

  final String description;

  var _restoreMode = false;

  var _history = <T>[];
  var _step = 0;

  T get value {
    if (!_restoreMode) {
      if (_value != null) {
        return _value!;
      }
      // TODO: エラー内容
      throw PropertyException('The value is not set.');
    } else {
      return _history[_step++]!;
    }
  }

  T? _value;

  set value(T value) {
    if (!_restoreMode) {
      _value = value;
      _history.add(value);
    }
  }

  Bundle<T> copy() {
    final bundle = Bundle<T>(description);
    bundle._value = _copyValue(_value!) as T;
    return bundle;
  }

  dynamic _copyValue(dynamic value) {
    if (value is List<dynamic>) {
      return value.map(_copyValue).toList() as T;
    } else if (value is Map) {
      return value.map((key, value) => MapEntry(key, _copyValue(value))) as T;
    } else if (value is tz.TZDateTime) {
      return value.copyWith();
    } else if (value is DateTime) {
      return DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);
    } else {
      return value;
    }
  }

  // ignore: use_to_and_as_if_applicable
  Bundle<T> consumer() => BundleConsumer(this);

  @internal
  void beginRestore() {
    _restoreMode = true;
    _step = 0;
  }
}

extension BundlePrivate<T> on Bundle<T> {
  void restore() {
    _restoreMode = true;
    _step = 0;
  }
}

final class BundleConsumer<T> extends Bundle<T> {
  BundleConsumer(this.bundle) : super(bundle.description);

  final Bundle<T> bundle;

  @override
  T get value => bundle.value;

  @override
  Bundle<T> copy() => BundleConsumer(bundle.copy());
}
