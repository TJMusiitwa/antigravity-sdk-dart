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

import 'package:antigravity/src/tools/schema_utils.dart';
import 'package:test/test.dart';

void main() {
  group('schema_utils.normalizeSchema', () {
    test('normalizes primitive uppercase types', () {
      expect(normalizeSchema('STRING'), equals('string'));
      expect(normalizeSchema('INTEGER'), equals('integer'));
      expect(normalizeSchema('NUMBER'), equals('number'));
      expect(normalizeSchema('BOOLEAN'), equals('boolean'));
      expect(normalizeSchema('ARRAY'), equals('array'));
      expect(normalizeSchema('OBJECT'), equals('object'));
      expect(normalizeSchema('NULL'), equals('null'));
    });

    test('normalizes map keywords and nested types', () {
      final input = {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING', 'description': 'User name'},
          'age': {'type': 'INTEGER'},
          'scores': {
            'type': 'ARRAY',
            'items': {'type': 'NUMBER'},
          },
        },
        'required': ['name'],
      };

      final expected = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'User name'},
          'age': {'type': 'integer'},
          'scores': {
            'type': 'array',
            'items': {'type': 'number'},
          },
        },
        'required': ['name'],
      };

      expect(normalizeSchema(input), equals(expected));
    });

    test('normalizes combiners, constraints, and keywords', () {
      final input = {
        'any_of': [
          {'type': 'STRING'},
          {'type': 'INTEGER'},
        ],
        'one_of': [
          {'type': 'BOOLEAN'},
        ],
        'all_of': [
          {'type': 'OBJECT'},
        ],
        'additional_properties': {'type': 'STRING'},
        'pattern_properties': {
          '^[a-z]+\$': {'type': 'INTEGER'},
        },
        'min_items': 1,
        'max_items': 10,
        'min_length': 2,
        'max_length': 50,
        'min_properties': 1,
        'max_properties': 5,
        'unique_items': true,
        r'$defs': {
          'CustomNode': {'type': 'OBJECT'},
        },
        'definitions': {
          'LegacyNode': {'type': 'ARRAY'},
        },
        'type': ['STRING', 'NULL', 'BOOLEAN'],
      };

      final normalized = normalizeSchema(input) as Map<String, dynamic>;

      expect(normalized.containsKey('anyOf'), isTrue);
      expect(normalized.containsKey('oneOf'), isTrue);
      expect(normalized.containsKey('allOf'), isTrue);
      expect(normalized.containsKey('additionalProperties'), isTrue);
      expect(normalized.containsKey('patternProperties'), isTrue);
      expect(normalized.containsKey('minItems'), isTrue);
      expect(normalized.containsKey('maxItems'), isTrue);
      expect(normalized.containsKey('minLength'), isTrue);
      expect(normalized.containsKey('maxLength'), isTrue);
      expect(normalized.containsKey('minProperties'), isTrue);
      expect(normalized.containsKey('maxProperties'), isTrue);
      expect(normalized.containsKey('uniqueItems'), isTrue);

      expect(normalized['anyOf'][0]['type'], equals('string'));
      expect(normalized['anyOf'][1]['type'], equals('integer'));
      expect(normalized['oneOf'][0]['type'], equals('boolean'));
      expect(normalized['allOf'][0]['type'], equals('object'));
      expect(normalized['additionalProperties']['type'], equals('string'));
      expect(
        normalized['patternProperties'][r'^[a-z]+$']['type'],
        equals('integer'),
      );
      expect(normalized[r'$defs']['CustomNode']['type'], equals('object'));
      expect(normalized['definitions']['LegacyNode']['type'], equals('array'));
      expect(normalized['type'], equals(['string', 'null', 'boolean']));
    });

    test('preserves literal values (enum, const, default)', () {
      final input = {
        'type': 'STRING',
        'enum': ['ACTIVE', 'INACTIVE', 'PENDING'],
        'const': 'UPPERCASE_CONST',
        'default': 'DEFAULT_VAL',
      };

      final normalized = normalizeSchema(input) as Map<String, dynamic>;

      expect(normalized['type'], equals('string'));
      expect(normalized['enum'], equals(['ACTIVE', 'INACTIVE', 'PENDING']));
      expect(normalized['const'], equals('UPPERCASE_CONST'));
      expect(normalized['default'], equals('DEFAULT_VAL'));
    });

    test('passes through non-schema primitives unchanged', () {
      expect(normalizeSchema(42), equals(42));
      expect(normalizeSchema(3.14), equals(3.14));
      expect(normalizeSchema(true), isTrue);
      expect(normalizeSchema(null), isNull);
      expect(normalizeSchema('custom_literal'), equals('custom_literal'));
    });
  });
}
