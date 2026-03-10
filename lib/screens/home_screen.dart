import 'package:flutter/material.dart';

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
            title: const Text('Notification History'),
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
                    : () async {
                        await widget.controller.clearAll();
                      },
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
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search notifications',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? const EmptyState()
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final entry = notifications[index];
                          return NotificationTile(
                            entry: entry,
                            onTap: () => _openDetail(context, entry),
                            onDelete: () =>
                                widget.controller.deleteEntry(entry),
                          );
                        },
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
}
