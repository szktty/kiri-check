class PropertyException implements Exception {
  PropertyException(this.message);

  final String message;

  @override
  String toString() => 'PropertyException: $message';
}

final class PropertyFailure extends PropertyException {
  PropertyFailure(super.message);
}

final class FalsifiedException<T> implements Exception {
  FalsifiedException({
    required this.example,
    this.description,
    this.seed,
  });

  final T example;
  final String? description;
  final int? seed;

  @override
  String toString() =>
      'Falsifying example: ${description ?? example}${seed != null ? ' (seed $seed)' : ''}';
}
