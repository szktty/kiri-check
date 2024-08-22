import 'dart:async';

Future<T> asyncCallOr<T>(FutureOr<T>? Function() f, T value) async {
  final result = await f();
  return result ?? value;
}
