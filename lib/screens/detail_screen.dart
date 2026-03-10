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
        title: Text(entry.appName),
      ),
      body: Padding(
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
