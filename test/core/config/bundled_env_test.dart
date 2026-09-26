import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the bundled `.env` asset.
///
/// `pubspec.yaml` lists `.env` under `flutter/assets`, so this file is copied
/// into every release artifact: the APKs, the Linux bundle and — most visibly —
/// `public/assets/.env` on Vercel. Anything in here is public, so only the
/// Supabase URL and the RLS-protected anon key may live in it.
///
/// Server-only secrets belong in `.env.secrets` (git-ignored) and in Supabase
/// Edge Function secrets.
void main() {
  group('bundled .env', () {
    late Map<String, String> entries;

    setUpAll(() {
      final file = File('.env');
      expect(
        file.existsSync(),
        isTrue,
        reason: '.env is required: it is bundled as an asset at build time',
      );
      entries = {};
      for (final line in const LineSplitter().convert(
        file.readAsStringSync(),
      )) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final separator = trimmed.indexOf('=');
        if (separator <= 0) continue;
        entries[trimmed.substring(0, separator)] =
            trimmed.substring(separator + 1);
      }
    });

    test('exposes the Supabase config the app needs', () {
      expect(entries.keys, contains('SUPABASE_URL'));
      expect(entries.keys, contains('SUPABASE_ANON_KEY'));
      expect(entries['SUPABASE_URL'], isNotEmpty);
      expect(entries['SUPABASE_ANON_KEY'], isNotEmpty);
    });

    test('contains no server-side secrets', () {
      const forbidden = <String>[
        'GITHUB_TOKEN',
        'GH_TOKEN',
        'ONESIGNAL_API_KEY',
        'GOOGLE_AI',
        'SE_API_USER',
        'SE_API_SECRET',
        'SUPABASE_SERVICE_ROLE_KEY',
        'SENTRY_DSN',
      ];

      for (final key in forbidden) {
        expect(
          entries.containsKey(key),
          isFalse,
          reason:
              '$key is bundled into the public artifacts. Move it to '
              '.env.secrets / Supabase secrets.',
        );
      }
    });

    test('no key name looks like a secret', () {
      final suspicious = entries.keys.where(
        (key) =>
            key.contains('SECRET') ||
            key.contains('TOKEN') ||
            key.contains('PASSWORD') ||
            key.contains('PRIVATE') ||
            key.contains('SERVICE_ROLE'),
      );
      expect(
        suspicious,
        isEmpty,
        reason: 'Suspicious keys in the bundled .env: $suspicious',
      );
    });

    test('ships the anon key, not a service role key', () {
      final parts = entries['SUPABASE_ANON_KEY']!.split('.');
      expect(parts.length, 3, reason: 'anon key should be a JWT');
      final claims = utf8
          .decode(_base64UrlDecode(parts[1]))
          .toLowerCase();
      expect(claims, contains('"role":"anon"'));
    });
  });
}

List<int> _base64UrlDecode(String input) {
  final normalized = input.replaceAll('-', '+').replaceAll('_', '/');
  final padding = (4 - normalized.length % 4) % 4;
  return base64.decode('$normalized${'=' * padding}');
}
