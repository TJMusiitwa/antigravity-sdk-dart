import 'dart:async';
import 'triggers.dart';
import '../connections/connection.dart';

/// Manages registration, startup, and shutdown of triggers.
class TriggerRunner {
  final List<Trigger> _triggers;
  final Connection _connection;
  final List<TriggerContext> _contexts = [];
  final List<Future<void>> _tasks = [];
  bool _isRunning = false;

  TriggerRunner({
    required List<Trigger> triggers,
    required Connection connection,
  }) : _triggers = List.from(triggers),
       _connection = connection;

  /// True if triggers are active and running.
  bool get isRunning => _isRunning;

  /// Starts all triggers as concurrent futures.
  Future<void> start() async {
    if (_isRunning) {
      throw StateError("TriggerRunner is already started.");
    }
    _isRunning = true;

    for (final trigger in _triggers) {
      final ctx = TriggerContext(_connection);
      _contexts.add(ctx);

      final task = () async {
        try {
          await trigger(ctx);
        } catch (e) {
          // Unhandled exceptions are swallowed/logged to not crash the session
        }
      }();
      _tasks.add(task);
    }
  }

  /// Cancels all trigger tasks and waits for them to finish.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;

    for (final ctx in _contexts) {
      ctx.cancel();
    }

    // Wait for all tasks to settle
    await Future.wait(_tasks);

    _contexts.clear();
    _tasks.clear();
  }
}
