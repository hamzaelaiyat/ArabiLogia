import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/app_version.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import '../services/landing_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  ReleaseInfo? _releaseInfo;
  bool _isLoading = true;
  bool _hasError = false;

  final _downloadKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _pageController = PageController();
  final _scrollController = ScrollController();
  Timer? _slideTimer;
  int _currentSlide = 0;
  bool _mobileMenuOpen = false;

  final _albumImages = [
    'assets/images/album/673883538_951805597708178_3676183158133156276_n.jpg',
    'assets/images/album/674395376_951805591041512_7371181102297422668_n.jpg',
    'assets/images/album/678278711_955818653973539_6676515568733782605_n.jpg',
    'assets/images/album/678465217_955818770640194_2596401437582107264_n.jpg',
    'assets/images/album/679831904_955818623973542_7211739239666954843_n.jpg',
    'assets/images/album/679859404_955818607306877_8739552286049830360_n.jpg',
    'assets/images/album/682518386_955818660640205_8176697648994662818_n.jpg',
    'assets/images/album/682525117_955818720640199_8622116451925099152_n.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRelease();
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentSlide + 1) % _albumImages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _currentSlide = next;
    });
  }

  Future<void> _fetchRelease() async {
    setState(() => _isLoading = true);
    final info = await LandingService.fetchLatestRelease();
    if (mounted) {
      setState(() {
        _releaseInfo = info;
        _isLoading = false;
        _hasError = info == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 992;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(brightness),
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 72),
                _buildHeroSection(context, isDesktop, isMobile),
                _buildFeaturesSection(context, isDesktop, isMobile, brightness),
                _buildDownloadSection(context, isDesktop),
                _buildFooter(context, brightness),
              ],
            ),
          ),
          _buildHeader(context, isDesktop),
          if (_mobileMenuOpen && !isDesktop)
            _buildMobileMenu(context, brightness),
        ],
      ),
    );
  }

  Widget _buildBackground(Brightness brightness) {
    return Positioned.fill(
      child: Image.asset(
        brightness == Brightness.dark
            ? 'assets/images/clouds-darkmode.png'
            : 'assets/images/clouds-image.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark
                  ? const Color(0xFF191B1D).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.75),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo-removedbg.png',
                    height: isDesktop ? 36 : 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  if (isDesktop) ...[
                    _NavLinks(
                      onFeaturesTap: () => _scrollTo(_featuresKey),
                      onDownloadTap: () => _scrollTo(_downloadKey),
                    ),
                    const Spacer(),
                    _buildThemeToggle(themeProvider),
                    const SizedBox(width: 8),
                    _buildCtaButton(context),
                  ] else ...[
                    const Spacer(),
                    _buildThemeToggle(themeProvider),
                    const SizedBox(width: 8),
                    _buildHamburger(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildThemeToggle(ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          color: isDark
              ? const Color(0xFF1E1E1E).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.7),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            key: ValueKey(isDark),
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return FilledButton(
      onPressed: () => context.push(AppRoutes.register),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text('الدخول للمنصة'),
    );
  }

  Widget _buildHamburger() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _mobileMenuOpen = !_mobileMenuOpen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          color: isDark
              ? const Color(0xFF1E1E1E).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.7),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _mobileMenuOpen ? Icons.close : Icons.menu,
            key: ValueKey(_mobileMenuOpen),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenu(BuildContext context, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return Positioned(
      top: 72,
      left: 0,
      right: 0,
      child: Container(
        color: isDark ? const Color(0xFF212325) : const Color(0xFFEDF2F8),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _mobileLink(context, 'الرئيسية', () {
              setState(() => _mobileMenuOpen = false);
            }),
            const SizedBox(height: 16),
            _mobileLink(context, 'المميزات', () {
              setState(() => _mobileMenuOpen = false);
              _scrollTo(_featuresKey);
            }),
            const SizedBox(height: 16),
            _mobileLink(context, 'التحميل', () {
              setState(() => _mobileMenuOpen = false);
              _scrollTo(_downloadKey);
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() => _mobileMenuOpen = false);
                context.push(AppRoutes.register);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('الدخول للمنصة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLink(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    bool isDesktop,
    bool isMobile,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 16,
        vertical: isDesktop ? 100 : 60,
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildHeroText(context, isDesktop)),
                const SizedBox(width: 48),
                SizedBox(
                  width: 480,
                  height: 420,
                  child: _buildSlideshow(),
                ),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: _buildSlideshow(),
                ),
                const SizedBox(height: 32),
                _buildHeroText(context, isDesktop),
              ],
            ),
    );
  }

  Widget _buildHeroText(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text.rich(
          TextSpan(
            style: GoogleFonts.rubik(
              fontSize: isDesktop ? 56 : 40,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: [
              const TextSpan(text: 'لغتنا الجميلة\n'),
              TextSpan(
                text: 'بطريقة ذكية',
                style: GoogleFonts.rubik(
                  fontSize: isDesktop ? 56 : 40,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 16),
        Text(
          'منصة تعليمية مبتكرة مصممة خصيصاً لطلاب الثانوية العامة، تجمع بين قوة التكنولوجيا وجمال لغة الضاد لتجعل تعلم النحو والصرف والبلاغة والأدب تجربة ممتعة وتفاعلية لا تُنسى.',
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.6,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.register),
              icon: const Icon(Icons.person_add),
              label: Text(
                'ابدأ الآن مجاناً',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => _scrollTo(_downloadKey),
              icon: const Icon(Icons.download),
              label: Text(
                'تحميل التطبيق',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlideshow() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _albumImages.length,
            onPageChanged: (index) => _currentSlide = index,
            itemBuilder: (context, index) {
              return Image.asset(
                _albumImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF212325)
                        : const Color(0xFFEDF2F8),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _albumImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentSlide == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentSlide == index
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _features = [
    _FeatureData(
      icon: Icons.quiz_outlined,
      title: 'امتحانات تفاعلية',
      description: 'اختبر معلوماتك في النحو والأدب والبلاغة والقراءة مع آلاف الأسئلة المصممة طبقاً للنظام الحديث للثانوية العامة.',
    ),
    _FeatureData(
      icon: Icons.leaderboard_outlined,
      title: 'لوحة المتصدرين',
      description: 'أشعل روح الحماس والتنافس مع زملائك على مستوى الجمهورية وتصدر القائمة الأسبوعية للحصول على ألقاب مميزة.',
    ),
    _FeatureData(
      icon: Icons.trending_up,
      title: 'تتبع التقدم',
      description: 'إحصائيات تفصيلية لمستوى إنجازك في كل فرع، تساعدك على معرفة نقاط قوتك وضعفك لتركز عليها.',
    ),
    _FeatureData(
      icon: Icons.category_outlined,
      title: 'تصنيفات شاملة',
      description: 'تقسيم منظم للمنهج يغطي النحو، الصرف، الأدب، البلاغة، النصوص والقراءة لتسهيل الوصول والتنقل.',
    ),
    _FeatureData(
      icon: Icons.speed,
      title: 'وضع الأداء',
      description: 'واجهة خفيفة وسريعة تتكيف مع سرعة جهازك ونوع اتصالك بالإنترنت لتقديم تجربة تصفح سلسة بلا انقطاع.',
    ),
    _FeatureData(
      icon: Icons.palette_outlined,
      title: 'تصاميم جذابة',
      description: 'تصميم عصري مريح للعين يدعم المظهرين الداكن والفاتح بالكامل، ليمنحك متعة التعلم ليلاً أو نهاراً.',
    ),
  ];

  Widget _buildFeaturesSection(
    BuildContext context,
    bool isDesktop,
    bool isMobile,
    Brightness brightness,
  ) {
    return Container(
      key: _featuresKey,
      width: double.infinity,
      color: brightness == Brightness.dark
          ? const Color(0xFF212325)
          : const Color(0xFFEDF2F8),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 16,
        vertical: isDesktop ? 80 : 60,
      ),
      child: Column(
        children: [
          Text(
            'مميزات المنصة',
            style: GoogleFonts.rubik(
              fontSize: isDesktop ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'كل ما يحتاجه طالب الثانوية العامة للتميز والتفوق في مادة اللغة العربية',
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: _features.map((feature) {
              return SizedBox(
                width: isMobile ? double.infinity : 320,
                child: _FeatureCard(feature: feature, brightness: brightness),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection(BuildContext context, bool isDesktop) {
    final version = _releaseInfo?.version ?? AppVersion.versionSync;
    final apkUrl = _releaseInfo?.apkUrl;
    final hasRelease = _releaseInfo != null && apkUrl != null;

    return Container(
      key: _downloadKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 16,
        vertical: isDesktop ? 80 : 60,
      ),
      child: Column(
        children: [
          Text(
            'ادرس في أي وقت، ومن أي جهاز',
            style: GoogleFonts.rubik(
              fontSize: isDesktop ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تدعم منصة عربيلوجيا التشغيل عبر الويب مباشرة، كما نوفر تطبيقات رسمية لنظام الأندرويد ولينكس لتستمتع بأفضل أداء وتجربة تعليمية خفيفة وسريعة.',
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'الإصدار الحالي: v$version',
            style: GoogleFonts.rubik(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (hasRelease)
                  _DownloadCard(
                    icon: Icons.android,
                    platform: 'تطبيق الأندرويد (Android APK)',
                    onDownload: () => _launchUrl(apkUrl),
                    brightness: Theme.of(context).brightness,
                  ),
                _DownloadCard(
                  icon: Icons.terminal,
                  platform: 'نسخة لينكس (Linux Package)',
                  onDownload: () => _launchUrl(
                    'https://github.com/hamzaelaiyat/ArabiLogia/releases/latest',
                  ),
                  isExternal: true,
                  brightness: Theme.of(context).brightness,
                ),
              ],
            ),
            if (!hasRelease && _hasError) ...[
              const SizedBox(height: 24),
              Icon(
                Icons.cloud_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'تعذر الاتصال بسيرفر التحديثات',
                style: GoogleFonts.vazirmatn(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _fetchRelease,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: isDark ? const Color(0xFF212325) : const Color(0xFFEDF2F8),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo-removedbg.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'عربيلوجيا هي منصة تعليمية غير ربحية تهدف لتبسيط ودعم تعلم اللغة العربية لطلاب المرحلة الثانوية باستخدام التكنولوجيا الحديثة.',
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _footerLink(context, 'الرئيسية', () {}),
              _footerLink(context, 'المميزات', () => _scrollTo(_featuresKey)),
              _footerLink(context, 'التحميل', () => _scrollTo(_downloadKey)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _footerLink(context, 'المشروع على GitHub', () {
                _launchUrl('https://github.com/hamzaelaiyat/ArabiLogia');
              }),
              _footerLink(context, 'حمزة العياط', () {
                _launchUrl('https://github.com/hamzaelaiyat');
              }),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} عربيلوجيا. جميع الحقوق محفوظة.',
            style: GoogleFonts.rubik(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _footerLink(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.rubik(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _NavLinks extends StatefulWidget {
  final VoidCallback onFeaturesTap;
  final VoidCallback onDownloadTap;

  const _NavLinks({
    required this.onFeaturesTap,
    required this.onDownloadTap,
  });

  @override
  State<_NavLinks> createState() => _NavLinksState();
}

class _NavLinksState extends State<_NavLinks> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _link('الرئيسية', 0, () {
          setState(() => _activeIndex = 0);
        }),
        const SizedBox(width: 24),
        _link('المميزات', 1, () {
          setState(() => _activeIndex = 1);
          widget.onFeaturesTap();
        }),
        const SizedBox(width: 24),
        _link('التحميل', 2, () {
          setState(() => _activeIndex = 2);
          widget.onDownloadTap();
        }),
      ],
    );
  }

  Widget _link(String label, int index, VoidCallback onTap) {
    final active = _activeIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: active ? label.length * 9.0 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final Brightness brightness;

  const _FeatureCard({required this.feature, required this.brightness});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: _hovered
            ? (Matrix4.identity()..setTranslationRaw(0, -8, 0))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191B1D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.5)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: _hovered ? 0.12 : 0.06),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF212325)
                    : const Color(0xFFEDF2F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.feature.icon,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.feature.title,
              style: GoogleFonts.rubik(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.feature.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final IconData icon;
  final String platform;
  final VoidCallback onDownload;
  final bool isExternal;
  final Brightness brightness;

  const _DownloadCard({
    required this.icon,
    required this.platform,
    required this.onDownload,
    this.isExternal = false,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDownload,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF212325) : const Color(0xFFEDF2F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                platform,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExternal ? Icons.open_in_new : Icons.download,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
