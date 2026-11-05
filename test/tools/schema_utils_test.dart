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

    test('maps read_only and write_only to camelCase', () {
      final normalized = normalizeSchema({
        'type': 'object',
        'properties': {
          'id': {'type': 'string', 'read_only': true},
          'password': {'type': 'string', 'write_only': true},
        },
      }) as Map<String, dynamic>;
      final props = normalized['properties'] as Map<String, dynamic>;
      expect(props['id'], {'type': 'string', 'readOnly': true});
      expect(props['password'], {'type': 'string', 'writeOnly': true});
    });

    test('preserves metadata strings that look like type names', () {
      final normalized = normalizeSchema({
        'type': 'object',
        'title': 'OBJECT',
        'description': 'STRING',
        'summary': 'NUMBER',
        'format': 'INTEGER',
        'pattern': 'BOOLEAN',
        'properties': {
          'val': {
            'type': 'STRING',
            'title': 'STRING',
            'description': 'OBJECT',
            'format': 'NUMBER',
            'pattern': 'ARRAY',
          },
        },
      }) as Map<String, dynamic>;
      expect(normalized['type'], 'object');
      expect(normalized['title'], 'OBJECT');
      expect(normalized['description'], 'STRING');
      expect(normalized['summary'], 'NUMBER');
      expect(normalized['format'], 'INTEGER');
      expect(normalized['pattern'], 'BOOLEAN');
      expect((normalized['properties'] as Map)['val'], {
        'type': 'string',
        'title': 'STRING',
        'description': 'OBJECT',
        'format': 'NUMBER',
        'pattern': 'ARRAY',
      });
    });

    test('preserves example and examples literals', () {
      final normalized = normalizeSchema({
        'type': 'STRING',
        'example': 'STRING',
        'examples': ['STRING', 'OBJECT', 'NULL'],
      }) as Map<String, dynamic>;
      expect(normalized['type'], 'string');
      expect(normalized['example'], 'STRING');
      expect(normalized['examples'], ['STRING', 'OBJECT', 'NULL']);
    });

    test('maps extended keywords and normalizes their subschemas', () {
      final normalized = normalizeSchema({
        'multiple_of': 5,
        'exclusive_minimum': 0,
        'exclusive_maximum': 100,
        'prefix_items': [
          {'type': 'STRING'},
          {'type': 'INTEGER'},
        ],
        'property_names': {'pattern': r'^[a-z]+$'},
        'dependent_required': {
          'credit_card': ['billing_address'],
        },
        'dependent_schemas': {
          'credit_card': {
            'properties': {
              'billing_address': {'type': 'STRING'},
            },
          },
        },
        'unevaluated_properties': false,
        'unevaluated_items': {'type': 'STRING'},
      }) as Map<String, dynamic>;
      expect(normalized, {
        'multipleOf': 5,
        'exclusiveMinimum': 0,
        'exclusiveMaximum': 100,
        'prefixItems': [
          {'type': 'string'},
          {'type': 'integer'},
        ],
        'propertyNames': {'pattern': r'^[a-z]+$'},
        'dependentRequired': {
          'credit_card': ['billing_address'],
        },
        'dependentSchemas': {
          'credit_card': {
            'properties': {
              'billing_address': {'type': 'string'},
            },
          },
        },
        'unevaluatedProperties': false,
        'unevaluatedItems': {'type': 'string'},
      });
    });

    test('keeps dependentRequired property names and lists as-is', () {
      final normalized = normalizeSchema({
        'type': 'OBJECT',
        'properties': {
          'type': {'type': 'STRING'},
          'min_items': {'type': 'INTEGER'},
          'STATUS': {'type': 'STRING'},
        },
        'dependent_required': {
          'type': ['min_items', 'properties'],
          'STATUS': ['STRING', 'OBJECT', 'NULL'],
          'schema_key': ['another_prop'],
        },
      }) as Map<String, dynamic>;
      expect(normalized['type'], 'object');
      expect(normalized['dependentRequired'], {
        'type': ['min_items', 'properties'],
        'STATUS': ['STRING', 'OBJECT', 'NULL'],
        'schema_key': ['another_prop'],
      });
    });

    test('preserves nested example data', () {
      const complexExample = {
        'type': 'CUSTOM_RECORD',
        'data': {
          'STRING': 'VALUE',
          'flags': ['BOOLEAN', 'NULL'],
          'nested': {'format': 'INTEGER'},
        },
      };
      final normalized = normalizeSchema({
        'type': 'OBJECT',
        'example': complexExample,
        'examples': [
          complexExample,
          {'code': 'ARRAY'},
        ],
      }) as Map<String, dynamic>;
      expect(normalized['example'], complexExample);
      expect(normalized['examples'], [
        complexExample,
        {'code': 'ARRAY'},
      ]);
    });

    test('dependentSchemas keys are property names, not keywords', () {
      final normalized = normalizeSchema({
        'dependent_schemas': {
          'any_of': {
            'properties': {
              'token': {'type': 'STRING'},
              'scope': {
                'type': 'STRING',
                'enum': ['READ', 'WRITE'],
              },
            },
            'dependent_required': {
              'token': ['scope'],
            },
          },
        },
      }) as Map<String, dynamic>;
      final schemas = normalized['dependentSchemas'] as Map<String, dynamic>;
      expect(schemas.keys, ['any_of']);
      expect(schemas['any_of'], {
        'properties': {
          'token': {'type': 'string'},
          'scope': {
            'type': 'string',
            'enum': ['READ', 'WRITE'],
          },
        },
        'dependentRequired': {
          'token': ['scope'],
        },
      });
    });

    test('handles deeply nested subschema composition', () {
      final normalized = normalizeSchema({
        'type': 'OBJECT',
        'properties': {
          'data_tuple': {
            'type': 'ARRAY',
            'prefix_items': [
              'STRING',
              {'type': 'INTEGER', 'multiple_of': 2.5},
              {'type': 'OBJECT', 'additional_properties': false},
            ],
          },
        },
      }) as Map<String, dynamic>;
      final prefixItems =
          (normalized['properties'] as Map)['data_tuple']['prefixItems'];
      expect(prefixItems, [
        'string',
        {'type': 'integer', 'multipleOf': 2.5},
        {'type': 'object', 'additionalProperties': false},
      ]);
    });

    test('handles empty and edge-case schemas', () {
      expect(normalizeSchema(<String, dynamic>{}), isEmpty);
      expect(normalizeSchema([]), isEmpty);
      expect(normalizeSchema({'type': []}), {'type': []});
      expect(
        normalizeSchema({
          'additional_properties': true,
          'unevaluated_properties': false,
        }),
        {'additionalProperties': true, 'unevaluatedProperties': false},
      );
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
