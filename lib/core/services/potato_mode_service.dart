import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

enum PotatoLevel { off, sweet, tiny }

enum DeviceType { phone, desktop }

class DeviceSpec {
  final int ramGB;
  final int cpuCores;
  final int batteryPercent;
  final DeviceType deviceType;
  final PotatoLevel potatoLevel;

  const DeviceSpec({
    required this.ramGB,
    required this.cpuCores,
    required this.batteryPercent,
    required this.deviceType,
    required this.potatoLevel,
  });

  bool get isLowRam => deviceType == DeviceType.phone ? ramGB < 4 : ramGB < 8;

  bool get isLowCPU =>
      deviceType == DeviceType.phone ? cpuCores < 2 : cpuCores < 6;

  bool get isLowBattery => batteryPercent < 20;

  bool get shouldEnablePotatoMode => isLowRam || isLowCPU || isLowBattery;
}

class PotatoModeConfig {
  final PotatoLevel level;
  final bool animationsEnabled;
  final bool lazyLoadingEnabled;
  final bool fancyUIAEnabled;
  final int maxListItems;
  final int imageQuality;
  final bool cacheEnabled;
  final bool shadowsEnabled;
  final bool blurEffectsEnabled;
  final int animationDurationMs;
  final bool debugLogs;

  const PotatoModeConfig({
    required this.level,
    this.animationsEnabled = true,
    this.lazyLoadingEnabled = true,
    this.fancyUIAEnabled = true,
    this.maxListItems = 50,
    this.imageQuality = 100,
    this.cacheEnabled = true,
    this.shadowsEnabled = true,
    this.blurEffectsEnabled = true,
    this.animationDurationMs = 300,
    this.debugLogs = false,
  });

  static const potatoOff = PotatoModeConfig(
    level: PotatoLevel.off,
    animationsEnabled: true,
    lazyLoadingEnabled: true,
    fancyUIAEnabled: true,
    maxListItems: 100,
    imageQuality: 100,
    cacheEnabled: true,
    shadowsEnabled: true,
    blurEffectsEnabled: true,
    animationDurationMs: 300,
    debugLogs: false,
  );

  static const potatoSweet = PotatoModeConfig(
    level: PotatoLevel.sweet,
    animationsEnabled: false,
    lazyLoadingEnabled: true,
    fancyUIAEnabled: false,
    maxListItems: 30,
    imageQuality: 60,
    cacheEnabled: false,
    shadowsEnabled: false,
    blurEffectsEnabled: false,
    animationDurationMs: 100,
    debugLogs: false,
  );

  static const potatoTiny = PotatoModeConfig(
    level: PotatoLevel.tiny,
    animationsEnabled: false,
    lazyLoadingEnabled: true,
    fancyUIAEnabled: false,
    maxListItems: 20,
    imageQuality: 40,
    cacheEnabled: false,
    shadowsEnabled: false,
    blurEffectsEnabled: false,
    animationDurationMs: 50,
    debugLogs: false,
  );

  String get levelName {
    switch (level) {
      case PotatoLevel.off:
        return 'العادي';
      case PotatoLevel.sweet:
        return 'بطاطا حلوة';
      case PotatoLevel.tiny:
        return 'بطاطا صغيرة';
    }
  }
}

class DeviceSpecDetector {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Battery _battery = Battery();

  static DeviceSpec? _cachedSpec;

  static Future<DeviceSpec> detectDevice() async {
    if (_cachedSpec != null) return _cachedSpec!;

    try {
      final ramGB = await _getRAM();
      final cpuCores = Platform.numberOfProcessors;
      final batteryPercent = await _getBattery();
      final deviceType = await _getDeviceType();
      final potatoLevel = _calculatePotatoLevel(
        ramGB,
        cpuCores,
        batteryPercent,
        deviceType,
      );

      _cachedSpec = DeviceSpec(
        ramGB: ramGB,
        cpuCores: cpuCores,
        batteryPercent: batteryPercent,
        deviceType: deviceType,
        potatoLevel: potatoLevel,
      );

      return _cachedSpec!;
    } catch (e) {
      return DeviceSpec(
        ramGB: 4,
        cpuCores: 2,
        batteryPercent: 50,
        deviceType: DeviceType.desktop,
        potatoLevel: PotatoLevel.off,
      );
    }
  }

  static Future<int> _getRAM() async {
    final cpuCores = Platform.numberOfProcessors;
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return _estimateRamFromAndroid(info);
      } else if (Platform.isIOS) {
        return 4;
      } else if (Platform.isLinux) {
        return 8;
      } else if (Platform.isWindows) {
        return cpuCores >= 8 ? 16 : 8;
      } else if (Platform.isMacOS) {
        return 8;
      }
    } catch (_) {}
    return 4;
  }

  static int _estimateRamFromAndroid(AndroidDeviceInfo info) {
    final model = info.model.toLowerCase();
    final brand = info.brand.toLowerCase();

    if (brand.contains('pixel') || model.contains('pixel')) {
      return 8;
    } else if (brand.contains('samsung')) {
      if (model.contains('s2') ||
          model.contains('s21') ||
          model.contains('s22') ||
          model.contains('s23')) {
        return 8;
      } else if (model.contains('a5') ||
          model.contains('a1') ||
          model.contains('m1')) {
        return 3;
      }
      return 4;
    } else if (brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco')) {
      return 4;
    } else if (brand.contains('oneplus')) {
      return 8;
    }
    return 4;
  }

  static Future<int> _getBattery() async {
    try {
      final level = await _battery.batteryLevel;
      return level;
    } catch (_) {
      return 50;
    }
  }

  static Future<DeviceType> _getDeviceType() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.isPhysicalDevice ? DeviceType.phone : DeviceType.desktop;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.isPhysicalDevice ? DeviceType.phone : DeviceType.desktop;
      }
    } catch (_) {}
    return DeviceType.desktop;
  }

  static PotatoLevel _calculatePotatoLevel(
    int ramGB,
    int cpuCores,
    int batteryPercent,
    DeviceType deviceType,
  ) {
    if (deviceType == DeviceType.phone) {
      if (ramGB < 2 || cpuCores < 2 || batteryPercent < 20) {
        return PotatoLevel.tiny;
      } else if (ramGB < 3 || cpuCores < 4 || batteryPercent < 30) {
        return PotatoLevel.sweet;
      }
      return PotatoLevel.off;
    } else {
      if (ramGB < 4 || cpuCores < 4 || batteryPercent < 20) {
        return PotatoLevel.tiny;
      } else if (ramGB < 8 || cpuCores < 6 || batteryPercent < 30) {
        return PotatoLevel.sweet;
      }
      return PotatoLevel.off;
    }
  }

  static PotatoModeConfig getConfigForLevel(PotatoLevel level) {
    switch (level) {
      case PotatoLevel.off:
        return PotatoModeConfig.potatoOff;
      case PotatoLevel.sweet:
        return PotatoModeConfig.potatoSweet;
      case PotatoLevel.tiny:
        return PotatoModeConfig.potatoTiny;
    }
  }

  static PotatoModeConfig getConfigForDevice(DeviceSpec spec) {
    return getConfigForLevel(spec.potatoLevel);
  }

  static void clearCache() {
    _cachedSpec = null;
  }
}
