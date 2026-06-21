import 'dart:async';
import 'dart:io';
import '../connections/connection.dart';
import '../types/file_change.dart';

/// Execution handle and context provided to every background trigger at startup in the Google Antigravity SDK.
class TriggerContext {
  final Connection _connection;
  bool _isCancelled = false;

  /// Creates a new [TriggerContext] instance wrapping the given [connection].
  TriggerContext(this._connection);

  /// Returns the active connection.
  Connection get connection => _connection;

  /// Returns true if the trigger runner has cancelled this trigger.
  bool get isCancelled => _isCancelled;

  /// Sends a trigger notification message to the agent.
  Future<void> send(String content) async {
    if (_isCancelled) return;
    await _connection.sendTriggerNotification(content);
  }

  /// Cancels the execution of the trigger.
  void cancel() {
    _isCancelled = true;
  }
}

/// A Trigger is any function that accepts a TriggerContext and runs asynchronously.
typedef Trigger = FutureOr<void> Function(TriggerContext context);

/// Helper factory that creates a trigger running a callback on a fixed interval.
Trigger every(
  Duration interval,
  FutureOr<void> Function(TriggerContext context) callback,
) {
  return (ctx) async {
    while (!ctx.isCancelled) {
      await Future.delayed(interval);
      if (ctx.isCancelled) break;
      try {
        await callback(ctx);
      } catch (e) {
        // Log/swallow callback errors to prevent loop termination
      }
    }
  };
}

/// Helper factory that creates a trigger watching for filesystem changes at the specified path.
///
/// Uses Dart's native `dart:io` [FileSystemEntity.watch] mechanism for OS-level events.
Trigger onFileChange(
  String path,
  FutureOr<void> Function(TriggerContext context, List<FileChange> changes)
      callback,
) {
  return (ctx) async {
    final entity =
        FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
            ? Directory(path)
            : File(path);

    if (!entity.existsSync()) {
      throw FileSystemException("Path to watch does not exist", path);
    }

    final subscription = entity.watch().listen((event) async {
      if (ctx.isCancelled) return;

      FileChangeKind kind;
      switch (event.type) {
        case FileSystemEvent.create:
          kind = FileChangeKind.added;
          break;
        case FileSystemEvent.delete:
          kind = FileChangeKind.deleted;
          break;
        case FileSystemEvent.modify:
        default:
          kind = FileChangeKind.modified;
          break;
      }

      final change = FileChange(kind: kind, path: event.path);
      try {
        await callback(ctx, [change]);
      } catch (e) {
        // Log/swallow callback errors
      }
    });

    // Keep the trigger alive until cancelled
    while (!ctx.isCancelled) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await subscription.cancel();
  };
}
