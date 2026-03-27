import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/notification_entry.dart';
import '../services/notification_channel.dart';
import '../services/notification_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/notification_tile.dart';
import '../widgets/permission_banner.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final NotificationController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final NotificationChannel _channel = NotificationChannel();
  bool _permissionEnabled = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatus();
    _searchController.addListener(() {
      widget.controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStatus();
    }
  }

  Future<void> _loadPermissionStatus() async {
    final enabled = await _channel.isNotificationAccessEnabled();
    if (mounted) {
      setState(() => _permissionEnabled = enabled);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final notifications = widget.controller.notifications;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Image.asset(
                  'assets/bell.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notilog',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Filter',
                onPressed: () => _openFilters(context),
                icon: const Icon(Icons.filter_alt_outlined),
              ),
              IconButton(
                tooltip: 'Clear all',
                onPressed: notifications.isEmpty
                    ? null
                    : () => _confirmClearAll(context),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              if (!_permissionEnabled)
                PermissionBanner(
                  onEnable: _channel.openNotificationAccessSettings,
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search notifications',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              _CategoryTabs(
                value: widget.controller.categoryFilter,
                onChanged: widget.controller.setCategoryFilter,
              ),
              Expanded(
                child: notifications.isEmpty
                    ? const EmptyState()
                    : SlidableAutoCloseBehavior(
                        child: ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final entry = notifications[index];
                            return NotificationTile(
                              entry: entry,
                              onTap: () => _openDetail(context, entry),
                              onDelete: () => _confirmDelete(context, entry),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, NotificationEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(entry: entry),
      ),
    );
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => FilterSheet(
        appNames: widget.controller.appNames,
        packageNames: widget.controller.packageNames,
        selectedApp: widget.controller.appFilter,
        selectedPackage: widget.controller.packageFilter,
        onApply: (app, packageName) {
          widget.controller.setFilters(appName: app, packageName: packageName);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NotificationEntry entry,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true) {
      await widget.controller.deleteEntry(entry);
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history'),
        content: const Text('Delete all stored notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (result == true) {
      await widget.controller.clearAll();
    }
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.value,
    required this.onChanged,
  });

  final AppCategoryFilter value;
  final ValueChanged<AppCategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildTab(theme, AppCategoryFilter.all, 'All'),
          _buildTab(theme, AppCategoryFilter.allApps, 'Installed'),
          _buildTab(theme, AppCategoryFilter.systemApps, 'System Apps'),
          _buildTab(theme, AppCategoryFilter.other, 'Others'),
        ],
      ),
    );
  }

  Widget _buildTab(
    ThemeData theme,
    AppCategoryFilter filter,
    String label,
  ) {
    final selected = value == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
