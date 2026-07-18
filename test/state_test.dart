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

import 'package:antigravity/src/utils/state.dart';
import 'package:test/test.dart';

void main() {
  group('StateStore', () {
    test('test basic get/set', () {
      final store = StateStore();
      expect(store.getState('missing'), isNull);
      expect(store.getState('missing', 'default'), equals('default'));
      store.setState('key', 'val');
      expect(store.getState('key'), equals('val'));
    });

    test('test hierarchical get and shadowing', () {
      final parent = StateStore();
      parent.setState('shared', 'parent_val');
      final child = StateStore(parent: parent);
      expect(child.getState('shared'), equals('parent_val'));

      child.setState('shared', 'child_val');
      expect(child.getState('shared'), equals('child_val'));
      expect(parent.getState('shared'), equals('parent_val'));
    });

    test('test updateState', () {
      final parent = StateStore();
      parent.setState('count', 10);
      final child = StateStore(parent: parent);
      final res = child.updateState('count', (x) => (x as int) + 5);
      expect(res, equals(15));
      expect(child.getState('count'), equals(15));
      expect(parent.getState('count'), equals(10));
    });

    test('test updateState exception safety', () {
      final store = StateStore();
      store.setState('key', 'initial');

      expect(() {
        store.updateState('key', (val) {
          throw Exception('failed');
        });
      }, throwsException);

      expect(store.getState('key'), equals('initial'));
      // Lock should be released and can be acquired again
      store.lock().acquire();
      expect(store.getState('key'), equals('initial'));
      store.lock().release();
    });

    test('test lock and context reentrancy', () {
      final store = StateStore();
      expect(store.lock().isLocked, isFalse);

      store.acquire();
      store.setState('in_lock', true);
      expect(store.lock().isLocked, isTrue);

      // Reentrant check
      store.acquire();
      expect(store.getState('in_lock'), isTrue);
      store.release();

      expect(store.lock().isLocked, isTrue);
      store.release();
      expect(store.lock().isLocked, isFalse);
    });
  });
}
