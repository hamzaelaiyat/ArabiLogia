import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/services/update_service.dart';

const _release = '''
{
  "tag_name": "v26.9.26-01",
  "name": "ArabiLogia v26.9.26-01 [PREVIEW]",
  "prerelease": false,
  "body": "# الجديد\\n## المميزات\\n- مشاركة بين الصفوف",
  "assets": [
    {"name": "arabilogia-arm64-v8a-v26.9.26-01.apk", "size": 52523595,
     "browser_download_url": "https://example/arm64.apk"},
    {"name": "arabilogia-armeabi-v7a-v26.9.26-01.apk", "size": 50850747,
     "browser_download_url": "https://example/v7a.apk"},
    {"name": "arabilogia-v26.9.26-01-linux-x64.tar.xz", "size": 31376376,
     "browser_download_url": "https://example/linux.tar.xz"}
  ]
}
''';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UpdateService.httpFetchOverride = null;
    UpdateService.currentVersionOverride = null;
  });

  tearDown(() {
    UpdateService.httpFetchOverride = null;
    UpdateService.currentVersionOverride = null;
  });

  group('detects the preview release from an older build', () {
    test('26.9.25 install is offered 26.9.26-01', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async =>
          http.Response(_release, 200, headers: {'content-type': 'application/json'});

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.result, UpdateCheckResult.updateAvailable);
      // The preview suffix is preserved so it can be compared and displayed.
      expect(report.latestVersion, '26.9.26-01');
      expect(report.currentVersion, '26.9.25');
      // Never hand a user an asset built for another platform.
      final os = Platform.operatingSystem;
      if (os == 'linux') {
        expect(report.assetName, endsWith('.tar.xz'));
      } else if (os == 'android') {
        expect(report.assetName, contains('arm64-v8a'));
      }
    });

    test('linux is offered the tar.xz bundle, not an APK', () async {
      // Guards the regression where linux matched only .AppImage/.deb and
      // silently fell back to assets.first, offering an Android APK.
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async =>
          http.Response(_release, 200, headers: {'content-type': 'application/json'});

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      if (Platform.operatingSystem == 'linux') {
        expect(report.assetName, isNot(endsWith('.apk')));
        expect(report.assetName, endsWith('linux-x64.tar.xz'));
      }
    });

    test('a release with no asset for this platform is reported', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async => http.Response(
            jsonEncode({
              'tag_name': 'v26.9.26-01',
              'name': 'no assets',
              'assets': <Object>[],
            }),
            200,
          );

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.failure, UpdateCheckFailure.noAsset);
    });

    test('the same build is not offered its own version', () async {
      UpdateService.currentVersionOverride = () async => '26.9.26-01';
      UpdateService.httpFetchOverride = (uri) async =>
          http.Response(_release, 200, headers: {'content-type': 'application/json'});

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.result, UpdateCheckResult.noUpdate);
    });
  });

  group('failures are reported instead of vanishing', () {
    test('403 is identified as a rate limit', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async => http.Response(
            '{"message":"API rate limit exceeded"}',
            403,
            headers: {'x-ratelimit-remaining': '0'},
          );

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.result, UpdateCheckResult.error);
      expect(report.failure, UpdateCheckFailure.rateLimited);
      expect(report.httpStatus, 403);
    });

    test('500 is identified as a server error', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride =
          (uri) async => http.Response('boom', 500);

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.failure, UpdateCheckFailure.serverError);
    });

    test('unparseable payload is reported, not thrown', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride =
          (uri) async => http.Response('not json at all', 200);

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.failure, UpdateCheckFailure.malformedResponse);
    });

    test('a network throw is reported as a network failure', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async => throw const SocketLike();

      final report = await UpdateService.checkForUpdatesInBackground(force: true);

      expect(report.failure, UpdateCheckFailure.network);
    });
  });

  group('a failed check does not silence the next launch', () {
    test('network failure leaves the cooldown untouched', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async => throw const SocketLike();

      await UpdateService.checkForUpdatesInBackground(force: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_update_check'), isNull,
          reason: 'a failed attempt must not start the cooldown');

      // The next automatic check must be allowed to run.
      UpdateService.httpFetchOverride = (uri) async =>
          http.Response(_release, 200, headers: {'content-type': 'application/json'});
      final second = await UpdateService.checkForUpdatesInBackground();

      expect(second.result, UpdateCheckResult.updateAvailable);
    });

    test('a successful check starts the cooldown', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async =>
          http.Response(_release, 200, headers: {'content-type': 'application/json'});

      await UpdateService.checkForUpdatesInBackground(force: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_update_check'), isNotNull);
    });
  });

  group('a detected update is never lost', () {
    test('pending update can be taken when no screen was listening', () async {
      UpdateService.currentVersionOverride = () async => '26.9.25';
      UpdateService.httpFetchOverride = (uri) async =>
          http.Response(_release, 200, headers: {'content-type': 'application/json'});

      final report = await UpdateService.checkForUpdatesInBackground(force: true);
      expect(report.hasUpdate, isTrue);

      final pending = UpdateService.takePendingUpdate();
      expect(pending, isNotNull);
      expect(pending!.version, '26.9.26-01');
      expect(UpdateService.takePendingUpdate(), isNull,
          reason: 'taken once, so it is not pushed twice');
    });
  });
}

class SocketLike implements Exception {
  const SocketLike();
  @override
  String toString() => 'SocketLike: connection failed';
}
