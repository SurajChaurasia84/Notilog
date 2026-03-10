import 'package:flutter/material.dart';

class PermissionBanner extends StatelessWidget {
  const PermissionBanner({
    super.key,
    required this.onEnable,
  });

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Enable notification access to start capturing history.',
              ),
            ),
            TextButton(
              onPressed: onEnable,
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }
}
