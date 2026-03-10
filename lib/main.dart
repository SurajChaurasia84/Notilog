import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Notification History',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
