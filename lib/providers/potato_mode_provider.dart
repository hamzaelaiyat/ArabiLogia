import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';

class PotatoModeProvider extends ChangeNotifier {
  DeviceSpec? _deviceSpec;
  PotatoModeConfig _config = PotatoModeConfig.potatoOff;
  bool _isLoaded = false;

  DeviceSpec? get deviceSpec => _deviceSpec;
  PotatoModeConfig get config => _config;
  bool get isLoaded => _isLoaded;
  PotatoLevel get level => _config.level;

  bool get animationsEnabled => _config.animationsEnabled;
  bool get transitionsEnabled => _config.transitionsEnabled;
  bool get fancyUIAEnabled => _config.fancyUIAEnabled;
  bool get lazyLoadingEnabled => _config.lazyLoadingEnabled;
  bool get shadowsEnabled => _config.shadowsEnabled;
  bool get blurEffectsEnabled => _config.blurEffectsEnabled;
  bool get cacheEnabled => _config.cacheEnabled;
  int get maxListItems => _config.maxListItems;
  int get imageQuality => _config.imageQuality;
  int get animationDurationMs => _config.animationDurationMs;

  Duration get animationDuration =>
      Duration(milliseconds: _config.animationDurationMs);

  String get levelName => _config.levelName;

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      _deviceSpec = await DeviceSpecDetector.detectDevice();
      _config = DeviceSpecDetector.getConfigForDevice(_deviceSpec!);

      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getString('potato_level');
      if (savedLevel != null) {
        final level = PotatoLevel.values.firstWhere(
          (e) => e.name == savedLevel,
          orElse: () => PotatoLevel.off,
        );
        _config = getConfigForLevel(level);
      }
    } catch (e) {
      _config = PotatoModeConfig.potatoOff;
    }

    _isLoaded = true;
    notifyListeners();
  }

  PotatoModeConfig getConfigForLevel(PotatoLevel level) {
    return DeviceSpecDetector.getConfigForLevel(level);
  }

  void setPotatoLevel(PotatoLevel level) async {
    _config = getConfigForLevel(level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('potato_level', level.name);
    notifyListeners();
  }

  void clearCache() {
    DeviceSpecDetector.clearCache();
    _deviceSpec = null;
    _isLoaded = false;
  }
}
