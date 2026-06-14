import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Policy builder helpers
  // ---------------------------------------------------------------------------
  group('Policy – allow / deny / askUser builders', () {
    test('allow() creates a policy with Decision.approve', () {
      final p = allow('view_file');
      expect(p.tool, equals('view_file'));
      expect(p.decision, equals(Decision.approve));
      expect(p.when, isNull);
    });

    test('allow() accepts an optional name', () {
      final p = allow('view_file', name: 'reader');
      expect(p.name, equals('reader'));
    });

    test('deny() creates a policy with Decision.deny', () {
      final p = deny('run_command');
      expect(p.tool, equals('run_command'));
      expect(p.decision, equals(Decision.deny));
    });

    test('askUser() creates a policy with Decision.askUser', () {
      final p = askUser('create_file', handler: (_) async => true);
      expect(p.tool, equals('create_file'));
      expect(p.decision, equals(Decision.askUser));
      expect(p.askUser, isNotNull);
    });

    test('allowAll() targets wildcard * with name allow_all', () {
      final p = allowAll();
      expect(p.tool, equals('*'));
      expect(p.decision, equals(Decision.approve));
      expect(p.name, equals('allow_all'));
    });

    test('denyAll() targets wildcard * with name deny_all', () {
      final p = denyAll();
      expect(p.tool, equals('*'));
      expect(p.decision, equals(Decision.deny));
      expect(p.name, equals('deny_all'));
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – validation
  // ---------------------------------------------------------------------------
  group('enforce() – validation', () {
    test('throws ArgumentError when askUser policy has no handler', () {
      final brokenPolicy = Policy(
        tool: 'view_file',
        decision: Decision.askUser,
        // No askUser handler!
      );
      expect(() => enforce([brokenPolicy]), throwsA(isA<ArgumentError>()));
    });

    test('does not throw when all askUser policies have handlers', () {
      final p = askUser('view_file', handler: (_) async => true);
      expect(() => enforce([p]), returnsNormally);
    });

    test('does not throw for allow/deny policies without handlers', () {
      expect(() => enforce([allow('*'), deny('run_command')]), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – allowAll policy
  // ---------------------------------------------------------------------------
  group('enforce() – allowAll', () {
    test('approves any tool call', () async {
      final hook = enforce([allowAll()]);
      final ctx = HookContext();
      final result = await hook.run(
        ctx,
        ToolCall(name: 'run_command', args: {'cmd': 'rm -rf /'}),
      );
      expect(result.allow, isTrue);
    });

    test('approves tool calls without args', () async {
      final hook = enforce([allowAll()]);
      final result = await hook.run(HookContext(), ToolCall(name: 'finish'));
      expect(result.allow, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – denyAll policy
  // ---------------------------------------------------------------------------
  group('enforce() – denyAll', () {
    test('denies any tool call', () async {
      final hook = enforce([denyAll()]);
      final ctx = HookContext();
      final result = await hook.run(ctx, ToolCall(name: 'view_file', args: {}));
      expect(result.allow, isFalse);
    });

    test('denial message mentions policy name', () async {
      final hook = enforce([denyAll()]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'anything', args: {}),
      );
      expect(result.message, contains('deny_all'));
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – specific tool allow/deny
  // ---------------------------------------------------------------------------
  group('enforce() – specific tool targeting', () {
    test('specific deny blocks the targeted tool', () async {
      final hook = enforce([deny('run_command'), allow('*')]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'run_command', args: {}),
      );
      expect(result.allow, isFalse);
    });

    test('specific deny does NOT block other tools', () async {
      final hook = enforce([deny('run_command'), allow('*')]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isTrue);
    });

    test('specific allow takes precedence over wildcard deny', () async {
      // Bucket ordering: specific-allow before wildcard-deny
      final hook = enforce([allow('view_file'), denyAll()]);
      final allowResult = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(allowResult.allow, isTrue);

      final denyResult = await hook.run(
        HookContext(),
        ToolCall(name: 'run_command', args: {}),
      );
      expect(denyResult.allow, isFalse);
    });

    test('no matching policy returns allow=true (default)', () async {
      // Only block 'run_command'; no wildcard fallback
      final hook = enforce([deny('run_command')]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – conditional policies (when clause)
  // ---------------------------------------------------------------------------
  group('enforce() – when clause', () {
    test('deny with when=false does NOT deny the call', () async {
      final hook = enforce([
        deny('view_file', when: (_) async => false),
        allow('*'),
      ]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isTrue);
    });

    test('deny with when=true denies the call', () async {
      final hook = enforce([
        deny('view_file', when: (_) async => true),
        allow('*'),
      ]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isFalse);
    });

    test('when clause receives the ToolCall', () async {
      ToolCall? received;
      final hook = enforce([
        deny(
          'view_file',
          when: (tc) async {
            received = tc;
            return false;
          },
        ),
        allow('*'),
      ]);
      final call = ToolCall(name: 'view_file', args: {'path': '/some/file'});
      await hook.run(HookContext(), call);
      expect(received, isNotNull);
      expect(received!.args['path'], equals('/some/file'));
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – askUser policy
  // ---------------------------------------------------------------------------
  group('enforce() – askUser policy', () {
    test('returns allow=true when handler approves', () async {
      final hook = enforce([
        askUser('create_file', handler: (_) async => true),
      ]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'create_file', args: {}),
      );
      expect(result.allow, isTrue);
    });

    test('returns allow=false when handler denies', () async {
      final hook = enforce([
        askUser('create_file', handler: (_) async => false),
      ]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'create_file', args: {}),
      );
      expect(result.allow, isFalse);
    });

    test('denial message mentions the tool name', () async {
      final hook = enforce([
        askUser('create_file', handler: (_) async => false),
      ]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'create_file', args: {}),
      );
      expect(result.message, contains('create_file'));
    });
  });

  // ---------------------------------------------------------------------------
  // enforce() – policy evaluation error handling
  // ---------------------------------------------------------------------------
  group('enforce() – error handling', () {
    test('returns allow=false if when clause throws', () async {
      final hook = enforce([
        deny('view_file', when: (_) async => throw Exception('bad when')),
        allow('*'),
      ]);
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isFalse);
      expect(result.message, contains('Policy evaluation failed'));
    });
  });

  // ---------------------------------------------------------------------------
  // workspaceOnly policy
  // ---------------------------------------------------------------------------
  group('workspaceOnly()', () {
    test('allows files inside workspace', () async {
      final hook = enforce(workspaceOnly(['/safe/workspace']));
      final result = await hook.run(
        HookContext(),
        ToolCall(
          name: 'view_file',
          args: {},
          canonicalPath: '/safe/workspace/src/main.dart',
        ),
      );
      expect(result.allow, isTrue);
    });

    test('denies files outside workspace', () async {
      final hook = enforce(workspaceOnly(['/safe/workspace']));
      final result = await hook.run(
        HookContext(),
        ToolCall(
          name: 'view_file',
          args: {},
          canonicalPath: '/unsafe/path/evil.dart',
        ),
      );
      expect(result.allow, isFalse);
      expect(result.message, contains('workspace_only'));
    });

    test('denies traversal attacks', () async {
      final hook = enforce(workspaceOnly(['/safe/workspace']));
      final result = await hook.run(
        HookContext(),
        ToolCall(
          name: 'view_file',
          args: {},
          canonicalPath: '/safe/workspace/../etc/passwd',
        ),
      );
      expect(result.allow, isFalse);
    });

    test('allows nested paths inside workspace', () async {
      final hook = enforce(workspaceOnly(['/proj']));
      final result = await hook.run(
        HookContext(),
        ToolCall(
          name: 'create_file',
          args: {},
          canonicalPath: '/proj/deep/nested/dir/file.txt',
        ),
      );
      expect(result.allow, isTrue);
    });

    test(
      'allows calls without canonicalPath (no path = no restriction)',
      () async {
        final hook = enforce(workspaceOnly(['/safe']));
        // No canonicalPath → outsideWorkspace returns false → policy not triggered
        final result = await hook.run(
          HookContext(),
          ToolCall(name: 'view_file', args: {}),
        );
        expect(result.allow, isTrue);
      },
    );

    test('allows files within any of multiple workspaces', () async {
      final hook = enforce(workspaceOnly(['/ws1', '/ws2']));

      final r1 = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}, canonicalPath: '/ws1/file.txt'),
      );
      expect(r1.allow, isTrue);

      final r2 = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}, canonicalPath: '/ws2/file.txt'),
      );
      expect(r2.allow, isTrue);
    });

    test('denies when path belongs to none of the workspaces', () async {
      final hook = enforce(workspaceOnly(['/ws1', '/ws2']));
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}, canonicalPath: '/ws3/file.txt'),
      );
      expect(result.allow, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isPathInWorkspace
  // ---------------------------------------------------------------------------
  group('isPathInWorkspace()', () {
    test('returns true for exact workspace root', () {
      expect(isPathInWorkspace('/workspace', '/workspace'), isTrue);
    });

    test('returns true for file directly in workspace', () {
      expect(isPathInWorkspace('/workspace/file.dart', '/workspace'), isTrue);
    });

    test('returns true for deeply nested path', () {
      expect(
        isPathInWorkspace('/workspace/a/b/c/file.dart', '/workspace'),
        isTrue,
      );
    });

    test('returns false for path outside workspace', () {
      expect(isPathInWorkspace('/other/file.dart', '/workspace'), isFalse);
    });

    test('returns false for path that traverses above workspace', () {
      expect(
        isPathInWorkspace('/workspace/../outside.dart', '/workspace'),
        isFalse,
      );
    });

    test('returns true for path with redundant ./ segments', () {
      expect(
        isPathInWorkspace('/workspace/src/../src/foo.dart', '/workspace'),
        isTrue,
      );
    });

    test('returns false when target is shallower than workspace', () {
      expect(isPathInWorkspace('/ws', '/ws/subdir'), isFalse);
    });

    test('returns false when workspace prefix is only partial match', () {
      // /workspace-extra should NOT count as inside /workspace
      expect(
        isPathInWorkspace('/workspace-extra/file.dart', '/workspace'),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // confirmRunCommand policy
  // ---------------------------------------------------------------------------
  group('confirmRunCommand()', () {
    test('denies run_command when no handler provided', () async {
      final hook = enforce(confirmRunCommand());
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'run_command', args: {'cmd': 'ls'}),
      );
      expect(result.allow, isFalse);
    });

    test('allows other tools when no handler provided', () async {
      final hook = enforce(confirmRunCommand());
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isTrue);
    });

    test('asks user for run_command when handler provided', () async {
      bool handlerCalled = false;
      final hook = enforce(
        confirmRunCommand(
          handler: (_) async {
            handlerCalled = true;
            return true;
          },
        ),
      );
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'run_command', args: {}),
      );
      expect(handlerCalled, isTrue);
      expect(result.allow, isTrue);
    });

    test('still allows view_file with handler present', () async {
      final hook = enforce(confirmRunCommand(handler: (_) async => false));
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'view_file', args: {}),
      );
      expect(result.allow, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // safeDefaults policy
  // ---------------------------------------------------------------------------
  group('safeDefaults()', () {
    test('allows read-only tools without prompting', () async {
      bool handlerCalled = false;
      final hook = enforce(
        safeDefaults((_) async {
          handlerCalled = true;
          return false;
        }),
      );
      for (final tool in BuiltinTools.readOnly()) {
        final result = await hook.run(
          HookContext(),
          ToolCall(name: tool.value, args: {}),
        );
        expect(result.allow, isTrue, reason: '${tool.value} should be allowed');
      }
      expect(handlerCalled, isFalse);
    });

    test('asks user for write tools', () async {
      bool handlerCalled = false;
      final hook = enforce(
        safeDefaults((_) async {
          handlerCalled = true;
          return true;
        }),
      );
      // run_command is not in readOnly → should ask user
      final result = await hook.run(
        HookContext(),
        ToolCall(name: 'run_command', args: {}),
      );
      expect(handlerCalled, isTrue);
      expect(result.allow, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // HookResult
  // ---------------------------------------------------------------------------
  group('HookResult', () {
    test('defaults to allow=true, empty message', () {
      final r = HookResult();
      expect(r.allow, isTrue);
      expect(r.message, isEmpty);
    });

    test('respects constructor arguments', () {
      final r = HookResult(allow: false, message: 'blocked');
      expect(r.allow, isFalse);
      expect(r.message, equals('blocked'));
    });
  });

  group('MCP Policies and 9-Level Priority', () {
    final mcpConfig = McpStdioServer(name: 'math', command: 'npx');
    final mcpConfigAdv = McpStdioServer(name: 'math_advanced', command: 'npx');

    test(
      'allow(mcpConfig) produces a single wildcard policy in server/* format',
      () {
        final policies = allow(mcpConfig);
        expect(policies, isA<List<Policy>>());
        final list = policies as List<Policy>;
        expect(list, hasLength(1));
        expect(list.first.tool, equals('math/*'));
        expect(list.first.decision, equals(Decision.approve));
      },
    );

    test(
      'allow(mcpConfig, mcpTools) produces policies in server/tool format',
      () {
        final policies = allow(mcpConfig, mcpTools: ['calc', 'multiply']);
        expect(policies, isA<List<Policy>>());
        final list = policies as List<Policy>;
        expect(list, hasLength(2));
        expect(list[0].tool, equals('math/calc'));
        expect(list[1].tool, equals('math/multiply'));
        expect(list[0].name, equals('approve_math_calc'));
      },
    );

    test(
      'deny(mcpConfig, mcpTools) produces policies in server/tool format',
      () {
        final policies = deny(mcpConfig, mcpTools: ['calc']);
        expect(policies, isA<List<Policy>>());
        final list = policies as List<Policy>;
        expect(list, hasLength(1));
        expect(list.first.tool, equals('math/calc'));
        expect(list.first.decision, equals(Decision.deny));
      },
    );

    test(
      'askUser(mcpConfig, mcpTools) produces policies in server/tool format with handler',
      () {
        final policies = askUser(
          mcpConfig,
          mcpTools: ['calc'],
          handler: (_) async => true,
        );
        expect(policies, isA<List<Policy>>());
        final list = policies as List<Policy>;
        expect(list, hasLength(1));
        expect(list.first.tool, equals('math/calc'));
        expect(list.first.decision, equals(Decision.askUser));
        expect(list.first.askUser, isNotNull);
      },
    );

    test(
      'enforce() throws ArgumentError if MCP policies exist but mcpServers is missing/empty',
      () {
        final policies = allow(mcpConfig);
        expect(
          () => enforce(policies as List<Policy>),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('enforce() flattens nested lists of policies', () {
      final List<dynamic> policies = [
        allow('read_file'),
        allow(mcpConfig), // returns List<Policy>
      ];
      expect(() => enforce(policies, mcpServers: [mcpConfig]), returnsNormally);
    });

    test('secure longest-match matching logic for similar prefixes', () async {
      final policies = [
        allow(mcpConfig), // math/*
        deny(mcpConfigAdv), // math_advanced/*
      ];
      final hook = enforce(policies, mcpServers: [mcpConfig, mcpConfigAdv]);
      final ctx = HookContext();

      final result1 = await hook.run(
        ctx,
        ToolCall(name: 'mcp_math_advanced_calc'),
      );
      expect(result1.allow, isFalse);

      final result2 = await hook.run(ctx, ToolCall(name: 'mcp_math_calc'));
      expect(result2.allow, isTrue);
    });

    test('9-level priority: specific allow beats prefix deny', () async {
      final policies = [
        allow(
          mcpConfig,
          mcpTools: ['calc'],
        ), // math/calc -> specific allow (level 2)
        deny(mcpConfig), // math/* -> prefix deny (level 3)
      ];
      final hook = enforce(policies, mcpServers: [mcpConfig]);
      final ctx = HookContext();

      final result1 = await hook.run(ctx, ToolCall(name: 'mcp_math_calc'));
      expect(result1.allow, isTrue);

      final result2 = await hook.run(ctx, ToolCall(name: 'mcp_math_multiply'));
      expect(result2.allow, isFalse);
    });

    test('enforce() rejects invalid types in list', () {
      final badPolicies1 = [
        allow('read_file'),
        ['not_a_policy'],
      ];
      expect(
        () => enforce(badPolicies1, mcpServers: [mcpConfig]),
        throwsA(isA<ArgumentError>()),
      );

      final badPolicies2 = [allow('read_file'), 123];
      expect(
        () => enforce(badPolicies2, mcpServers: [mcpConfig]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('unregistered server prefix treated as standard tool', () async {
      final policies = [allow('math/*')];
      final hook = enforce(policies, mcpServers: [mcpConfig]);
      final ctx = HookContext();

      final result = await hook.run(ctx, ToolCall(name: 'mcp_unknown_calc'));
      expect(result.allow, isTrue); // default open since no policy matches
    });
  });
}
