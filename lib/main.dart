import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:arabilogia/core/theme/app_theme.dart';
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/constants/app_version.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/services/update_service.dart';
import 'package:arabilogia/core/widgets/splash_screen.dart';
import 'package:arabilogia/core/widgets/whats_new_dialog.dart';
import 'package:arabilogia/core/widgets/offline_banner.dart';
import 'package:arabilogia/features/auth/update_confirm/screens/update_confirm_page.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/exams/providers/exam_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/admin/providers/teacher_exam_defaults_provider.dart';
import 'package:arabilogia/features/dashboard/profile/providers/accounts_provider.dart';
import 'package:arabilogia/providers/contextual_sidebar_provider.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Load environment, Supabase and any shared non-UI dependencies.
///
/// Patrol tests call this directly; the Flutter binding is managed by
/// Patrol's own binding layer.  Set [skipBinding] to `true` when
/// Patrol's binding already initialized [WidgetsFlutterBinding].
Future<void> initializeApp({
  bool enableAds = true,
  bool skipBinding = false,
}) async {
  if (!skipBinding) {
    WidgetsFlutterBinding.ensureInitialized();
  }
  if (kIsWeb) usePathUrlStrategy();

  // The bundled `.env` is a convenience for local runs and mobile builds. On
  // web the host strips dotfiles, so the file is never served and the values
  // come from --dart-define instead. Only read the file when we still need it,
  // and never let a failure here stop the app from starting.
  if (!SupabaseConfig.isConfigured) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // Ignored: SupabaseConfig falls back to a placeholder.
    }
  }
  await AppVersion.preload();

  if (enableAds &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    unawaited(_initializeMobileAds());
  }

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
}

void main() async {
  await initializeApp();
  runApp(const ArabiLogiaApp());
}

Future<void> _initializeMobileAds() async {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      // Ignore mobile ads initialization errors when unavailable
    }
  }
}

class ArabiLogiaApp extends StatefulWidget {
  const ArabiLogiaApp({super.key});

  @override
  State<ArabiLogiaApp> createState() => _ArabiLogiaAppState();
}

class _ArabiLogiaAppState extends State<ArabiLogiaApp> {
  StreamSubscription<AppUpdate?>? _updateSubscription;
  bool _providersInitialized = false;

  // Boot-splash readiness gates. The branded splash stays up until the app has
  // resolved its first destination (dashboard, teacher dashboard, or the
  // update screen) and a minimum display time has elapsed.
  bool _providersDone = false;
  bool _routeSettled = false;
  bool _minDelayElapsed = false;
  bool _appReady = false;
  Timer? _splashTimer;

  static const Duration _splashMinDuration = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    _updateSubscription = UpdateService.updateStream.listen((update) {
      if (update != null && mounted) {
        _showUpdateDialog(update);
      }
    });
    AppRouter.router.routerDelegate.addListener(_onRouterChanged);
    _splashTimer = Timer(_splashMinDuration, () {
      _minDelayElapsed = true;
      _maybeReleaseBootSplash();
    });
  }

  void _onRouterChanged() {
    final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (path.isNotEmpty && path != '/') {
      _routeSettled = true;
      _maybeReleaseBootSplash();
      _flushPendingUpdate();
    }
  }

  void _maybeReleaseBootSplash() {
    if (_appReady || !mounted) return;
    if (_providersDone && _routeSettled && _minDelayElapsed) {
      setState(() => _appReady = true);
      // Now that the splash is off, anything detected during boot can actually
      // be seen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingUpdate());
    }
  }

  Future<void> _initializeHeavyProviders(BuildContext context) async {
    if (_providersInitialized) return;
    _providersInitialized = true;

    final authProvider = context.read<AuthProvider>();
    final potatoProvider = context.read<PotatoModeProvider>();
    final teacherDefaultsProvider = context.read<TeacherExamDefaultsProvider>();

    await Future.wait([
      authProvider.initializeAfterSupabase(),
      potatoProvider.initialize(),
      teacherDefaultsProvider.loadDefaults(),
      GradeMetadata.loadGrades(),
      CategoryMetadata.loadCategories(),
    ]);

    if (!context.mounted) return;

    AppRouter.router.refresh();

    // Wait for any pending update decision before releasing the splash, so the
    // user lands directly on the update screen instead of the dashboard.
    if (authProvider.state.isAuthenticated &&
        !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux)) {
      await UpdateService.checkForUpdatesInBackground();
    }

    _providersDone = true;
    _maybeReleaseBootSplash();
    _checkWhatsNew();
    // Safety net in case the router listener never fired for the current path.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeReleaseBootSplash(),
    );
  }

  Future<void> _checkWhatsNew() async {
    final show = await UpdateService.shouldShowWhatsNew();
    if (show) {
      final notes = await UpdateService.getWhatsNewNotes();
      final version = await UpdateService.getCurrentVersion();
      final navContext =
          AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      showDialog(
        context: navContext,
        builder: (dialogCtx) => WhatsNewDialog(
          version: version,
          releaseNotes: notes,
          onDismiss: () => UpdateService.dismissWhatsNew(),
        ),
      );
    }
  }

  void _showUpdateDialog(AppUpdate update) {
    final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) {
      // The check can finish while the navigator is still being built. Keep the
      // update instead of dropping it: it is retried on the next route change
      // and after the boot splash is released.
      // Kept in UpdateService until a screen can host it.
      return;
    }

    // Don't interrupt auth screens
    final routerState = AppRouter.router.routerDelegate.currentConfiguration;
    final currentPath = routerState.uri.toString();
    if (currentPath == AppRoutes.login ||
        currentPath == AppRoutes.register ||
        currentPath == AppRoutes.forgotPassword) {
      // Kept in UpdateService until a screen can host it.
      return;
    }


    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateConfirmPage(update: update),
      ),
    );
  }

  /// Push a still-pending update once we are on a screen that can host it.
  void _flushPendingUpdate() {
    if (!mounted || !_appReady) return;
    if (!_isUpdateRouteSafe()) return;
    final pending = UpdateService.takePendingUpdate();
    if (pending == null) return;
    _showUpdateDialog(pending);
  }

  bool _isUpdateRouteSafe() {
    final currentPath =
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
    return currentPath != AppRoutes.login &&
        currentPath != AppRoutes.register &&
        currentPath != AppRoutes.forgotPassword;
  }


  @override
  void dispose() {
    _updateSubscription?.cancel();
    _splashTimer?.cancel();
    AppRouter.router.routerDelegate.removeListener(_onRouterChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ExamProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => PotatoModeProvider(), lazy: true),
        ChangeNotifierProvider(
          create: (_) => TeacherExamDefaultsProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (_) => AccountsProvider(), lazy: true),
        ChangeNotifierProvider(
          create: (_) => ContextualSidebarProvider(),
          lazy: true,
        ),
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeHeavyProviders(context);
          });

          // Mount MaterialApp.router from the very first frame. Using a
          // plain MaterialApp (spinner) while auth initializes lets the
          // framework normalize the URL to "/", which made go_router boot
          // at the wrong location on cold deep links (e.g. /gate).
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp.router(
                title: 'عربيلوجيا',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeProvider.themeMode,
                routerConfig: AppRouter.router,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  final scale = mediaQuery.textScaler.scale(1.0);
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(scale.clamp(0.85, 1.3)),
                    ),
                    child: Stack(
                      children: [
                        OfflineBanner(child: child ?? const SizedBox.shrink()),
                        if (!_appReady)
                          const Positioned.fill(child: SplashScreen()),
                      ],
                    ),
                  );
                },
                locale: const Locale('ar'),
                supportedLocales: const [Locale('ar')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
