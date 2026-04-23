import 'dart:io';
import 'dart:async';

class ClipboardManager {
  String _lastClipboardContent = '';
  Timer? _timer;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get clipboardStream => _controller.stream;

  void startWatching({Duration interval = const Duration(microseconds: 100)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final currentContent = await _read();
      if (currentContent != _lastClipboardContent) {
        _lastClipboardContent = currentContent;
        _controller.add(currentContent);
      }
    });
  }

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

  Future<void> push(String text) async {
    _lastClipboardContent = text;
    if (Platform.isWindows) {
      await Process.run('powershell', [
        '-Command',
        'Set-Clipboard -Value "$text"',
      ]);
    } else if (Platform.isLinux) {
      final process = await Process.start('xclip', ['-selection', 'clipboard']);
      process.stdin.write(text);
      await process.stdin.close();
    }
  }

  void stopWatching() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
