import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.appNames,
    required this.selectedApp,
    required this.onApply,
  });

  final List<String> appNames;
  final String? selectedApp;
  final void Function(String? appName) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _app;

  @override
  void initState() {
    super.initState();
    _app = widget.selectedApp;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'App Name',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _app,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All apps'),
                ),
                ...widget.appNames.map(
                  (name) => DropdownMenuItem<String?>(
                    value: name,
                    child: Text(name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _app = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _app = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_app);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
