import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/theme/app_theme.dart';
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/services/update_service.dart';
import 'package:arabilogia/features/auth/update_confirm/screens/update_confirm_page.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/exam_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();

  runApp(const ArabiLogiaApp());
}

class ArabiLogiaApp extends StatefulWidget {
  const ArabiLogiaApp({super.key});

  @override
  State<ArabiLogiaApp> createState() => _ArabiLogiaAppState();
}

class _ArabiLogiaAppState extends State<ArabiLogiaApp> {
  StreamSubscription<AppUpdate?>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _listenForUpdates();
    _checkWhatsNew();
  }

  Future<void> _checkWhatsNew() async {
    try {
      final shouldShow = await UpdateService.shouldShowWhatsNew();
      if (shouldShow && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final lastVersion = prefs.getString('installed_version');
        final whatsNewNotes = await UpdateService.getWhatsNewNotes();
        if (lastVersion != null) {
          _showWhatsNewDialog(lastVersion, whatsNewNotes);
        }
      }
    } catch (e) {
      debugPrint('Error checking for WhatsNew: $e');
    }
  }

  void _showWhatsNewDialog(String version, String releaseNotes) {
    final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !mounted) return;

    final notesContent = releaseNotes.isNotEmpty
        ? releaseNotes
        : '• تحسينات في الأداء\n• إصلاحات للأخطاء\n• تحسينات تجربة المستخدم';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFFEB8A00)),
            const SizedBox(width: 8),
            const Text('🎉 نسخة جديدة!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تم تحديث التطبيق إلى الإصدار $version'),
            const SizedBox(height: 12),
            const Text(
              'ما الجديد:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(notesContent, style: const TextStyle(height: 1.5)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              UpdateService.markAsInstalled(version);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB8A00),
            ),
            child: const Text('ممتاز!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _listenForUpdates() {
    _updateSubscription = UpdateService.updateStream.listen((update) {
      if (update != null && mounted) {
        _showUpdateDialog(update);
      }
    });
  }

  void _showUpdateDialog(AppUpdate update) {
    // Use the navigator to show the update page
    // We need to find the current navigator context
    final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UpdateConfirmPage(update: update),
        ),
      );
    }
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(
          create: (_) => PotatoModeProvider()..initialize(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Check for updates in background after app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Only check on Android/Windows/Linux
            if (Theme.of(context).platform == TargetPlatform.android ||
                Theme.of(context).platform == TargetPlatform.windows ||
                Theme.of(context).platform == TargetPlatform.linux) {
              UpdateService.checkForUpdatesInBackground();
            }
          });

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
      ),
    );
  }
}
