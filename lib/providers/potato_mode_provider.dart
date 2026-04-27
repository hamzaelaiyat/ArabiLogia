import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PotatoModeProvider extends ChangeNotifier {
  DeviceSpec? _deviceSpec;
  PotatoModeConfig _config = PotatoModeConfig.potatoOff;
  bool _isLoaded = false;

  DeviceSpec? get deviceSpec => _deviceSpec;
  PotatoModeConfig get config => _config;
  bool get isLoaded => _isLoaded;
  PotatoLevel get level => _config.level;

  bool get animationsEnabled => _config.animationsEnabled;
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
    } catch (e) {
      _config = PotatoModeConfig.potatoOff;
    }

    _isLoaded = true;
    notifyListeners();
  }

  PotatoModeConfig getConfigForLevel(PotatoLevel level) {
    return DeviceSpecDetector.getConfigForLevel(level);
  }

  void setPotatoLevel(PotatoLevel level) {
    _config = getConfigForLevel(level);
    notifyListeners();
  }

  void clearCache() {
    DeviceSpecDetector.clearCache();
    _deviceSpec = null;
    _isLoaded = false;
  }
}

class PotatoModeWrapper extends StatelessWidget {
  final Widget child;
  final bool useInListView;
  final ScrollController? controller;

  const PotatoModeWrapper({
    super.key,
    required this.child,
    this.useInListView = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (useInListView && potato.lazyLoadingEnabled) {
          return LazyLoadWrapper(
            maxItems: potato.maxListItems,
            controller: controller,
            child: child,
          );
        }
        return child;
      },
    );
  }
}

class LazyLoadWrapper extends StatefulWidget {
  final int maxItems;
  final Widget child;
  final ScrollController? controller;

  const LazyLoadWrapper({
    super.key,
    required this.maxItems,
    required this.child,
    this.controller,
  });

  @override
  State<LazyLoadWrapper> createState() => _LazyLoadWrapperState();
}

class _LazyLoadWrapperState extends State<LazyLoadWrapper> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    // In a real implementation, this would trigger loading more items
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AnimatedWrapper extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Curve curve;
  final bool addAnimation;

  const AnimatedWrapper({
    super.key,
    required this.child,
    this.duration,
    this.curve = Curves.easeInOut,
    this.addAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (!addAnimation || !potato.animationsEnabled) {
          return child;
        }

        return AnimatedOpacity(
          duration: duration ?? potato.animationDuration,
          curve: curve,
          opacity: 1.0,
          child: child,
        );
      },
    );
  }
}

class PerformanceIndicator extends StatelessWidget {
  final bool showDetails;

  const PerformanceIndicator({super.key, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (!potato.isLoaded) {
          return const SizedBox.shrink();
        }

        final color = _getColor(potato.level);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.speed, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                potato.levelName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (showDetails && potato.deviceSpec != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${potato.deviceSpec!.ramGB}GB/${potato.deviceSpec!.cpuCores} cores',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${potato.deviceSpec!.batteryPercent}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: potato.deviceSpec!.batteryPercent < 20
                        ? Colors.red
                        : color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getColor(PotatoLevel level) {
    switch (level) {
      case PotatoLevel.off:
        return Colors.green;
      case PotatoLevel.sweet:
        return Colors.orange;
      case PotatoLevel.tiny:
        return Colors.red;
    }
  }
}
