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
    final nid = calloc<NOTIFYICONDATA>();
    try {
      nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
      nid.ref.hWnd = GetDesktopWindow();
      nid.ref.uID = 1;
      nid.ref.uFlags = NIF_INFO;
      nid.ref.dwInfoFlags = NIIF_INFO;
      nid.ref.szInfoTitle = title;
      nid.ref.szInfo = content;

      Shell_NotifyIcon(NIM_ADD, nid);
    } finally {
      free(nid);
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
