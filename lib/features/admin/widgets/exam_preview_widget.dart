import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

/// Screen size presets for preview
enum PreviewDevice { mobile, tablet, desktop }

/// Widget to preview exam in different device sizes
class ExamPreviewWidget extends StatelessWidget {
  final Widget child;
  final PreviewDevice device;
  final bool showFrame;
  final bool showDeviceLabel;

  const ExamPreviewWidget({
    super.key,
    required this.child,
    this.device = PreviewDevice.mobile,
    this.showFrame = true,
    this.showDeviceLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get dimensions based on device type
    final dimensions = _getDimensions();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showDeviceLabel) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(
              builder: (context) => Text(
                _getDeviceLabel(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedColor(context),
                ),
              ),
            ),
          ),
        ],
        if (showFrame)
          Builder(
            builder: (context) => Container(
              width: dimensions.width,
              height: dimensions.height,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(dimensions.borderRadius),
                border: Border.all(
                  color: AppColors.mutedColor(context).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(dimensions.borderRadius),
                child: SizedBox(
                  width: dimensions.innerWidth,
                  height: dimensions.innerHeight,
                  child: SingleChildScrollView(child: child),
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: dimensions.innerWidth,
            height: dimensions.innerHeight,
            child: SingleChildScrollView(child: child),
          ),
      ],
    );
  }

  String _getDeviceLabel() {
    switch (device) {
      case PreviewDevice.mobile:
        return 'جوال (375px)';
      case PreviewDevice.tablet:
        return ' جهاز لوحي (768px)';
      case PreviewDevice.desktop:
        return ' حاسوب (1280px)';
    }
  }

  _DeviceDimensions _getDimensions() {
    switch (device) {
      case PreviewDevice.mobile:
        return _DeviceDimensions(
          width: 200,
          height: 350,
          innerWidth: 180,
          innerHeight: 320,
          borderRadius: 16,
        );
      case PreviewDevice.tablet:
        return _DeviceDimensions(
          width: 400,
          height: 500,
          innerWidth: 380,
          innerHeight: 460,
          borderRadius: 12,
        );
      case PreviewDevice.desktop:
        return _DeviceDimensions(
          width: 700,
          height: 500,
          innerWidth: 680,
          innerHeight: 460,
          borderRadius: 8,
        );
    }
  }
}

class _DeviceDimensions {
  final double width;
  final double height;
  final double innerWidth;
  final double innerHeight;
  final double borderRadius;

  const _DeviceDimensions({
    required this.width,
    required this.height,
    required this.innerWidth,
    required this.innerHeight,
    required this.borderRadius,
  });
}

/// Preview mode selector with tabs for different devices
class ExamPreviewSelector extends StatefulWidget {
  final Widget Function(PreviewDevice device) builder;

  const ExamPreviewSelector({super.key, required this.builder});

  @override
  State<ExamPreviewSelector> createState() => _ExamPreviewSelectorState();
}

class _ExamPreviewSelectorState extends State<ExamPreviewSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedColor(context),
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.phone_android, size: 20), text: 'جوال'),
              Tab(icon: Icon(Icons.tablet_android, size: 20), text: 'لوحي'),
              Tab(icon: Icon(Icons.desktop_windows, size: 20), text: 'حاسوب'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPreview(PreviewDevice.mobile),
              _buildPreview(PreviewDevice.tablet),
              _buildPreview(PreviewDevice.desktop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(PreviewDevice device) {
    return SingleChildScrollView(child: widget.builder(device));
  }
}
