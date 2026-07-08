import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/logging/app_logger.dart';

void main() {
  setUp(() {
    AppLogger.clearBuffer();
    AppLogger.minLevel = LogLevel.debug;
  });

  test('records entries with level, tag and message', () {
    AppLogger.info('test', 'hello');

    expect(AppLogger.recentEntries, hasLength(1));
    final entry = AppLogger.recentEntries.single;
    expect(entry.level, LogLevel.info);
    expect(entry.tag, 'test');
    expect(entry.message, 'hello');
  });

  test('filters entries below minLevel', () {
    AppLogger.minLevel = LogLevel.warning;

    AppLogger.debug('test', 'skipped');
    AppLogger.info('test', 'skipped too');
    AppLogger.error('test', 'kept');

    expect(AppLogger.recentEntries, hasLength(1));
    expect(AppLogger.recentEntries.single.level, LogLevel.error);
  });

  test('buffer is bounded and drops oldest entries', () {
    for (var i = 0; i < 600; i++) {
      AppLogger.info('test', 'entry $i');
    }

    expect(AppLogger.recentEntries.length, 500);
    expect(AppLogger.recentEntries.first.message, 'entry 100');
    expect(AppLogger.recentEntries.last.message, 'entry 599');
  });
}
