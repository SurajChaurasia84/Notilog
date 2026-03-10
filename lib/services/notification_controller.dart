import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_entry.dart';
import 'notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);

  final NotificationRepository _repository;
  StreamSubscription<NotificationEntry>? _subscription;

  List<NotificationEntry> _all = [];
  List<NotificationEntry> _filtered = [];
  String _query = '';
  String? _appFilter;
  String? _packageFilter;
  TimeFilter _timeFilter = TimeFilter.more;

  List<NotificationEntry> get notifications => _filtered;
  TimeFilter get timeFilter => _timeFilter;

  List<String> get appNames =>
      _all.map((e) => e.appName).where((e) => e.isNotEmpty).toSet().toList()
        ..sort();

  List<String> get packageNames => _all
      .map((e) => e.packageName)
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  String? get appFilter => _appFilter;
  String? get packageFilter => _packageFilter;

  void setTimeFilter(TimeFilter filter) {
    _timeFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  Future<void> initialize() async {
    _all = _repository.getAllSorted();
    _applyFilters();
    await _repository.initialize();
    _subscription?.cancel();
    _subscription = _repository.liveStream.listen((entry) {
      _all.insert(0, entry);
      _applyFilters();
      notifyListeners();
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

  void setFilters({String? appName, String? packageName}) {
    _appFilter = (appName == null || appName.isEmpty) ? null : appName;
    _packageFilter =
        (packageName == null || packageName.isEmpty) ? null : packageName;
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
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  void _applyFilters() {
    Iterable<NotificationEntry> items = _all;
    if (_appFilter != null) {
      items = items.where((e) => e.appName == _appFilter);
    }
    if (_packageFilter != null) {
      items = items.where((e) => e.packageName == _packageFilter);
    }
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      items = items.where((e) =>
          e.title.toLowerCase().contains(lower) ||
          e.message.toLowerCase().contains(lower));
    }
    items = _applyTimeFilter(items);
    _filtered = items.toList();
  }

  Iterable<NotificationEntry> _applyTimeFilter(
    Iterable<NotificationEntry> items,
  ) {
    if (_timeFilter == TimeFilter.recent) {
      return items.take(10);
    }
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = todayStart.add(const Duration(days: 2));

    switch (_timeFilter) {
      case TimeFilter.today:
        return items.where((e) =>
            e.dateTime.isAfter(todayStart) &&
            e.dateTime.isBefore(tomorrowStart));
      case TimeFilter.tomorrow:
        return items.where((e) =>
            e.dateTime.isAfter(tomorrowStart) &&
            e.dateTime.isBefore(dayAfterTomorrowStart));
      case TimeFilter.more:
        return items.where((e) => e.dateTime.isBefore(todayStart));
      case TimeFilter.recent:
        return items;
    }
  }
}

enum TimeFilter { recent, today, tomorrow, more }
