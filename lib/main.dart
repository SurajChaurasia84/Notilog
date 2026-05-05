import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'database/hive_boxes.dart';
import 'models/notification_entry.dart';
import 'screens/home_screen.dart';
import 'services/notification_controller.dart';
import 'services/notification_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NotificationEntryAdapter());
  await Hive.openBox<NotificationEntry>(HiveBoxes.notifications);

  // Initialize Unity Ads
  UnityAds.init(
    gameId: '6090693',
    testMode: false,
    onComplete: () => print('Unity Ads Initialization Complete'),
    onFailed: (error, message) =>
        print('Unity Ads Initialization Failed: $error $message'),
  );

  final repository = NotificationRepository();
  await repository.drainNativeBuffer();
  final controller = NotificationController(repository);
  await controller.initialize();

  runApp(NotificationHistoryApp(controller: controller));
}

class NotificationHistoryApp extends StatelessWidget {
  const NotificationHistoryApp({super.key, required this.controller});

  final NotificationController controller;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6FE5);
    const transitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SmoothPageTransitionsBuilder(),
        TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
        TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
        TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
        TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
      },
    );
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        background: const Color(0xFFF4F6FA),
        surface: Colors.white,
        surfaceVariant: const Color(0xFFE9EEF6),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      pageTransitionsTheme: transitionsTheme,
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Notilog',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF4F6FA),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          background: const Color(0xFF0F131A),
          surface: const Color(0xFF161B24),
          surfaceVariant: const Color(0xFF202736),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F131A),
        pageTransitionsTheme: transitionsTheme,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: HomeScreen(controller: controller),
    );
  }
}

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.linear,
    );
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.85,
        end: 1,
      ).animate(curved),
      child: child,
    );
  }
}
