import 'dart:typed_data';

import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class NotificationEntry extends HiveObject {
  NotificationEntry({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.title,
    required this.message,
    required this.timestamp,
    this.appIcon,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String appName;

  @HiveField(2)
  final String packageName;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String message;

  @HiveField(5)
  final int timestamp;

  @HiveField(6)
  final Uint8List? appIcon;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

class NotificationEntryAdapter extends TypeAdapter<NotificationEntry> {
  @override
  final int typeId = 1;

  @override
  NotificationEntry read(BinaryReader reader) {
    final id = reader.readString();
    final appName = reader.readString();
    final packageName = reader.readString();
    final title = reader.readString();
    final message = reader.readString();
    final timestamp = reader.readInt();
    final hasIcon = reader.readBool();
    final icon = hasIcon ? reader.readByteList() : null;
    return NotificationEntry(
      id: id,
      appName: appName,
      packageName: packageName,
      title: title,
      message: message,
      timestamp: timestamp,
      appIcon: icon,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationEntry obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.appName);
    writer.writeString(obj.packageName);
    writer.writeString(obj.title);
    writer.writeString(obj.message);
    writer.writeInt(obj.timestamp);
    if (obj.appIcon == null) {
      writer.writeBool(false);
    } else {
      writer.writeBool(true);
      writer.writeByteList(obj.appIcon!);
    }
  }
}
