import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

/// Shows content as a bottom sheet on mobile or navigates to a full page on desktop.
///
/// On mobile: shows [showModalBottomSheet] with the content widget.
/// On desktop/tablet: pushes a [MaterialPageRoute] with a [Scaffold] wrapping
/// the content, giving a full-page experience.
///
/// Example:
/// ```dart
/// ResponsiveOverlay.show(
///   context: context,
///   title: 'Question Preview',
///   mobileBuilder: (ctx) => _buildBottomSheetContent(ctx),
///   desktopBuilder: (ctx) => _buildFullPageContent(ctx),
/// );
/// ```
class ResponsiveOverlay {
  /// Shows content responsively: bottom sheet on mobile, full page on desktop.
  ///
  /// [title] - AppBar title for the desktop full page (ignored on mobile).
  /// [mobileBuilder] - Builds the bottom sheet content. If null, [child] is used.
  /// [desktopBuilder] - Builds the full page content. If null, [child] is used.
  /// [child] - Simple content widget used when both builders are null.
  /// [isScrollControlled] - For bottom sheet, whether to allow full height.
  /// [useRootNavigator] - Whether to use the root navigator for the bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget Function(BuildContext context)? mobileBuilder,
    Widget Function(BuildContext context)? desktopBuilder,
    Widget? child,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
  }) {
    final isDesktop = AppTokens.isDesktop(context);

    if (isDesktop) {
      final content = desktopBuilder != null
          ? Builder(builder: desktopBuilder)
          : child ?? const SizedBox.shrink();
      return Navigator.of(context, rootNavigator: true).push<T>(
        MaterialPageRoute(
          builder: (_) => _DesktopPage(title: title, child: content),
        ),
      );
    } else {
      final content = mobileBuilder != null
          ? Builder(builder: mobileBuilder)
          : child ?? const SizedBox.shrink();
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        backgroundColor: Colors.transparent,
        builder: (_) => content,
      );
    }
  }
}

/// A simple full-page scaffold for desktop content.
class _DesktopPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _DesktopPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: child,
    );
  }
}

/// A full-page wrapper for desktop content with custom AppBar actions.
///
/// Use this when you need more control over the AppBar than [ResponsiveOverlay]
/// provides, such as custom actions or a custom leading widget.
class ResponsivePage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;

  const ResponsivePage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading:
            leading ??
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
        actions: actions,
      ),
      body: body,
    );
  }
}
