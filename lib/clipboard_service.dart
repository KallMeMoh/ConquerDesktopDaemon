import 'dart:io';
import 'dart:async';

import 'package:logging/logging.dart';

class ClipboardService {
  String _lastClipboardContent = '';
  Timer? _timer;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  final Logger _logger = Logger('ClipboardService');

  Stream<String> get clipboardStream => _controller.stream;

  void startWatching() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 100), (_) async {
      try {
        final currentContent = await _read();
        if (currentContent != _lastClipboardContent) {
          _lastClipboardContent = currentContent;
          _controller.add(currentContent);
          _logger.info('$currentContent was polled from the clipboard');
        }
        _logger.info('Started polling clipboard');
      } catch (err) {
        _logger.severe(err);
      }
    });
  }

  Future<String> _read() async {
    ProcessResult result;
    try {
      if (Platform.isWindows) {
        result = await Process.run('powershell', ['-Command', 'Get-Clipboard']);
      } else if (Platform.isLinux) {
        result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
      } else {
        return '';
      }
      return result.stdout.toString().trim();
    } catch (err) {
      _logger.severe(err);
    }
    return '';
  }

  Future<void> push(String text) async {
    _lastClipboardContent = text;
    try {
      if (Platform.isWindows) {
        await Process.run('powershell', [
          '-Command',
          'Set-Clipboard -Value "$text"',
        ]);
      } else if (Platform.isLinux) {
        final process = await Process.start('xclip', [
          '-selection',
          'clipboard',
        ]);
        process.stdin.write(text);
        await process.stdin.close();
      }
    } catch (err) {
      _logger.severe(err);
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