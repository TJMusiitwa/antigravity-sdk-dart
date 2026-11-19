import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/interactions_config_converter.dart';
import 'package:test/test.dart';

void main() {
  test('function tool schema preserves explicit metadata', () {
    final tool = Tool(
      name: 'add_numbers',
      description: 'Adds two numbers.',
      schema: {
        'type': 'OBJECT',
        'properties': {
          'a': {'type': 'INTEGER', 'read_only': true},
        },
      },
      handler: (_, _) => 0,
    );
    expect(toolToFunctionToolDict(tool), {
      'type': 'function',
      'name': 'add_numbers',
      'description': 'Adds two numbers.',
      'parameters': {
        'type': 'object',
        'properties': {
          'a': {'type': 'integer', 'readOnly': true},
        },
      },
    });
  });
}
