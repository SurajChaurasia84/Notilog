import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_entry.dart';

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
        titleSpacing: 0,
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
}
