import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';

void main(List<String> arguments) {
  String folderPath;

  if (Platform.isWindows) {
    folderPath = join(Platform.environment['APPDATA']!, 'my_daemon');
  } else {
    folderPath = join(
      Platform.environment['HOME']!,
      '.local',
      'share',
      'my_daemon',
    );
  }

  Directory(folderPath).createSync(recursive: true);

  final logPath = join(folderPath, 'log_file.log');

  Logger.root.onRecord.listen((record) {
    final file = File(logPath);
    file.writeAsStringSync(
      '${record.time}: [${record.level.name}] ${record.message}\n',
      mode: FileMode.append,
    );
  });
}
