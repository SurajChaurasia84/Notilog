import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_entry.dart';
import 'notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);

  final NotificationRepository _repository;
  StreamSubscription<NotificationEntry>? _subscription;
  Timer? _pruneTimer;

  List<NotificationEntry> _all = [];
  List<NotificationEntry> _filtered = [];
  String _query = '';
  String? _appFilter;
  AppCategoryFilter _categoryFilter = AppCategoryFilter.all;

  List<NotificationEntry> get notifications => _filtered;
  AppCategoryFilter get categoryFilter => _categoryFilter;

  List<String> get appNames =>
      _all.map((e) => e.appName).where((e) => e.isNotEmpty).toSet().toList()
        ..sort();

  String? get appFilter => _appFilter;

  void setCategoryFilter(AppCategoryFilter filter) {
    _categoryFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  Future<void> initialize() async {
    await _repository.pruneExpired();
    _all = _repository.getAllSorted();
    _applyFilters();
    await _repository.initialize();
    _subscription?.cancel();
    _subscription = _repository.liveStream.listen((entry) {
      _all.insert(0, entry);
      _applyFilters();
      notifyListeners();
    });
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _repository.pruneExpired();
      await refreshFromRepository();
    });
  }

  Future<void> refreshFromRepository() async {
    _all = _repository.getAllSorted();
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _query = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void setFilters({String? appName}) {
    _appFilter = (appName == null || appName.isEmpty) ? null : appName;
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteEntry(NotificationEntry entry) async {
    await _repository.deleteEntry(entry);
    _all.removeWhere((e) => e.id == entry.id);
    _applyFilters();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _all.clear();
    _applyFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _pruneTimer?.cancel();
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  void _applyFilters() {
    Iterable<NotificationEntry> items = _all;
    if (_appFilter != null) {
      items = items.where((e) => e.appName == _appFilter);
    }
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      items = items.where((e) =>
          e.title.toLowerCase().contains(lower) ||
          e.message.toLowerCase().contains(lower));
    }
    items = _applyCategoryFilter(items);
    _filtered = items.toList();
  }

  Iterable<NotificationEntry> _applyCategoryFilter(
    Iterable<NotificationEntry> items,
  ) {
    switch (_categoryFilter) {
      case AppCategoryFilter.all:
        return items;
      case AppCategoryFilter.allApps:
        return items.where((e) => !_isSystemPackage(e.packageName));
      case AppCategoryFilter.systemApps:
        return items.where((e) => _isSystemPackage(e.packageName));
      case AppCategoryFilter.other:
        return items.where((e) => _isOtherCategory(e));
    }
  }

  bool _isOtherCategory(NotificationEntry entry) {
    final packageName = entry.packageName.toLowerCase();
    final title = entry.title.toLowerCase();
    final message = entry.message.toLowerCase();
    final appName = entry.appName.toLowerCase();
    final content = '$appName $title $message';

    const packageHints = [
      'android',
      'com.android',
      'com.google.android',
      'com.samsung.android',
      'com.miui',
      'com.oneplus',
      'com.oppo',
      'com.vivo',
      'com.huawei',
      'com.motorola',
      'com.realme',
      'com.coloros',
      'com.android.systemui',
      'com.google.android.systemui',
      'com.android.settings',
      'com.google.android.settings',
      'com.mi.android.globalfileexplorer',
      'com.google.android.apps.nbu.files',
      'com.android.documentsui',
      'com.android.permissioncontroller',
      'com.google.android.permissioncontroller',
    ];

    const notificationHints = [
      'low battery',
      'battery low',
      'battery saver',
      'power saving',
      'data saver',
      'focus mode',
      'do not disturb',
      'charging',
      'charged',
      'charger connected',
      'charger disconnected',
      'usb connected',
      'usb debugging',
      'bluetooth',
      'hotspot',
      'portable hotspot',
      'wifi hotspot',
      'mobile hotspot',
      'tethering',
      'device control',
      'system ui',
      'android system',
      'screenshot',
      's-capture',
      'file saved',
      'screen shot',
      'screen capture',
      'captured screen',
      'recording',
      'screen recording',
      'screen recorder',
      'record screen',
      'display over other apps',
      'running in background',
      'background activity',
      'background apps',
      'active in background',
      'floating window',
      'overlay',
      'permissions in use',
      'microphone in use',
      'camera in use',
      'clipboard',
      'copied to clipboard',
      'cast',
      'casting',
      'nearby share',
      'quick share',
      'download complete',
      'file received',
      'usb preferences',
    ];

    final matchesPackage =
        packageHints.any((prefix) => packageName.startsWith(prefix));
    final matchesContent =
        notificationHints.any((keyword) => content.contains(keyword));

    return matchesPackage && matchesContent;
  }

  bool _isSystemPackage(String packageName) {
    final lower = packageName.toLowerCase();
    const prefixes = [
      'android',
      'com.android',
      'com.google.android',
      'com.samsung.android',
      'com.miui',
      'com.oneplus',
      'com.oppo',
      'com.vivo',
      'com.huawei',
      'com.motorola',
      'com.lenovo',
      'com.realme',
      'com.coloros',
    ];
    return prefixes.any((prefix) => lower.startsWith(prefix));
  }
}

enum AppCategoryFilter { all, allApps, systemApps, other }
