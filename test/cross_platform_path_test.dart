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
