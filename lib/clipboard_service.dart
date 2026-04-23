import 'dart:io';
import 'dart:async';

class ClipboardManager {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get clipboardStream => _controller.stream;

  Future<String> _read() async {
    ProcessResult result;
    if (Platform.isWindows) {
      result = await Process.run('powershell', ['-Command', 'Get-Clipboard']);
    } else if (Platform.isLinux) {
      result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
    } else {
      return '';
    }
    return result.stdout.toString().trim();
  }
}
