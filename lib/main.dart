import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/theme/app_theme.dart';
import 'package:arabilogia/core/config/supabase_config.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/services/update_service.dart';
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

  runApp(const ArabiLogiaApp());
}

class ArabiLogiaApp extends StatelessWidget {
  const ArabiLogiaApp({super.key});

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
          // Check for updates after app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Only check on Android
            if (Theme.of(context).platform == TargetPlatform.android) {
              UpdateService.checkForUpdates(context);
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
