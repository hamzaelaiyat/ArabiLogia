import 'dart:convert';
import 'package:http/http.dart' as http;

class ReleaseInfo {
  final String version;
  final String? apkUrl;
  final String? apkName;
  final String releaseNotes;

  ReleaseInfo({
    required this.version,
    this.apkUrl,
    this.apkName,
    required this.releaseNotes,
  });
}

class LandingService {
  static const String _owner = 'hamzaelaiyat';
  static const String _repo = 'ArabiLogia';

  static Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_owner/$_repo/releases/latest',
            ),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'ArabiLogia-Landing',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final tagName = data['tag_name'] as String? ?? 'v2.8.23';
      final version = tagName.replaceFirst(RegExp(r'^v'), '');
      final body = data['body'] as String? ?? '';
      final assets = data['assets'] as List? ?? [];

      String? apkUrl;
      String? apkName;

      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.contains('arm64-v8a') && name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          apkName = name;
          break;
        }
      }

      if (apkUrl == null) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkName = name;
            break;
          }
        }
      }

      return ReleaseInfo(
        version: version,
        apkUrl: apkUrl,
        apkName: apkName,
        releaseNotes: body,
      );
    } catch (_) {
      return null;
    }
  }
}
