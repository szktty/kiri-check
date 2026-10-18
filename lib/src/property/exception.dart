class KiriCheckException implements Exception {
  KiriCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PropertyException implements Exception {
  PropertyException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class PropertyFailure extends PropertyException {
  PropertyFailure(super.message);
}

final class FalsifiedException<T> implements Exception {
  FalsifiedException({
    required this.example,
    this.description,
    this.originalExample,
    this.originalDescription,
    this.seed,
    this.exception,
    this.stackTrace,
  });

  final T example;
  final String? description;
  final T? originalExample;
  final String? originalDescription;
  final int? seed;
  final Exception? exception;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln(
        'Falsifying example: ${description ?? example}${seed != null ? ' (seed $seed)' : ''}',
      );

    final original = originalDescription ?? originalExample?.toString();
    if (original != null && original != (description ?? example.toString())) {
      buffer.writeln('Original example: $original');
    }

    if (exception != null) {
      buffer.writeln('Exception: $exception');
    }
    if (stackTrace != null) {
      buffer
        ..writeln('Stack trace:')
        ..writeln(stackTrace);
    }
    return buffer.toString();
  }
}
