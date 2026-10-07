import 'dart:io';

import 'package:antigravity/antigravity.dart';

/// Runs a Python workflow file in the local harness's restricted runtime.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
        'Usage: dart run example/getting_started/workflows.dart <workflow.py>');
    exitCode = 64;
    return;
  }
  final agent = Agent(LocalAgentConfig(
    capabilities: CapabilitiesConfig(enabledTools: [BuiltinTools.runWorkflow]),
    policies: [allowAll()],
  ));
  await agent.start();
  try {
    final result = await agent.beta.runWorkflow(scriptPath: args.single);
    stdout.writeln(result.output);
    stdout.writeln(result.responseText);
  } finally {
    await agent.stop();
  }
}
