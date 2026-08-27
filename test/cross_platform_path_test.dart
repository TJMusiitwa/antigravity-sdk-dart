import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity/antigravity.dart';

void main() {
  setUp(() {
    BinaryDiscovery.environmentOverride = {
      'HOME': '/nonexistent-home',
      'USERPROFILE': '/nonexistent-userprofile',
      'PATH': '',
    };
  });

  tearDown(() {
    BinaryDiscovery.environmentOverride = null;
  });

  group('Cross-Platform Path Logic (package:path)', () {
    test('isPathInWorkspace handles POSIX paths correctly', () {
      final workspace = '/Users/dev/project';

      // We expect the internal isPathInWorkspace to use the current platform,
      // but we can verify the logic principles.
      expect(
        isPathInWorkspace('/Users/dev/project/file.txt', workspace),
        isTrue,
      );
      expect(
        isPathInWorkspace('/Users/dev/other/file.txt', workspace),
        isFalse,
      );
    });

    test('isPathInWorkspace handles relative path normalization', () {
      final workspace = Directory.current.absolute.path;
      final relativePath = p.join(workspace, 'test', '..', 'lib');

      expect(isPathInWorkspace(relativePath, workspace), isTrue);
    });
  });

  group('Workspace path normalization', () {
    test('normalizes relative workspace paths to absolute paths', () {
      final cwd = Directory.current.absolute.path;
      expect(normalizeWorkspacePath('.'), equals(cwd));
      expect(normalizeWorkspacePath('./test'), equals(p.join(cwd, 'test')));
      expect(normalizeWorkspacePaths(['.', 'test']),
          equals([cwd, p.join(cwd, 'test')]));
    });

    test('normalizes file:// URIs', () {
      expect(normalizeWorkspacePath('file:///tmp/workspace'),
          equals('/tmp/workspace'));
    });

    test('normalizes user home paths (~)', () {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (home.isNotEmpty) {
        expect(normalizeWorkspacePath('~/my-project'),
            equals(p.join(home, 'my-project')));
      }
    });

    test('preserves /cns/ paths', () {
      expect(normalizeWorkspacePath('/cns/test-cell/workspace'),
          equals('/cns/test-cell/workspace'));
    });

    test(
        'defaults to current working directory when null and defaultToCwd is true',
        () {
      final cwd = Directory.current.absolute.path;
      expect(normalizeWorkspacePaths(null, defaultToCwd: true), equals([cwd]));
      expect(normalizeWorkspacePaths(null, defaultToCwd: false), equals([]));
    });

    test('does not treat a Windows drive letter as a URI scheme', () {
      // Uri.tryParse(r'C:\dir') reports scheme 'c', so without an explicit
      // drive-letter guard the function would return the path unnormalized.
      // On Windows the guard yields a real absolute path; on POSIX hosts a
      // Windows path is meaningless, so we only assert it is not passed
      // through untouched (the bug this guard exists to prevent).
      const winPath = r'C:\Users\foo\..\bar';
      final normalized = normalizeWorkspacePath(winPath);

      expect(normalized, isNot(equals(winPath)),
          reason: 'drive-letter path must not be returned verbatim');

      if (Platform.isWindows) {
        expect(normalized, equals(p.normalize(r'C:\Users\bar')));
      } else {
        // On POSIX a backslash is not a separator, so the whole drive-letter
        // string stays one segment; the point is only that it was resolved
        // rather than returned verbatim.
        expect(normalized, startsWith(Directory.current.absolute.path));
      }
    });

    test('collapses parent-directory segments in relative paths', () {
      final cwd = Directory.current.absolute.path;
      expect(normalizeWorkspacePath('./a/../b'), equals(p.join(cwd, 'b')));
      expect(normalizeWorkspacePath('a/b/../..'), equals(cwd));
    });

    test('passes non-file URI schemes through untouched', () {
      expect(normalizeWorkspacePath('https://example.com/x'),
          equals('https://example.com/x'));
    });
  });

  group('BinaryDiscovery edge cases', () {
    test('discover throws descriptive exception when not found', () async {
      expect(
        BinaryDiscovery.discover(
          configPath: '/non/existent/path/to/agy',
          autoDownload: false,
        ),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('AntigravityBinaryNotFoundException') &&
                e.toString().contains('Priority paths checked'),
          ),
        ),
      );
    });
  });
}
