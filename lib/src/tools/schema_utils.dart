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
dynamic normalizeSchema(dynamic schema) {
  if (schema is Map) {
    final normalized = <String, dynamic>{};
    for (final entry in schema.entries) {
      final rawKey = entry.key.toString();
      final k = _schemaKeywordMap[rawKey] ?? rawKey;
      final v = entry.value;

      if (k == 'type') {
        if (v is String) {
          normalized[k] = v.toLowerCase();
        } else if (v is List) {
          normalized[k] = v.map((item) => normalizeSchema(item)).toList();
        } else {
          normalized[k] = normalizeSchema(v);
        }
      } else if (k == 'properties' ||
          k == 'patternProperties' ||
          k == r'$defs' ||
          k == 'definitions') {
        if (v is Map) {
          normalized[k] = v.map(
            (pk, pv) => MapEntry(pk.toString(), normalizeSchema(pv)),
          );
        } else {
          normalized[k] = normalizeSchema(v);
        }
      } else if (k == 'enum' || k == 'const' || k == 'default') {
        normalized[k] = v;
      } else {
        normalized[k] = normalizeSchema(v);
      }
    }
    return normalized;
  } else if (schema is List) {
    return schema.map((item) => normalizeSchema(item)).toList();
  } else if (schema is String && _uppercaseTypes.contains(schema)) {
    return schema.toLowerCase();
  }
  return schema;
}
