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

  static const Duration retentionWindow = Duration(hours: 24);

  final NotificationChannel _channel;
  final StreamController<NotificationEntry> _liveController =
      StreamController.broadcast();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  Box<NotificationEntry> get _box => HiveBoxes.notificationsBox();

  Stream<NotificationEntry> get liveStream => _liveController.stream;

  Future<void> initialize() async {
    await pruneExpired();
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
    await pruneExpired();
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

  Future<void> pruneExpired() async {
    final cutoff = _cutoffTimestamp();
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final entry = _box.get(key);
      if (entry == null || entry.timestamp < cutoff) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
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
    if (timestamp < _cutoffTimestamp()) {
      return null;
    }
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
    await pruneExpired();
    return entry;
  }

  int _cutoffTimestamp() {
    return DateTime.now().subtract(retentionWindow).millisecondsSinceEpoch;
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
