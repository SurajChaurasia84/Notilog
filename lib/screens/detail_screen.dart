import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_entry.dart';
import '../services/notification_channel.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.entry});

  final NotificationEntry entry;

  @override
  Widget build(BuildContext context) {
    final timestamp =
        DateFormat('MMM d, yyyy • h:mm a').format(entry.dateTime);
    return Scaffold(
      appBar: AppBar(
        // elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            if (entry.appIcon != null)
              ClipOval(
                child: Image.memory(
                  entry.appIcon!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              )
            else
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: Text(
                  entry.appName.isNotEmpty
                      ? entry.appName[0].toUpperCase()
                      : '?',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _launchApp(context),
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open ${entry.appName}',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title.isEmpty ? entry.appName : entry.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              entry.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              timestamp,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchApp(BuildContext context) async {
    final channel = NotificationChannel();
    try {
      await channel.launchApp(entry.packageName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${entry.appName}')),
        );
      }
    }
  }
}
