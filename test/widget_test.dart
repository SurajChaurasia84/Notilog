import 'package:flutter_test/flutter_test.dart';

import 'package:notilog/main.dart';
import 'package:notilog/models/notification_entry.dart';
import 'package:notilog/services/notification_controller.dart';
import 'package:notilog/services/notification_repository.dart';

void main() {
  testWidgets('renders home screen shell', (WidgetTester tester) async {
    final controller = NotificationController(_FakeNotificationRepository());

    await tester.pumpWidget(NotificationHistoryApp(controller: controller));
    await tester.pump();

    expect(find.text('Notilog'), findsOneWidget);
    expect(find.text('Search notifications'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('System Apps'), findsOneWidget);
    expect(find.text('Others'), findsOneWidget);
    expect(find.text('No notifications captured yet.'), findsOneWidget);
  });
}

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> drainNativeBuffer() async {}

  @override
  Future<void> pruneExpired() async {}

  @override
  List<NotificationEntry> getAllSorted() => [];
}
