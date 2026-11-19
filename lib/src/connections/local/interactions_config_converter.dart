import '../../tools/schema_utils.dart';
import '../../tools/tool_runner.dart';

Map<String, dynamic> _emptyParameters() => {
  'type': 'object',
  'properties': <String, dynamic>{},
};

/// Converts a registered [Tool] into a function tool schema.
Map<String, dynamic> toolToFunctionToolDict(Tool tool) {
  return {
    'type': 'function',
    'name': tool.name,
    if (tool.description.isNotEmpty) 'description': tool.description,
    'parameters': normalizeSchema(
      tool.schema.isEmpty ? _emptyParameters() : tool.schema,
    ),
  };
}
