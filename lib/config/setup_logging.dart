import 'package:logging/logging.dart';

void setupLogging() {
  // Configure logging levels
  Logger.root.level = Level.ALL; // Capture all log levels

  // Set up log handler
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: '
        '${record.time}: '
        '${record.message}');
  });
}