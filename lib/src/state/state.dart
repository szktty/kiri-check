import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:meta/meta.dart';

abstract class State {
  List<Command> build();

  List<Command> initialize() => [];

  void setUp() {}

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
    // TODO: ログを取る？
    _value = value;
  }

  // ignore: use_to_and_as_if_applicable
  Bundle<T> consumer() => BundleConsumer(this);
}

final class BundleConsumer<T> extends Bundle<T> {
  BundleConsumer(this.bundle) : super(bundle.description);

  final Bundle<T> bundle;

  T get value => bundle.value;
}
