import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final info = <String, dynamic>{};
      info['platform'] = Platform.operatingSystem;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['device'] = androidInfo.model;
        info['brand'] = androidInfo.brand;
        info['deviceId'] = androidInfo.id;
        info['sdkVersion'] = androidInfo.version.sdkInt;
        info['isPhysicalDevice'] = androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['device'] = iosInfo.model;
        info['brand'] = 'Apple';
        info['deviceId'] = iosInfo.identifierForVendor;
        info['systemVersion'] = iosInfo.systemVersion;
        info['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info['device'] = windowsInfo.computerName;
        info['brand'] = 'Windows';
        info['productName'] = windowsInfo.productName;
        info['displayVersion'] = windowsInfo.displayVersion;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info['device'] = linuxInfo.prettyName;
        info['brand'] = 'Linux';
        info['distroId'] = linuxInfo.id;
        info['distroVersion'] = linuxInfo.versionId;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        info['device'] = macInfo.model;
        info['brand'] = 'Apple';
        info['systemVersion'] = macInfo.osRelease;
        info['deviceId'] = macInfo.systemGUID;
      } else {
        info['device'] = 'Unknown';
      }

      return info;
    } catch (e) {
      return {
        'platform': Platform.operatingSystem,
        'device': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  static Future<String> getDeviceInfoString() async {
    final info = await getDeviceInfo();
    final parts = <String>[
      'Platform: ${info['platform']}',
      'Device: ${info['device']}',
    ];
    if (info['brand'] != null) parts.add('Brand: ${info['brand']}');
    if (info['sdkVersion'] != null) parts.add('SDK: ${info['sdkVersion']}');
    if (info['systemVersion'] != null) parts.add('OS: ${info['systemVersion']}');
    if (info['productName'] != null) parts.add('Product: ${info['productName']}');
    return parts.join(' | ');
  }

  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (e) {
      return 'Unknown';
    }
  }

  static Future<String> getPackageName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.packageName;
    } catch (e) {
      return '';
    }
  }
}
