import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/notification_entry.dart';
import 'notification_channel.dart';

class NotificationRepository {
  NotificationRepository({NotificationChannel? channel})
      : _channel = channel ?? NotificationChannel();

  final NotificationChannel _channel;
  final StreamController<NotificationEntry> _liveController =
      StreamController.broadcast();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  Box<NotificationEntry> get _box => HiveBoxes.notificationsBox();

  Stream<NotificationEntry> get liveStream => _liveController.stream;

  Future<void> initialize() async {
    _subscription?.cancel();
    _subscription = _channel.notificationStream.listen((payload) async {
      final entry = await _storeFromPayload(payload);
      if (entry != null) {
        _liveController.add(entry);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _liveController.close();
  }

  Future<void> drainNativeBuffer() async {
    final items = await _channel.drainNativeBuffer();
    for (final payload in items) {
      await _storeFromPayload(payload);
    }
  }

  List<NotificationEntry> getAllSorted() {
    final values = _box.values.toList();
    values.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return values;
  }

  Future<void> deleteEntry(NotificationEntry entry) async {
    await _box.delete(entry.id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<NotificationEntry?> _storeFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final id = payload['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }
    if (_box.containsKey(id)) {
      return null;
    }
    final appName = (payload['appName'] ?? '').toString();
    final packageName = (payload['packageName'] ?? '').toString();
    final title = (payload['title'] ?? '').toString();
    final message = (payload['message'] ?? '').toString();
    final timestamp = _parseTimestamp(payload['timestamp']);
    final iconBytes = _parseIconBytes(payload['appIcon']);

    final entry = NotificationEntry(
      id: id,
      appName: appName,
      packageName: packageName,
      title: title,
      message: message,
      timestamp: timestamp,
      appIcon: iconBytes,
    );
    await _box.put(entry.id, entry);
    return entry;
  }

  int _parseTimestamp(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  Uint8List? _parseIconBytes(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Uint8List) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      try {
        return base64Decode(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
