import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  // Ad Unit ID from AdMob
  // Note: The ad unit ID format from user appears to have issues
  // Using the format: ca-app-pub-XXXX/YYYY
  static const String _adUnitId = 'ca-app-pub-8677686078416176/7792528013';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adLoader = NativeAdListener(
      onAdLoaded: (ad) {
        setState(() {
          _nativeAd = ad as NativeAd;
          _isAdLoaded = true;
          _isAdFailed = false;
        });
      },
      onAdFailedToLoad: (ad, error) {
        setState(() {
          _isAdFailed = true;
          _isAdLoaded = false;
        });
        ad.dispose();
      },
    );

    final request = AdRequest(
      keywords: ['education', 'exam', 'learning', 'arabic'],
      nonPersonalizedAds: false,
    );

    final nativeAd = NativeAd(
      adUnitId: _adUnitId,
      factoryId: 'adFactoryExample',
      listener: adLoader,
      request: request,
    );

    nativeAd.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdFailed) {
      // Return a placeholder when ad fails to load
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: AppTokens.spacing8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'إعلان',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (!_isAdLoaded || _nativeAd == null) {
      // Return a loading placeholder
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: AppTokens.spacing8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Return the native ad widget
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: AppTokens.spacing8),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

// Alternative simple native ad widget that works with custom layout
class SimpleNativeAdWidget extends StatefulWidget {
  const SimpleNativeAdWidget({super.key});

  @override
  State<SimpleNativeAdWidget> createState() => _SimpleNativeAdWidgetState();
}

class _SimpleNativeAdWidgetState extends State<SimpleNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  static const String _adUnitId = 'ca-app-pub-8677686078416176/7792528013';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adLoader = NativeAdListener(
      onAdLoaded: (ad) {
        setState(() {
          _nativeAd = ad as NativeAd;
          _isAdLoaded = true;
          _isAdFailed = false;
        });
      },
      onAdFailedToLoad: (ad, error) {
        setState(() {
          _isAdFailed = true;
          _isAdLoaded = false;
        });
        ad.dispose();
      },
    );

    final request = AdRequest(
      keywords: ['education', 'exam', 'learning', 'arabic'],
      nonPersonalizedAds: false,
    );

    final nativeAd = NativeAd(
      adUnitId: _adUnitId,
      factoryId: 'adFactoryExample',
      listener: adLoader,
      request: request,
    );

    nativeAd.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: AppTokens.spacing8),
      child: _isAdLoaded && _nativeAd != null
          ? AdWidget(ad: _nativeAd!)
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _isAdFailed
                    ? const Text('إعلان', style: TextStyle(color: Colors.grey))
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            ),
    );
  }
}
