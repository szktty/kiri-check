import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('uri', () {
    property('generates valid URIs', () {
      forAll(uri(), (u) {
        expect(u.toString(), isNotEmpty);
        expect(() => Uri.parse(u.toString()), returnsNormally);
      });
    });

    property('generates HTTP and HTTPS URIs by default', () {
      forAll(uri(), (u) {
        expect(['http', 'https'], contains(u.scheme));
      });
    });

    property('respects custom schemes', () {
      forAll(uri(schemes: ['ftp', 'sftp']), (u) {
        expect(['ftp', 'sftp'], contains(u.scheme));
      });
    });

    property('generates HTTPS URIs only when specified', () {
      forAll(uri(schemes: ['https']), (u) {
        expect(u.scheme, equals('https'));
        expect(u.isScheme('https'), isTrue);
      });
    });

    property('generates file URIs when enabled', () {
      forAll(uri(allowFile: true), (u) {
        // Should generate some file URIs among others
        if (u.scheme == 'file') {
          expect(u.path, isNotEmpty);
          expect(u.host, isEmpty);
        }
      });
    });

    property('generates mailto URIs when enabled', () {
      forAll(uri(allowMailto: true), (u) {
        if (u.scheme == 'mailto') {
          expect(u.path, isNotEmpty);
          expect(u.path, contains('@'));
        }
      });
    });

    property('generates data URIs when enabled', () {
      forAll(uri(allowDataUri: true), (u) {
        if (u.scheme == 'data') {
          expect(u.data, isNotNull);
        }
      });
    });

    property('URIs have valid hosts', () {
      forAll(uri(), (u) {
        if (u.hasAuthority && u.host.isNotEmpty) {
          // Should be either domain name or IP address
          final isDomain = RegExp(
                  r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$')
              .hasMatch(u.host);
          final isIPv4 = RegExp(
                  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')
              .hasMatch(u.host);

          expect(isDomain || isIPv4, isTrue,
              reason: 'Host should be domain or IPv4: ${u.host}');
        }
      });
    });

    property('URIs with ports have valid port numbers', () {
      forAll(uri(), (u) {
        if (u.hasPort) {
          expect(u.port, greaterThan(0));
          expect(u.port, lessThanOrEqualTo(65535));
        }
      });
    });

    property('URIs can have query parameters', () {
      forAll(uri(), (u) {
        if (u.hasQuery) {
          expect(u.queryParameters, isNotEmpty);
          for (final key in u.queryParameters.keys) {
            expect(key, isNotEmpty);
          }
        }
      });
    });

    property('URIs can have fragments', () {
      forAll(uri(), (u) {
        if (u.hasFragment) {
          expect(u.fragment, isNotEmpty);
        }
      });
    });

    property('generated URIs are parseable and equivalent', () {
      forAll(uri(), (original) {
        final uriString = original.toString();
        final parsed = Uri.parse(uriString);

        expect(parsed.scheme, equals(original.scheme));
        if (original.hasAuthority) {
          expect(parsed.host, equals(original.host));
          if (original.hasPort) {
            expect(parsed.port, equals(original.port));
          }
        }
        expect(parsed.path, equals(original.path));
        if (original.hasQuery) {
          expect(parsed.queryParameters, equals(original.queryParameters));
        }
        if (original.hasFragment) {
          expect(parsed.fragment, equals(original.fragment));
        }
      });
    });

    test('shrinks to simpler URIs', () {
      final arb = uri();
      final complexUri = Uri(
        scheme: 'https',
        host: 'example.com',
        port: 8080,
        path: '/api/v1/users',
        queryParameters: {'page': '1', 'limit': '10'},
        fragment: 'section1',
      );

      final shrinks = getShrinks(arb, complexUri);
      expect(shrinks, isNotEmpty);

      // Should include simpler version
      final hasSimpler = shrinks.any(
        (uri) =>
            uri.scheme == complexUri.scheme &&
            uri.host == complexUri.host &&
            !uri.hasPort &&
            uri.path.isEmpty &&
            !uri.hasQuery &&
            !uri.hasFragment,
      );
      expect(hasSimpler, isTrue);
    });

    test('shrinks remove components progressively', () {
      final arb = uri();
      final complexUri = Uri(
        scheme: 'https',
        host: 'example.com',
        path: '/a/b/c',
        queryParameters: {'x': '1', 'y': '2'},
        fragment: 'top',
      );

      final shrinks = getShrinks(arb, complexUri);

      // Should have version without fragment
      final withoutFragment = shrinks.any(
        (uri) =>
            uri.scheme == complexUri.scheme &&
            uri.host == complexUri.host &&
            uri.path == complexUri.path &&
            uri.hasQuery &&
            !uri.hasFragment,
      );
      expect(withoutFragment, isTrue);

      // Should have version without query
      final withoutQuery = shrinks.any(
        (uri) =>
            uri.scheme == complexUri.scheme &&
            uri.host == complexUri.host &&
            uri.path == complexUri.path &&
            !uri.hasQuery,
      );
      expect(withoutQuery, isTrue);
    });

    property('can be used with other combinators', () {
      forAll(
        frequency([
          (80, uri(schemes: ['https'])),
          (20, uri(schemes: ['http'])),
        ]),
        (u) {
          expect(['http', 'https'], contains(u.scheme));
        },
      );
    });

    property('works with list combinator', () {
      forAll(
        list(uri(schemes: ['https']), maxLength: 3),
        (uris) {
          for (final u in uris) {
            expect(u.scheme, equals('https'));
          }
        },
      );
    });

    property('nonEmpty extension works with URI lists', () {
      forAll(
        list(uri()).nonEmpty(),
        (uris) {
          expect(uris, isNotEmpty);
          for (final u in uris) {
            expect(u.toString(), isNotEmpty);
          }
        },
      );
    });

    property('URI toString is always non-empty', () {
      forAll(uri(), (u) {
        expect(u.toString(), isNotEmpty);
      });
    });

    property('different URI types maintain their characteristics', () {
      forAll(uri(schemes: ['file'], allowFile: true), (u) {
        if (u.scheme == 'file') {
          expect(u.host, isEmpty);
          expect(u.path, isNotEmpty);
        }
      });
    });
  });
}
