import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/timer/presentation/pages/timer_page.dart';
import 'features/timer/presentation/controllers/timer_controller.dart';
import 'features/timer/presentation/providers/theme_provider.dart';
import 'features/timer/domain/services/app_rating_service.dart';
import 'features/timer/domain/services/audio_service.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Register dependencies - must be done before using any GetIt.I
  await setupDependencies();

  // Configure screen orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appRatingService = AppRatingService();
  appRatingService.checkAndRequestReview();

  runApp(
    ProviderScope(
      overrides: [
        // Override the sharedPreferences provider
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CountdownApp(),
    ),
  );
}

Future<void> setupDependencies() async {
  // Register AudioPlayerService as a singleton
  final audioService = await AudioPlayerService.create();
  getIt.registerSingleton<AudioPlayerService>(audioService);

  // Register TimerController factory that accepts a ref parameter
  getIt.registerFactoryParam<TimerController, Ref, void>(
    (ref, _) => TimerController(ref),
  );
}

class CountdownApp extends ConsumerWidget {
  const CountdownApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme mode
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Gym Timer',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const TimerPage(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      scaffoldBackgroundColor: Colors.grey[850],
      cardTheme: CardTheme(
        elevation: 4,
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}
