// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// A simple reentrant lock class matching RLock behavior for state synchronization.
///
/// > [!NOTE]
/// > Because Dart uses a single-threaded event loop, synchronous operations
/// > are naturally atomic. This [Lock] is a non-blocking hold-counter provided
/// > for API parity with the Python SDK, and does not block/suspend execution
/// > across asynchronous (`await`) boundaries.
class Lock {
  int _holdCount = 0;

  /// Returns whether the lock is currently held.
  bool get isLocked => _holdCount > 0;

  /// Acquires the lock, incrementing the hold count.
  void acquire() {
    _holdCount++;
  }

  /// Releases the lock, decrementing the hold count.
  void release() {
    if (_holdCount > 0) {
      _holdCount--;
    }
  }
}

/// Hierarchical key-value store for extensibility contexts.
///
/// Provides state operations ([getState], [setState], [updateState]) and lock
/// support across both flat and hierarchical (parent-child) contexts.
///
/// Synchronous callbacks passed to [updateState] execute atomically because Dart's
/// event loop is single-threaded and cannot interleave execution without an `await`.
class StateStore {
  /// The parent state store, if any.
  final StateStore? parent;
  final Map<String, dynamic> _store = {};
  final Lock _lock = Lock();

  /// Creates a new [StateStore] instance, optionally specifying a [parent].
  StateStore({this.parent});

  /// Retrieves a value from the local state store or its parents.
  dynamic getState(String key, [dynamic defaultValue]) {
    if (_store.containsKey(key)) {
      return _store[key];
    }
    if (parent != null) {
      return parent!.getState(key, defaultValue);
    }
    return defaultValue;
  }

  /// Stores a value in the local state store.
  void setState(String key, dynamic value) {
    _store[key] = value;
  }

  /// Atomically updates a value in the local state store.
  ///
  /// The [updaterFn] executes while holding the reentrant lock.
  /// If the key exists only in a parent store, the current parent value is passed
  /// to [updaterFn], and the updated result is stored in the local store.
  dynamic updateState(
    String key,
    dynamic Function(dynamic) updaterFn, [
    dynamic defaultValue,
  ]) {
    _lock.acquire();
    try {
      final val = getState(key, defaultValue);
      final newVal = updaterFn(val);
      _store[key] = newVal;
      return newVal;
    } finally {
      _lock.release();
    }
  }

  /// Returns the underlying lock.
  Lock lock() => _lock;

  /// Direct acquire proxy for using StateStore directly.
  void acquire() => _lock.acquire();

  /// Direct release proxy for using StateStore directly.
  void release() => _lock.release();
}
