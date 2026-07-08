import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer =
        StringBuffer()
          ..write(time.toIso8601String())
          ..write(' [')
          ..write(level.name.toUpperCase())
          ..write('] ')
          ..write(tag)
          ..write(': ')
          ..write(message);
    if (error != null) {
      buffer.write(' | error: $error');
    }
    return buffer.toString();
  }
}

/// Structured, leveled logger. Single entry point for all app logging —
/// feature code must not call print/debugPrint directly.
///
/// Keeps a bounded in-memory buffer so recent history can be attached to
/// error reports in production, where console output is unavailable.
class AppLogger {
  AppLogger._();

  static const int _bufferLimit = 500;
  static final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Minimum level that gets recorded. Debug builds see everything;
  /// release builds skip debug-level noise.
  static LogLevel minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  static List<LogEntry> get recentEntries => List.unmodifiable(_buffer);

  @visibleForTesting
  static void clearBuffer() => _buffer.clear();

  static void debug(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void warning(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _log(LogLevel.warning, tag, message, error, stackTrace);

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _log(LogLevel.error, tag, message, error, stackTrace);

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (level.index < minLevel.index) {
      return;
    }

    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    _buffer.addLast(entry);
    if (_buffer.length > _bufferLimit) {
      _buffer.removeFirst();
    }

    developer.log(
      message,
      name: tag,
      time: entry.time,
      level: _developerLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _developerLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
