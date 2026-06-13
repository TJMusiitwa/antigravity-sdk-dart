/// Kind of filesystem change detected by a file-watching trigger.
enum FileChangeKind {
  added('added'),
  modified('modified'),
  deleted('deleted');

  final String value;
  const FileChangeKind(this.value);
}

/// A single filesystem change detected by a file-watching trigger.
class FileChange {
  final FileChangeKind kind;
  final String path;

  FileChange({required this.kind, required this.path});
}
