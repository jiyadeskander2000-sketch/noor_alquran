import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/quran_service.dart';
import 'services/audio_manager.dart';
import 'services/prayer_times_service.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage preferences
  await StorageService.init();

  // Preload Quran and Azkar datasets
  await QuranService.loadQuranData();

  // Initialize background prayer times & notifications service
  try {
    await PrayerTimesService.initialize();
    await PrayerTimesService.refreshNotificationsIfEnabled();
  } catch (e) {
    debugPrint('PrayerTimesService init warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioManager()),
      ],
      child: const NoorAlQuranApp(),
    ),
  );
}

class NoorAlQuranApp extends StatelessWidget {
  const NoorAlQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, child) {
        return MaterialApp(
          title: 'نور القرآن الكريم',
          debugShowCheckedModeBanner: false,
          themeMode: themeProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [
            Locale('ar', 'SA'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        );
      },
    );
  }
}
