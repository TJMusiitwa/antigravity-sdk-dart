import '../connections/connection.dart';

/// Conversation-aware context for custom tools.
///
/// wraps a Connection and exposes conversation capabilities — identity, idle state,
/// message injection, and a per-conversation key-value store — to tools.
class ToolContext {
  final Connection _connection;
  final Map<String, dynamic> _state = {};

  ToolContext(this._connection);

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

  /// Retrieves a value from the per-conversation state store.
  dynamic getState(String key, [dynamic defaultValue]) {
    return _state.containsKey(key) ? _state[key] : defaultValue;
  }

  /// Stores a value in the per-conversation state store.
  void setState(String key, dynamic value) {
    _state[key] = value;
  }
}
