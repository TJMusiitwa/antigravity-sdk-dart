/// Kind of filesystem change detected by a file-watching trigger.
enum FileChangeKind {
  /// A file was added.
  added('added'),

  /// A file was modified.
  modified('modified'),

  /// A file was deleted.
  deleted('deleted');

  /// The wire string for this kind.
  final String value;
  const FileChangeKind(this.value);
}

/// A single filesystem change detected by a file-watching trigger.
class FileChange {
  /// The type of change.
  final FileChangeKind kind;

  /// The path of the changed file, as reported by the file system watcher.
  final String path;

  /// Creates a [FileChange] of [kind] at [path].
  FileChange({required this.kind, required this.path});
}
