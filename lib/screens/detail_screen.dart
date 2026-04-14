import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../models/notification_entry.dart';
import '../services/notification_channel.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.entry});

  final NotificationEntry entry;

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen>
    with WidgetsBindingObserver {
  bool _isBannerLoaded = false;
  int _externalReturnCount = 0;
  bool _isLaunchingApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLaunchingApp) {
      _isLaunchingApp = false;
      _externalReturnCount++;

      // Trigger ad logic: every 2nd return
      if (_externalReturnCount >= 2) {
        _externalReturnCount = 0;
        _showInterstitialAd();
      }
    }
  }

  void _loadInterstitialAd() {
    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) => print('Detail Ad Loaded'),
      onFailed: (placementId, error, message) => print('Detail Ad Failed: $error'),
    );
  }

  void _showInterstitialAd() {
    UnityAds.showVideoAd(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) {
        print('Detail Interstitial Finished');
      },
      onFailed: (placementId, error, message) => print('Detail Interstitial Failed'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp =
        DateFormat('MMM d, yyyy • h:mm a').format(widget.entry.dateTime);
    return Scaffold(
      appBar: AppBar(
        // elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            if (widget.entry.appIcon != null)
              ClipOval(
                child: Image.memory(
                  widget.entry.appIcon!,
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
                  widget.entry.appName.isNotEmpty
                      ? widget.entry.appName[0].toUpperCase()
                      : '?',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.entry.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _launchApp(context),
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open ${widget.entry.appName}',
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
              widget.entry.title.isEmpty ? widget.entry.appName : widget.entry.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              widget.entry.message,
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
      bottomNavigationBar: SizedBox(
        height: _isBannerLoaded ? 50 : 1,
        child: UnityBannerAd(
          placementId: 'Banner_Android',
          onLoad: (placementId) {
            if (mounted) setState(() => _isBannerLoaded = true);
          },
          onClick: (placementId) => print('Banner clicked: $placementId'),
          onFailed: (placementId, error, message) =>
              print('Banner ad $placementId failed: $error $message'),
        ),
      ),
    );
  }

  Future<void> _launchApp(BuildContext context) async {
    final channel = NotificationChannel();
    try {
      _isLaunchingApp = true;
      _loadInterstitialAd(); // Pre-load as soon as user decides to leave
      await channel.launchApp(widget.entry.packageName);
    } catch (e) {
      _isLaunchingApp = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${widget.entry.appName}')),
        );
      }
    }
  }
}
