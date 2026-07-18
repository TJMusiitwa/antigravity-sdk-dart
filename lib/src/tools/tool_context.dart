import '../connections/connection.dart';
import '../utils/state.dart';

/// Conversation-aware context for custom tools.
///
/// wraps a Connection and exposes conversation capabilities — identity, idle state,
/// message injection, and a per-conversation key-value store — to tools.
class ToolContext extends StateStore {
  final Connection _connection;

  /// Creates a new [ToolContext] instance wrapping the given [connection].
  ToolContext(this._connection) : super(parent: null);

  /// Returns the active connection.
  Connection get connection => _connection;

  /// Returns the conversation identifier.
  String get conversationId => _connection.conversationId;

  /// Returns true if the connection is idle.
  bool get isIdle => _connection.isIdle;

  /// Sends an asynchronous trigger notification to the conversation.
  Future<void> send(String message) async {
    await _connection.sendTriggerNotification(message);
  }
}
