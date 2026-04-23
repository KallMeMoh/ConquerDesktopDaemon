import 'dart:io';
import 'dart:ffi';

import 'package:dbus/dbus.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

class NotificationService {
  static Future<void> show(String title, String content) async {
    if (Platform.isWindows) {
      _showWindowsNotification(title, content);
    } else if (Platform.isLinux) {
      await _showLinuxNotification(title, content);
    }
  }

  static void _showWindowsNotification(String title, String content) {
    final script = """
    \$ErrorActionPreference = 'Stop'
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
    \$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
    \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(\$template)
    \$nodes = \$xml.GetElementsByTagName('text')
    \$titleNode = \$nodes.Item(0)
    \$messageNode = \$nodes.Item(1)
    \$titleNode.AppendChild(\$xml.CreateTextNode('$title')) | Out-Null
    \$messageNode.AppendChild(\$xml.CreateTextNode('$content')) | Out-Null
    \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
    \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Conquer')
    \$notifier.Show(\$toast)
    """;

    final result = Process.runSync(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-Command', script],
    );

    if (result.exitCode != 0) {
      print('Error: ${result.stderr}');
    }
  }


  static Future<void> _showLinuxNotification(
    String title,
    String content,
  ) async {
    final client = DBusClient.session();
    try {
      final object = DBusRemoteObject(
        client,
        name: 'org.freedesktop.Notifications',
        path: DBusObjectPath('/org/freedesktop/Notifications'),
      );

      await object.callMethod('org.freedesktop.Notifications', 'Notify', [
        DBusString('Conquer'),
        DBusUint32(0),
        DBusString(''),
        DBusString(title),
        DBusString(content),
        DBusArray(DBusSignature('s')),
        DBusDict(DBusSignature('s'), DBusSignature('v')),
        DBusInt32(5000),
      ]);
    } finally {
      await client.close();
    }
  }
}
