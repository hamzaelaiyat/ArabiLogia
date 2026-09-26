import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/video_utils.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';

// Dummy WebViewPlatform implementation for platforms (like Linux desktop) without native webview support
class _DummyWebViewPlatform extends WebViewPlatform {
  final VoidCallback? onLaunchVideo;
  _DummyWebViewPlatform([this.onLaunchVideo]);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _DummyNavigationDelegate(params);
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return _DummyWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _DummyWebViewWidget(params, onLaunchVideo: onLaunchVideo);
  }
}

class _DummyNavigationDelegate extends PlatformNavigationDelegate {
  _DummyNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
}

class _DummyWebViewController extends PlatformWebViewController {
  _DummyWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<String> runJavaScriptReturningResult(String javaScript) async => '';

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {}

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage message) onConsoleMessage,
  ) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> clearLocalStorage() async {}
}

class _DummyWebViewWidget extends PlatformWebViewWidget {
  final PlatformWebViewWidgetCreationParams creationParams;
  final VoidCallback? onLaunchVideo;

  _DummyWebViewWidget(this.creationParams, {this.onLaunchVideo})
    : super.implementation(creationParams);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLaunchVideo,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'انقر هنا لتشغيل الفيديو',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YoutubeBlockWidget extends StatefulWidget {
  final LectureContentBlock block;
  final bool isCompleted;
  final VoidCallback onToggleCompletion;

  const YoutubeBlockWidget({
    super.key,
    required this.block,
    required this.isCompleted,
    required this.onToggleCompletion,
  });

  @override
  State<YoutubeBlockWidget> createState() => _YoutubeBlockWidgetState();
}

class _YoutubeBlockWidgetState extends State<YoutubeBlockWidget> {
  YoutubePlayerController? _controller;
  Timer? _positionTimer;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _currentPlaybackRate = 1.0;

  String get _videoId => getVideoId(widget.block.content);

  Future<void> _setSpeed(double speed) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setPlaybackRate(speed);
      if (mounted) setState(() => _currentPlaybackRate = speed);
    } catch (e) {
      debugPrint('🔴 Failed to set playback rate: $e');
    }
  }

  Future<void> _seekRelative(int secondsDelta) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final current = await controller.currentTime;
      final newPos = (current + secondsDelta).clamp(0.0, 86400.0);
      await controller.seekTo(seconds: newPos);
    } catch (e) {
      debugPrint('🔴 Failed to seek video position: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureWebViewPlatform();
  }

  void _ensureWebViewPlatform() {
    try {
      if (WebViewPlatform.instance == null) {
        WebViewPlatform.instance = _DummyWebViewPlatform(_launchExternalVideo);
      }
    } catch (e) {
      debugPrint('WebView platform null check failed, trying fallback: $e');
      try {
        WebViewPlatform.instance = _DummyWebViewPlatform(_launchExternalVideo);
      } catch (e) {
        debugPrint("Silently caught error: $e");
      }
    }
  }

  Future<void> _launchExternalVideo() async {
    if (_videoId.isEmpty) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$_videoId');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (e) {
      debugPrint("Silently caught error: $e");
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('🔴 Launch external video error: $e');
    }
  }

  Future<void> _startPlaying() async {
    if (_videoId.isEmpty) {
      debugPrint('🔴 Video ID is empty for block: ${widget.block.content}');
      return;
    }

    _ensureWebViewPlatform();

    if (!widget.isCompleted) {
      widget.onToggleCompletion();
    }

    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (_controller == null) {
      int lastPosition = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        lastPosition = prefs.getInt('yt_$_videoId') ?? 0;
      } catch (e) {
        debugPrint('🔴 Failed to read saved YT position: $e');
      }

      try {
        debugPrint(
          '▶️ Initializing YoutubePlayerController for videoId: $_videoId',
        );
        final controller = YoutubePlayerController.fromVideoId(
          videoId: _videoId,
          autoPlay: true,
          startSeconds: lastPosition > 3 ? lastPosition.toDouble() : null,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true,
            showControls: true,
          ),
        );

        if (!mounted) return;
        setState(() {
          _controller = controller;
          _isPlaying = true;
        });

        _positionTimer?.cancel();
        _positionTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _savePosition(),
        );
        debugPrint('✅ YoutubePlayerController initialized successfully!');
      } catch (e, stack) {
        debugPrint('🔴 EXCEPTION in YoutubePlayerController init: $e');
        debugPrint('🔴 STACKTRACE: $stack');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = '$e';
            _isPlaying = false;
          });
        }
      }
    } else {
      try {
        setState(() {
          _isPlaying = true;
        });
        _controller?.playVideo();
        debugPrint('▶️ Resumed playing videoId: $_videoId');
      } catch (e, stack) {
        debugPrint('🔴 EXCEPTION in playVideo: $e');
        debugPrint('🔴 STACKTRACE: $stack');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = '$e';
            _isPlaying = false;
          });
        }
      }
    }
  }

  Future<void> _savePosition() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final position = await controller.currentTime;
      if (position <= 0) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('yt_$_videoId', position.round());
    } catch (e) {
      debugPrint('🔴 Failed to save YT position: $e');
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    unawaited(_savePosition());
    _controller?.close();
    super.dispose();
  }

  Widget _buildVideoThumbnail(String duration) {
    return GestureDetector(
      onTap: _startPlaying,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                color: Colors.grey.shade900,
                child: const Icon(
                  Icons.video_library_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.3)),
            Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            if (duration.isNotEmpty)
              Positioned(
                bottom: AppTokens.spacing8,
                left: AppTokens.spacing8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.amber,
            size: 36,
          ),
          const SizedBox(height: 8),
          const Text(
            'خطأ في تشغيل المشغل المدمج:',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SelectableText(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : 'حدث خطأ استثناء غير معروف عند تحميل المشغل',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _startPlaying,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _launchExternalVideo,
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'فتح في يوتيوب',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.block.metadata?['title'] ?? 'فيديو الشرح للمحاضرة';
    final rawDuration = widget.block.metadata?['duration']?.toString() ?? '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusLgAll),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasError)
                _buildErrorWidget()
              else if (_isPlaying && _controller != null) ...[
                YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: Theme.of(context).cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, size: 22),
                            tooltip: 'تراجع 10 ثوانٍ',
                            onPressed: () => _seekRelative(-10),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10_rounded,
                              size: 22,
                            ),
                            tooltip: 'تقديم 10 ثوانٍ',
                            onPressed: () => _seekRelative(10),
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'السرعة: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            for (final speed in [1.0, 1.25, 1.5, 2.0])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: ChoiceChip(
                                  label: Text(
                                    '${speed}x',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: _currentPlaybackRate == speed,
                                  onSelected: (_) => _setSpeed(speed),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_videoId.isNotEmpty)
                _buildVideoThumbnail(rawDuration)
              else
                Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Center(child: Text('رابط الفيديو غير صالح')),
                ),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spacing16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _launchExternalVideo,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'فتح في يوتيوب',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: widget.onToggleCompletion,
                      icon: Icon(
                        widget.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: widget.isCompleted ? Colors.green : Colors.grey,
                      ),
                      label: Text(
                        widget.isCompleted ? 'تمت المشاهدة' : 'حدد كمشاهد',
                        style: TextStyle(
                          color: widget.isCompleted
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
