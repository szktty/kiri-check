import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

final class StatisticsEntry {
  StatisticsEntry(this.values);

  final List<Object> values;
}

final class Statistics {
  Statistics._();

  static final Statistics _instance = Statistics._();

  final List<StatisticsEntry> _entries = [];

  static void initialize() {
    _instance._entries.clear();
  }

  static StatisticsResult getResult() {
    return StatisticsResult(_instance._entries);
  }

  static void collect(List<Object> values) {
    _instance._entries.add(StatisticsEntry(values));
  }
}

final class StatisticsMetricsEntry {
  StatisticsMetricsEntry({
    required this.values,
    required this.count,
    required this.ratio,
  });

  final List<Object> values;
  final int count;
  final double ratio;
}

final class StatisticsResult {
  @protected
  StatisticsResult(this._entries) {
    _valueMap = EqualityMap(const ListEquality());
    for (final entry in entries) {
      _valueMap[entry.values] = (_valueMap[entry.values] ?? 0) + 1;
    }
  }

  List<StatisticsEntry> get entries => List.of(_entries);
  final List<StatisticsEntry> _entries;

  late final Map<List<Object>, int> _valueMap;

  List<StatisticsMetricsEntry> getMetrics() {
    final baseEntries = _valueMap.entries
        .toList()
        .sorted((a, b) => a.value.compareTo(b.value))
        .map((e) => (e.value, e.key))
        .toList()
        .reversed
        .toList();
    return baseEntries
        .map((e) => StatisticsMetricsEntry(
              values: e.$2,
              count: e.$1,
              ratio: e.$1 / baseEntries.length,
            ),)
        .toList();
  }
}
