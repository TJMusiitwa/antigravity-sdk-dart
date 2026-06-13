import 'dart:async';
import '../types.dart';

// --- Contexts ---

/// Base context for hooks to share state.
class HookContext {
  final HookContext? parent;
  final Map<String, dynamic> _store = {};

  HookContext({this.parent});

  /// Gets a value from the context or its parent hierarchy.
  dynamic get(String key, [dynamic defaultValue]) {
    if (_store.containsKey(key)) {
      return _store[key];
    }
    if (parent != null) {
      return parent!.get(key, defaultValue);
    }
    return defaultValue;
  }

  /// Sets a value in the local context.
  void set(String key, dynamic value) {
    _store[key] = value;
  }
}

/// Context scoped to an entire agent session.
class SessionContext extends HookContext {
  SessionContext() : super(parent: null);
}

/// Context scoped to a single interaction turn.
class TurnContext extends HookContext {
  final SessionContext sessionContext;
  TurnContext(this.sessionContext) : super(parent: sessionContext);
}

/// Context scoped to a single operation (e.g. a tool call).
class OperationContext extends HookContext {
  final TurnContext turnContext;
  OperationContext(this.turnContext) : super(parent: turnContext);
}

// --- Base Hook Interfaces ---

/// Base interface for all Hooks.
abstract class Hook {}

/// Read-only, non-blocking hook for observability.
abstract class InspectHook<T> implements Hook {
  Future<void> run(HookContext context, T data);
}

/// Read-only, blocking hook for policy decisions.
abstract class DecideHook<T> implements Hook {
  Future<HookResult> run(HookContext context, T data);
}

/// Modifying, blocking hook for data transformation.
abstract class TransformHook<T, R> implements Hook {
  Future<R> run(HookContext context, T data);
}

// --- Functional Helpers / Implementations ---

/// Helper class to adapt functions into InspectHooks.
class FunctionInspectHook<T> implements InspectHook<T> {
  final FutureOr<void> Function(HookContext context, T data) _func;
  FunctionInspectHook(this._func);

  @override
  Future<void> run(HookContext context, T data) async {
    await _func(context, data);
  }
}

/// Helper class to adapt functions into DecideHooks.
class FunctionDecideHook<T> implements DecideHook<T> {
  final FutureOr<HookResult> Function(HookContext context, T data) _func;
  FunctionDecideHook(this._func);

  @override
  Future<HookResult> run(HookContext context, T data) async {
    return await _func(context, data);
  }
}

/// Helper class to adapt functions into TransformHooks.
class FunctionTransformHook<T, R> implements TransformHook<T, R> {
  final FutureOr<R> Function(HookContext context, T data) _func;
  FunctionTransformHook(this._func);

  @override
  Future<R> run(HookContext context, T data) async {
    return await _func(context, data);
  }
}

// --- Concrete Hook Subclasses/Interfaces ---

/// Invoked when the session starts.
abstract class OnSessionStartHook extends InspectHook<void> {}

/// Invoked when the session ends.
abstract class OnSessionEndHook extends InspectHook<void> {}

/// Invoked before a turn starts.
abstract class PreTurnHook extends DecideHook<ContentPrimitive> {}

/// Invoked after a completed turn ends.
abstract class PostTurnHook extends InspectHook<String> {}

/// Invoked before a tool call to decide if it should proceed.
abstract class PreToolCallDecideHook extends DecideHook<ToolCall> {}

/// Invoked after a tool call completes successfully.
abstract class PostToolCallHook extends InspectHook<ToolResult> {}

/// Invoked when a tool fails, allowing recovery/transformation.
abstract class OnToolErrorHook extends TransformHook<Exception, dynamic> {}

/// Invoked when the agent needs user interaction.
abstract class OnInteractionHook
    extends TransformHook<AskQuestionInteractionSpec, QuestionHookResult> {}

/// Invoked when a context compaction event occurs.
abstract class OnCompactionHook extends InspectHook<dynamic> {}

// --- Hook Runner ---

/// Coordinates registration and dispatch of lifecycle hooks.
class HookRunner {
  final List<OnSessionStartHook> onSessionStartHooks;
  final List<OnSessionEndHook> onSessionEndHooks;
  final List<PreTurnHook> preTurnHooks;
  final List<PostTurnHook> postTurnHooks;
  final List<PreToolCallDecideHook> preToolCallDecideHooks;
  final List<PostToolCallHook> postToolCallHooks;
  final List<OnToolErrorHook> onToolErrorHooks;
  final List<OnInteractionHook> onInteractionHooks;
  final List<OnCompactionHook> onCompactionHooks;

  final SessionContext sessionContext = SessionContext();
  TurnContext? _currentTurnContext;

  HookRunner({
    List<OnSessionStartHook>? onSessionStartHooks,
    List<OnSessionEndHook>? onSessionEndHooks,
    List<PreTurnHook>? preTurnHooks,
    List<PostTurnHook>? postTurnHooks,
    List<PreToolCallDecideHook>? preToolCallDecideHooks,
    List<PostToolCallHook>? postToolCallHooks,
    List<OnToolErrorHook>? onToolErrorHooks,
    List<OnInteractionHook>? onInteractionHooks,
    List<OnCompactionHook>? onCompactionHooks,
  }) : onSessionStartHooks = onSessionStartHooks ?? [],
       onSessionEndHooks = onSessionEndHooks ?? [],
       preTurnHooks = preTurnHooks ?? [],
       postTurnHooks = postTurnHooks ?? [],
       preToolCallDecideHooks = preToolCallDecideHooks ?? [],
       postToolCallHooks = postToolCallHooks ?? [],
       onToolErrorHooks = onToolErrorHooks ?? [],
       onInteractionHooks = onInteractionHooks ?? [],
       onCompactionHooks = onCompactionHooks ?? [];

  /// Registers a hook dynamically.
  void registerHook(Hook hook) {
    if (hook is OnSessionStartHook) {
      onSessionStartHooks.add(hook);
    } else if (hook is OnSessionEndHook) {
      onSessionEndHooks.add(hook);
    } else if (hook is PreTurnHook) {
      preTurnHooks.add(hook);
    } else if (hook is PostTurnHook) {
      postTurnHooks.add(hook);
    } else if (hook is PreToolCallDecideHook) {
      preToolCallDecideHooks.add(hook);
    } else if (hook is PostToolCallHook) {
      postToolCallHooks.add(hook);
    } else if (hook is OnToolErrorHook) {
      onToolErrorHooks.add(hook);
    } else if (hook is OnInteractionHook) {
      onInteractionHooks.add(hook);
    } else if (hook is OnCompactionHook) {
      onCompactionHooks.add(hook);
    } else {
      throw ArgumentError("Unknown hook type: ${hook.runtimeType}");
    }
  }

  /// Returns true if any hooks are registered in the runner.
  bool get hasHooks =>
      onSessionStartHooks.isNotEmpty ||
      onSessionEndHooks.isNotEmpty ||
      preTurnHooks.isNotEmpty ||
      postTurnHooks.isNotEmpty ||
      preToolCallDecideHooks.isNotEmpty ||
      postToolCallHooks.isNotEmpty ||
      onToolErrorHooks.isNotEmpty ||
      onInteractionHooks.isNotEmpty ||
      onCompactionHooks.isNotEmpty;

  /// Creates and returns a fresh [TurnContext].
  TurnContext createTurnContext() {
    _currentTurnContext = TurnContext(sessionContext);
    return _currentTurnContext!;
  }

  /// Returns the current active [TurnContext], creating one if none exists.
  TurnContext get currentTurnContext =>
      _currentTurnContext ?? createTurnContext();

  /// Dispatches session start events to all registered hooks.
  Future<void> dispatchSessionStart() async {
    for (final hook in onSessionStartHooks) {
      await hook.run(sessionContext, null);
    }
  }

  /// Dispatches session end events to all registered hooks.
  Future<void> dispatchSessionEnd() async {
    for (final hook in onSessionEndHooks) {
      await hook.run(sessionContext, null);
    }
  }

  /// Dispatches pre-turn events to decide if a turn should proceed.
  Future<HookResult> dispatchPreTurn(ContentPrimitive? prompt) async {
    final ctx = createTurnContext();
    final effectivePrompt = prompt ?? '';
    for (final hook in preTurnHooks) {
      final res = await hook.run(ctx, effectivePrompt);
      if (!res.allow) {
        return res;
      }
    }
    return HookResult(allow: true);
  }

  /// Dispatches post-turn events when a turn completes.
  Future<void> dispatchPostTurn(
    TurnContext turnContext,
    String response,
  ) async {
    for (final hook in postTurnHooks) {
      await hook.run(turnContext, response);
    }
  }

  /// Dispatches pre-tool call events to verify execution allowance.
  Future<HookResult> dispatchPreToolCall(
    TurnContext turnContext,
    ToolCall toolCall,
  ) async {
    final opContext = OperationContext(turnContext);
    for (final hook in preToolCallDecideHooks) {
      final res = await hook.run(opContext, toolCall);
      if (!res.allow) {
        return res;
      }
    }
    return HookResult(allow: true);
  }

  /// Dispatches post-tool call events after execution is successful.
  Future<void> dispatchPostToolCall(
    TurnContext turnContext,
    ToolResult result,
  ) async {
    final opContext = OperationContext(turnContext);
    for (final hook in postToolCallHooks) {
      await hook.run(opContext, result);
    }
  }

  /// Dispatches tool error events allowing guides/recovery to be returned to the model.
  Future<dynamic> dispatchOnToolError(
    TurnContext turnContext,
    Exception error,
  ) async {
    final opContext = OperationContext(turnContext);
    for (final hook in onToolErrorHooks) {
      try {
        final res = await hook.run(opContext, error);
        if (res != null) {
          return res;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Dispatches interactive questions to appropriate handlers.
  Future<QuestionHookResult?> dispatchInteraction(
    TurnContext turnContext,
    AskQuestionInteractionSpec spec,
  ) async {
    final opContext = OperationContext(turnContext);
    for (final hook in onInteractionHooks) {
      final res = await hook.run(opContext, spec);
      return res;
    }
    return null;
  }

  /// Dispatches compaction events.
  Future<void> dispatchCompaction(TurnContext turnContext, dynamic data) async {
    final opContext = OperationContext(turnContext);
    for (final hook in onCompactionHooks) {
      await hook.run(opContext, data);
    }
  }
}
