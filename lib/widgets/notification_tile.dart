import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_entry.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: _AppIcon(iconBytes: entry.appIcon, fallback: entry.appName),
        title: Text(
          entry.title.isEmpty ? entry.appName : entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTime(entry.dateTime),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;
    if (isToday) {
      return DateFormat('h:mm a').format(time);
    }
    return DateFormat('MMM d').format(time);
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.iconBytes, required this.fallback});

  final Uint8List? iconBytes;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (iconBytes != null) {
      return CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceVariant,
        child: ClipOval(
          child: Image.memory(
            iconBytes!,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    final fallbackChar = fallback.isNotEmpty ? fallback[0].toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: theme.colorScheme.surfaceVariant,
      child: Text(
        fallbackChar,
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}
