import 'dart:async';

import 'package:flutter/services.dart';

class NotificationChannel {
  static const MethodChannel _methodChannel =
      MethodChannel('notilog/native');
  static const EventChannel _eventChannel =
      EventChannel('notilog/notifications');

  Stream<Map<String, dynamic>> get notificationStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return map;
    });
  }

  Future<bool> isNotificationAccessEnabled() async {
    final result =
        await _methodChannel.invokeMethod<bool>('isNotificationAccessEnabled');
    return result ?? false;
  }

  Future<void> openNotificationAccessSettings() async {
    await _methodChannel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<List<Map<String, dynamic>>> drainNativeBuffer() async {
    final result =
        await _methodChannel.invokeMethod<List<dynamic>>('drainNotificationBuffer');
    if (result == null) {
      return [];
    }
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
