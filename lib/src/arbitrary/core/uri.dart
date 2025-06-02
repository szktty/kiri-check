import 'package:kiri_check/src/arbitrary/top.dart';
import 'package:kiri_check/src/helpers/helpers_internal.dart';
import 'package:kiri_check/src/property/property_internal.dart';

/// A generator for [Uri] values with various URI schemes and components.
final class UriArbitrary extends ArbitraryBase<Uri> {
  UriArbitrary({
    this.schemes = const ['http', 'https'],
    this.allowFile = false,
    this.allowMailto = false,
    this.allowDataUri = false,
  });

  /// List of URI schemes to generate.
  final List<String> schemes;

  /// Whether to include file:// URIs.
  final bool allowFile;

  /// Whether to include mailto: URIs.
  final bool allowMailto;

  /// Whether to include data: URIs.
  final bool allowDataUri;

  @override
  bool get isExhaustive => false;

  @override
  int get enumerableCount => 0;

  @override
  List<Uri>? get edgeCases => null;

  // Character sets for URI components
  static final _unreserved = CharacterSet.fromCharacters(
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~',
  );

  static final _domainLabel = CharacterSet.fromCharacters(
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-',
  );

  static final _pathSegment = CharacterSet.fromCharacters(
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    r"0123456789-._~!$&'()*+,;=:@",
  );

  // Generate a valid domain label (RFC 1035)
  static Arbitrary<String> _domainLabelArb() {
    return combine3(
      string(
        minLength: 1,
        maxLength: 1,
        characterSet: CharacterSet.letter(CharacterEncoding.ascii),
      ),
      string(
        maxLength: 60,
        characterSet: _domainLabel,
      ),
      string(
        minLength: 0,
        maxLength: 1,
        characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
      ),
    ).map((parts) {
      final start = parts.$1;
      final middle = parts.$2;
      final end = parts.$3;

      // Remove trailing hyphens if they exist
      final cleanMiddle = middle.replaceAll(RegExp(r'-+$'), '');

      if (cleanMiddle.isEmpty && end.isEmpty) {
        return start;
      } else if (end.isEmpty) {
        return start + cleanMiddle;
      } else {
        return start + cleanMiddle + end;
      }
    });
  }

  // Generate a domain name
  static Arbitrary<String> _domainNameArb() {
    return combine2(
      list(_domainLabelArb(), minLength: 1, maxLength: 3),
      constantFrom(['com', 'org', 'net', 'io', 'dev', 'app', 'test']),
    ).map((parts) => '${parts.$1.join('.')}.${parts.$2}');
  }

  // Generate an IPv4 address
  static Arbitrary<String> _ipv4Arb() {
    return combine4(
      integer(min: 0, max: 255),
      integer(min: 0, max: 255),
      integer(min: 0, max: 255),
      integer(min: 0, max: 255),
    ).map((parts) => '${parts.$1}.${parts.$2}.${parts.$3}.${parts.$4}');
  }

  // Generate a host (domain or IP)
  static Arbitrary<String> _hostArb() {
    return frequency([
      (80, _domainNameArb()),
      (20, _ipv4Arb()),
    ]).cast<String>();
  }

  // Generate a port number
  static Arbitrary<int?> _portArb() {
    return frequency([
      (70, constant(null)),
      (10, constantFrom([80, 443, 8080, 8443, 3000])),
      (20, integer(min: 1024, max: 65535)),
    ]).cast<int?>();
  }

  // Generate a path segment
  static Arbitrary<String> _pathSegmentArb() {
    return string(
      minLength: 1,
      maxLength: 20,
      characterSet: _pathSegment,
    );
  }

  // Generate a path
  static Arbitrary<String> _pathArb() {
    return frequency([
      (30, constant('')),
      (
        70,
        list(_pathSegmentArb(), minLength: 1, maxLength: 4)
            .map((segments) => '/${segments.join('/')}')
      ),
    ]).cast<String>();
  }

  // Generate query parameters
  static Arbitrary<Map<String, String>> _queryParamsArb() {
    return frequency([
      (50, constant(<String, String>{})),
      (
        50,
        map(
          string(
            minLength: 1,
            maxLength: 10,
            characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
          ),
          string(maxLength: 20, characterSet: _unreserved),
          minLength: 1,
          maxLength: 5,
        )
      ),
    ]).cast<Map<String, String>>();
  }

  // Generate a fragment
  static Arbitrary<String?> _fragmentArb() {
    return frequency([
      (70, constant(null)),
      (30, string(minLength: 1, maxLength: 20, characterSet: _unreserved)),
    ]).cast<String?>();
  }

  @override
  Uri getFirst(RandomContext random) {
    // Use the first scheme from the allowed schemes
    final firstScheme = schemes.isNotEmpty ? schemes.first : 'http';

    if (firstScheme == 'file' || (allowFile && schemes.contains('file'))) {
      return Uri.file('/example/path');
    } else if (firstScheme == 'mailto' ||
        (allowMailto && schemes.contains('mailto'))) {
      return Uri.parse('mailto:user@example.com');
    } else if (firstScheme == 'data' ||
        (allowDataUri && schemes.contains('data'))) {
      return Uri.dataFromString('example', mimeType: 'text/plain');
    } else {
      return Uri.parse('$firstScheme://example.com');
    }
  }

  @override
  Uri generate(RandomContext random) {
    return _generateUri(random);
  }

  @override
  Uri generateRandom(RandomContext random) {
    return _generateUri(random);
  }

  Uri _generateUri(RandomContext random) {
    final allSchemes = <String>[...schemes];
    if (allowFile) allSchemes.add('file');
    if (allowMailto) allSchemes.add('mailto');
    if (allowDataUri) allSchemes.add('data');

    final schemeArb =
        constantFrom(allSchemes).cast<String>() as ArbitraryInternal<String>;
    final scheme = schemeArb.generate(random);

    // Handle special schemes
    if (scheme == 'mailto') {
      final userArb = string(
        minLength: 1,
        maxLength: 20,
        characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
      ) as ArbitraryInternal<String>;
      final user = userArb.generate(random);
      final domainArb = _domainNameArb() as ArbitraryInternal<String>;
      final domain = domainArb.generate(random);
      return Uri.parse('mailto:$user@$domain');
    }

    if (scheme == 'file') {
      final segmentsArb = list(_pathSegmentArb(), minLength: 1, maxLength: 5)
          as ArbitraryInternal<List<String>>;
      final segments = segmentsArb.generate(random);
      return Uri.file('/${segments.join('/')}');
    }

    if (scheme == 'data') {
      final mimeTypeArb = constantFrom([
        'text/plain',
        'image/png',
        'application/json',
      ]).cast<String>() as ArbitraryInternal<String>;
      final mimeType = mimeTypeArb.generate(random);
      final dataArb = string(
        minLength: 1,
        maxLength: 50,
        characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
      ) as ArbitraryInternal<String>;
      final data = dataArb.generate(random);
      return Uri.dataFromString(data, mimeType: mimeType);
    }

    // Standard HTTP(S) URIs
    final hostArb = _hostArb() as ArbitraryInternal<String>;
    final host = hostArb.generate(random);
    final portArb = _portArb() as ArbitraryInternal<int?>;
    final port = portArb.generate(random);
    final pathArb = _pathArb() as ArbitraryInternal<String>;
    final path = pathArb.generate(random);
    final queryParamsArb =
        _queryParamsArb() as ArbitraryInternal<Map<String, String>>;
    final queryParams = queryParamsArb.generate(random);
    final fragmentArb = _fragmentArb() as ArbitraryInternal<String?>;
    final fragment = fragmentArb.generate(random);

    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      queryParameters: queryParams.isEmpty ? null : queryParams,
      fragment: fragment,
    );
  }

  @override
  ShrinkingDistance calculateDistance(Uri value) {
    // Calculate distance based on URI complexity
    var distance = 0;

    // Add distance for each component
    if (value.hasPort && value.port != 80 && value.port != 443) distance += 10;
    if (value.hasQuery) distance += value.queryParameters.length * 5;
    if (value.hasFragment) distance += 5;
    if (value.path.isNotEmpty && value.path != '/') {
      distance += value.pathSegments.length * 5;
    }

    return ShrinkingDistance(distance);
  }

  @override
  List<Uri> shrink(Uri value, ShrinkingDistance distance) {
    final shrinks = <Uri>[];

    // Try simpler URIs first
    if (value.scheme == 'http' || value.scheme == 'https') {
      // Simplest form: just scheme and host
      shrinks.add(Uri(scheme: value.scheme, host: value.host));

      // Without fragment
      if (value.hasFragment) {
        shrinks.add(
          Uri(
            scheme: value.scheme,
            host: value.host,
            port: value.hasPort ? value.port : null,
            path: value.path,
            queryParameters: value.hasQuery ? value.queryParameters : null,
          ),
        );
      }

      // Without query
      if (value.hasQuery) {
        shrinks.add(
          Uri(
            scheme: value.scheme,
            host: value.host,
            port: value.hasPort ? value.port : null,
            path: value.path,
            fragment: value.hasFragment ? value.fragment : null,
          ),
        );
      }

      // Without port
      if (value.hasPort && value.port != 80 && value.port != 443) {
        shrinks.add(
          Uri(
            scheme: value.scheme,
            host: value.host,
            path: value.path,
            queryParameters: value.hasQuery ? value.queryParameters : null,
            fragment: value.hasFragment ? value.fragment : null,
          ),
        );
      }

      // Shorter path
      if (value.path.isNotEmpty && value.path != '/') {
        final segments = value.pathSegments;
        if (segments.isNotEmpty) {
          for (var i = segments.length - 1; i >= 0; i--) {
            final newPath =
                i == 0 ? '' : '/${segments.sublist(0, i).join('/')}';
            shrinks.add(
              Uri(
                scheme: value.scheme,
                host: value.host,
                port: value.hasPort ? value.port : null,
                path: newPath,
                queryParameters: value.hasQuery ? value.queryParameters : null,
                fragment: value.hasFragment ? value.fragment : null,
              ),
            );
          }
        }
      }

      // Fewer query parameters
      if (value.hasQuery && value.queryParameters.length > 1) {
        final keys = value.queryParameters.keys.toList();
        for (var i = 1; i < keys.length; i++) {
          final newParams = Map<String, String>.from(value.queryParameters)
            ..remove(keys[i]);
          shrinks.add(
            Uri(
              scheme: value.scheme,
              host: value.host,
              port: value.hasPort ? value.port : null,
              path: value.path,
              queryParameters: newParams,
              fragment: value.hasFragment ? value.fragment : null,
            ),
          );
        }
      }
    }

    return shrinks;
  }
}

/// Creates an arbitrary that generates [Uri] values.
///
/// By default, generates HTTP and HTTPS URIs with various components
/// (host, port, path, query parameters, and fragments).
///
/// Additional URI schemes can be enabled:
/// - [schemes]: List of URI schemes to use (default: ['http', 'https'])
/// - [allowFile]: Include file:// URIs
/// - [allowMailto]: Include mailto: URIs
/// - [allowDataUri]: Include data: URIs
///
/// Example:
/// ```dart
/// property('URIs are valid', () {
///   forAll(uri(), (u) {
///     expect(u.toString(), isNotEmpty);
///     expect(() => Uri.parse(u.toString()), returnsNormally);
///   });
/// });
///
/// property('HTTPS URIs use secure scheme', () {
///   forAll(uri(schemes: ['https']), (u) {
///     expect(u.scheme, equals('https'));
///     expect(u.isScheme('https'), isTrue);
///   });
/// });
/// ```
Arbitrary<Uri> uri({
  List<String> schemes = const ['http', 'https'],
  bool allowFile = false,
  bool allowMailto = false,
  bool allowDataUri = false,
}) {
  return UriArbitrary(
    schemes: schemes,
    allowFile: allowFile,
    allowMailto: allowMailto,
    allowDataUri: allowDataUri,
  );
}
