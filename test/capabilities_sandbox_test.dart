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

import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

void main() {
  group('RunCommandConfig sandbox', () {
    test('defaults enableSandbox to false', () {
      final config = RunCommandConfig();
      expect(config.enableSandbox, isFalse);
      expect(config.enableDaemons, isFalse);
      expect(config.timeoutSeconds, isNull);

      final map = config.toMap();
      expect(map['enable_sandbox'], isFalse);
    });

    test('accepts enableSandbox: true', () {
      final config = RunCommandConfig(
        enableSandbox: true,
        enableDaemons: true,
        timeoutSeconds: 30.0,
      );
      expect(config.enableSandbox, isTrue);
      expect(config.enableDaemons, isTrue);
      expect(config.timeoutSeconds, equals(30.0));

      final map = config.toMap();
      expect(map['enable_sandbox'], isTrue);
      expect(map['enable_daemons'], isTrue);
      expect(map['timeout_seconds'], equals(30.0));

      final decoded = RunCommandConfig.fromMap(map);
      expect(decoded.enableSandbox, isTrue);
      expect(decoded.enableDaemons, isTrue);
      expect(decoded.timeoutSeconds, equals(30.0));
    });

    test('deserializes from map with snake_case key', () {
      final decoded = RunCommandConfig.fromMap({'enable_sandbox': true});
      expect(decoded.enableSandbox, isTrue);
    });
  });
}
