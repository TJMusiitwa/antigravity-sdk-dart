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

/// Utilities for JSON Schema normalization and conversion.
library;

const Map<String, String> _schemaKeywordMap = {
  'any_of': 'anyOf',
  'one_of': 'oneOf',
  'all_of': 'allOf',
  'additional_properties': 'additionalProperties',
  'pattern_properties': 'patternProperties',
  'min_items': 'minItems',
  'max_items': 'maxItems',
  'min_length': 'minLength',
  'max_length': 'maxLength',
  'min_properties': 'minProperties',
  'max_properties': 'maxProperties',
  'unique_items': 'uniqueItems',
};

const Set<String> _uppercaseTypes = {
  'STRING',
  'NUMBER',
  'INTEGER',
  'BOOLEAN',
  'ARRAY',
  'OBJECT',
  'NULL',
};

/// Recursively normalizes JSON Schema maps and lists for universal model compatibility.
///
/// Converts uppercase GenAI/Protobuf type names to lowercase strings, converts
/// snake_case JSON Schema keywords to camelCase (e.g. `any_of` -> `anyOf`),
/// and preserves literal values (`enum`, `const`, `default`).
dynamic normalizeSchema(dynamic schema) => switch (schema) {
      Map() => _normalizeMap(schema),
      List() => schema.map(normalizeSchema).toList(),
      String s when _uppercaseTypes.contains(s) => s.toLowerCase(),
      _ => schema,
    };

Map<String, dynamic> _normalizeMap(Map schema) {
  final normalized = <String, dynamic>{};
  for (final entry in schema.entries) {
    final rawKey = entry.key.toString();
    final k = _schemaKeywordMap[rawKey] ?? rawKey;
    normalized[k] = _normalizeEntryValue(k, entry.value);
  }
  return normalized;
}

dynamic _normalizeEntryValue(String key, dynamic value) => switch (key) {
      'type' => switch (value) {
          String s => s.toLowerCase(),
          List l => l.map(normalizeSchema).toList(),
          _ => normalizeSchema(value),
        },
      'properties' ||
      'patternProperties' ||
      r'$defs' ||
      'definitions' =>
        switch (value) {
          Map m => m.map(
              (pk, pv) => MapEntry(pk.toString(), normalizeSchema(pv)),
            ),
          _ => normalizeSchema(value),
        },
      'enum' || 'const' || 'default' => value,
      _ => normalizeSchema(value),
    };
