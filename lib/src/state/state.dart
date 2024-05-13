import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

// ignore: one_member_abstracts
abstract class Behavior<T extends State> {
  @protected
  @factory
  T createState();

  @protected
  List<Command<T>> generateCommands(T state);
}

abstract class State {
  @protected
  void setUp() {}

  @protected
  void tearDown() {}
}

class Bundle<T> {
  Bundle(this.description);

  final String description;

  T get value {
    if (_value != null) {
      return _value!;
    }
    // TODO: エラー内容
    throw PropertyException('The value is not set.');
  }

  T? _value;

  set value(T value) {
    _value = value;
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
  Bundle<T> get consumer => BundleConsumer(this);
}

final class BundleConsumer<T> extends Bundle<T> {
  BundleConsumer(this.bundle) : super(bundle.description);

  final Bundle<T> bundle;

  @override
  T get value => bundle.value;

  @override
  Bundle<T> copy() => BundleConsumer(bundle.copy());
}
