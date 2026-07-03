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
import 'package:arabilogia/features/auth/update_confirm/screens/update_confirm_page.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/exams/providers/exam_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/admin/providers/teacher_exam_defaults_provider.dart';
import 'package:arabilogia/features/dashboard/profile/providers/accounts_provider.dart';
import 'package:arabilogia/features/dashboard/exams/models/grade_metadata.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();

  await dotenv.load(fileName: ".env");
  await AppVersion.preload();
  unawaited(_initializeMobileAds());

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  runApp(const ArabiLogiaApp());
}

Future<void> _initializeMobileAds() async {
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
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

  @override
  void initState() {
    super.initState();
    _updateSubscription = UpdateService.updateStream.listen((update) {
      if (update != null && mounted) {
        _showUpdateDialog(update);
      }
    });
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
    ]);

    if (mounted) {
      AppRouter.router.refresh();
    }

    // Check for updates only after auth is initialized
    if (authProvider.state.isAuthenticated &&
        !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.android ||
         Theme.of(context).platform == TargetPlatform.windows ||
         Theme.of(context).platform == TargetPlatform.linux)) {
      UpdateService.checkForUpdatesInBackground();
    }
  }

  void _showUpdateDialog(AppUpdate update) {
    final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    // Don't interrupt auth screens
    final routerState = AppRouter.router.routerDelegate.currentConfiguration;
    final currentPath = routerState.uri.toString();
    if (currentPath == AppRoutes.login ||
        currentPath == AppRoutes.register ||
        currentPath == AppRoutes.forgotPassword) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateConfirmPage(update: update),
      ),
    );
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => ExamProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => PotatoModeProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => TeacherExamDefaultsProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => AccountsProvider(),
          lazy: true,
        ),
      ],
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeHeavyProviders(context);
              });

              return Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (!authProvider.isInitialized) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light,
                      darkTheme: AppTheme.dark,
                      locale: const Locale('ar'),
                      home: const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  return Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return MaterialApp.router(
                    title: 'عربيلوجيا',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeProvider.themeMode,
                    routerConfig: AppRouter.router,
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
          );
        },
      ),
    );
  }
}
