import 'package:hive/hive.dart';

import '../models/notification_entry.dart';

class HiveBoxes {
  static const String notifications = 'notifications';

  static Box<NotificationEntry> notificationsBox() {
    return Hive.box<NotificationEntry>(notifications);
  }
}
