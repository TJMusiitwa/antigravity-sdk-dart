import 'dart:io' if (dart.library.html) 'dart:async';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

import 'exceptions.dart';

part 'content.mapper.dart';

/// Image MIME types accepted by [Image].
const supportedImageMimes = {
  "image/bmp",
  "image/jpeg",
  "image/png",
  "image/webp",
};

/// Document MIME types accepted by [Document].
const supportedDocumentMimes = {
  "application/pdf",
  "application/json",
  "text/css",
  "text/csv",
  "text/html",
  "text/javascript",
  "text/plain",
  "text/rtf",
  "text/xml",
};

/// Audio MIME types accepted by [Audio].
const supportedAudioMimes = {
  "audio/wav",
  "audio/x-wav",
  "audio/wave",
  "audio/vnd.wave",
  "audio/mp3",
  "audio/mp4",
  "audio/webm",
  "audio/aac",
  "audio/ogg",
  "audio/flac",
  "audio/opus",
  "audio/mpeg",
  "audio/m4a",
  "audio/l16",
};

/// Video MIME types accepted by [Video].
const supportedVideoMimes = {
  "video/3gpp",
  "video/avi",
  "video/mp4",
  "video/mpeg",
  "video/mpg",
  "video/quicktime",
  "video/webm",
  "video/wmv",
  "video/x-flv",
};

const _extToMime = {
  '.bmp': 'image/bmp',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
  '.json': 'application/json',
  '.css': 'text/css',
  '.csv': 'text/csv',
  '.html': 'text/html',
  '.htm': 'text/html',
  '.js': 'text/javascript',
  '.txt': 'text/plain',
  '.rtf': 'text/rtf',
  '.xml': 'text/xml',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mp3',
  '.aac': 'audio/aac',
  '.ogg': 'audio/ogg',
  '.flac': 'audio/flac',
  '.opus': 'audio/opus',
  '.mpeg': 'audio/mpeg',
  '.m4a': 'audio/m4a',
  '.3gp': 'video/3gpp',
  '.avi': 'video/avi',
  '.mp4': 'video/mp4',
  '.mpg': 'video/mpeg',
  '.mov': 'video/quicktime',
  '.qt': 'video/quicktime',
  '.webm': 'video/webm',
  '.wmv': 'video/wmv',
  '.flv': 'video/x-flv',
};

String _guessMimeType(String path) {
  final ext = p.extension(path).toLowerCase();
  final mime = _extToMime[ext];
  if (mime == null) {
    throw AntigravityValidationException(
      "Could not infer a valid MIME type for extension: '$ext'",
    );
  }
  return mime;
}

/// Expands a leading `~` (the current user's home directory), like Python's
/// `Path.expanduser()`. Other paths are returned unchanged.
String _expandUser(String path) {
  if (path != '~' && !path.startsWith('~/') && !path.startsWith(r'~\')) {
    return path;
  }
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null || home.isEmpty) return path;
  return home + path.substring(1);
}

/// Trims surrounding whitespace and lowercases a MIME type string.
String _normalizeMime(String mimeType) => mimeType.trim().toLowerCase();

({String mime, Uint8List data}) _readFileAndMime(dynamic fileOrPath) {
  final path = _expandUser(
    fileOrPath is File ? fileOrPath.path : fileOrPath as String,
  );
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException("File not found", path);
  }
  final mime = _guessMimeType(path);
  final data = file.readAsBytesSync();
  return (mime: mime, data: data);
}

/// Base class for multimedia content attachments.
sealed class MediaContent {
  /// The MIME type, trimmed and lowercased (`' IMAGE/PNG '` becomes
  /// `'image/png'`).
  final String mimeType;

  /// Text description of the media.
  final String description;

  /// Raw media bytes.
  final List<int> data;

  /// Returns the underlying media data as a strongly-typed Dart [Uint8List].
  Uint8List get bytes => Uint8List.fromList(data);

  /// Creates a [MediaContent], normalizing [mimeType].
  MediaContent({
    required String mimeType,
    required this.description,
    required this.data,
  }) : mimeType = _normalizeMime(mimeType);

  /// Creates the media type that matches [mimeType], which is matched
  /// case-insensitively after trimming whitespace.
  static MediaContent fromBytes(
    List<int> data,
    String rawMimeType, {
    String description = '',
  }) {
    final mimeType = _normalizeMime(rawMimeType);
    if (supportedImageMimes.contains(mimeType)) {
      return Image(mimeType: mimeType, description: description, data: data);
    } else if (supportedDocumentMimes.contains(mimeType)) {
      return Document(mimeType: mimeType, description: description, data: data);
    } else if (supportedAudioMimes.contains(mimeType)) {
      return Audio(mimeType: mimeType, description: description, data: data);
    } else if (supportedVideoMimes.contains(mimeType)) {
      return Video(mimeType: mimeType, description: description, data: data);
    } else {
      throw AntigravityValidationException(
        "Unsupported MIME type: '$rawMimeType'",
      );
    }
  }

  /// Reads [fileOrPath] (a [File] or path; a leading `~` is expanded to the
  /// home directory) and creates the media type for its extension.
  static MediaContent fromFile(dynamic fileOrPath, {String description = ''}) {
    final fileData = _readFileAndMime(fileOrPath);
    final mime = fileData.mime;
    final data = fileData.data;

    if (supportedImageMimes.contains(mime)) {
      return Image(mimeType: mime, description: description, data: data);
    } else if (supportedDocumentMimes.contains(mime)) {
      return Document(mimeType: mime, description: description, data: data);
    } else if (supportedAudioMimes.contains(mime)) {
      return Audio(mimeType: mime, description: description, data: data);
    } else if (supportedVideoMimes.contains(mime)) {
      return Video(mimeType: mime, description: description, data: data);
    } else {
      throw AntigravityValidationException("Unsupported MIME type: '$mime'");
    }
  }
}

/// Image content attachment.
class Image extends MediaContent {
  /// Creates an [Image].
  ///
  /// Throws an [AntigravityValidationException] if [mimeType] is not in
  /// [supportedImageMimes].
  Image({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedImageMimes.contains(mimeType)) {
      throw AntigravityValidationException(
        "Unsupported Image MIME type: '$mimeType'",
      );
    }
  }

  /// Reads [fileOrPath] (a [File] or path; a leading `~` is expanded to the
  /// home directory) and creates an [Image], inferring the MIME type from the
  /// file extension.
  factory Image.fromFile(dynamic fileOrPath, {String description = ''}) {
    final fileData = _readFileAndMime(fileOrPath);
    if (!supportedImageMimes.contains(fileData.mime)) {
      throw AntigravityValidationException(
        "Unsupported Image MIME type: '${fileData.mime}'",
      );
    }
    return Image(
      mimeType: fileData.mime,
      description: description,
      data: fileData.data,
    );
  }
}

/// Document content attachment.
class Document extends MediaContent {
  /// Creates a [Document].
  ///
  /// Throws an [AntigravityValidationException] if [mimeType] is not in
  /// [supportedDocumentMimes].
  Document({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedDocumentMimes.contains(mimeType)) {
      throw AntigravityValidationException(
        "Unsupported Document MIME type: '$mimeType'",
      );
    }
  }

  /// Reads [fileOrPath] (a [File] or path; a leading `~` is expanded to the
  /// home directory) and creates a [Document], inferring the MIME type from
  /// the file extension.
  factory Document.fromFile(dynamic fileOrPath, {String description = ''}) {
    final fileData = _readFileAndMime(fileOrPath);
    if (!supportedDocumentMimes.contains(fileData.mime)) {
      throw AntigravityValidationException(
        "Unsupported Document MIME type: '${fileData.mime}'",
      );
    }
    return Document(
      mimeType: fileData.mime,
      description: description,
      data: fileData.data,
    );
  }
}

/// Audio content attachment.
class Audio extends MediaContent {
  /// Creates an [Audio].
  ///
  /// Throws an [AntigravityValidationException] if [mimeType] is not in
  /// [supportedAudioMimes].
  Audio({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedAudioMimes.contains(mimeType)) {
      throw AntigravityValidationException(
        "Unsupported Audio MIME type: '$mimeType'",
      );
    }
  }

  /// Reads [fileOrPath] (a [File] or path; a leading `~` is expanded to the
  /// home directory) and creates an [Audio], inferring the MIME type from the
  /// file extension.
  factory Audio.fromFile(dynamic fileOrPath, {String description = ''}) {
    final fileData = _readFileAndMime(fileOrPath);
    if (!supportedAudioMimes.contains(fileData.mime)) {
      throw AntigravityValidationException(
        "Unsupported Audio MIME type: '${fileData.mime}'",
      );
    }
    return Audio(
      mimeType: fileData.mime,
      description: description,
      data: fileData.data,
    );
  }
}

/// Video content attachment.
class Video extends MediaContent {
  /// Creates a [Video].
  ///
  /// Throws an [AntigravityValidationException] if [mimeType] is not in
  /// [supportedVideoMimes].
  Video({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedVideoMimes.contains(mimeType)) {
      throw AntigravityValidationException(
        "Unsupported Video MIME type: '$mimeType'",
      );
    }
  }

  /// Reads [fileOrPath] (a [File] or path; a leading `~` is expanded to the
  /// home directory) and creates a [Video], inferring the MIME type from the
  /// file extension.
  factory Video.fromFile(dynamic fileOrPath, {String description = ''}) {
    final fileData = _readFileAndMime(fileOrPath);
    if (!supportedVideoMimes.contains(fileData.mime)) {
      throw AntigravityValidationException(
        "Unsupported Video MIME type: '${fileData.mime}'",
      );
    }
    return Video(
      mimeType: fileData.mime,
      description: description,
      data: fileData.data,
    );
  }
}

/// Union representation of dynamic prompt inputs.
typedef ContentPrimitive =
    dynamic; // String, MediaContent, SlashCommand, or List<ContentPrimitive>

@MappableEnum(caseStyle: CaseStyle.snakeCase)
/// Supported built-in slash commands.
enum BuiltinSlashCommandName {
  /// Plans before executing a task: generates an implementation plan
  /// artifact and awaits user approval.
  @MappableValue('plan')
  plan('plan');

  /// The wire value of this command name.
  final String value;

  /// Creates a [BuiltinSlashCommandName] with the given wire [value].
  const BuiltinSlashCommandName(this.value);
}

/// Slash command prompt input.
@MappableClass()
class SlashCommand with SlashCommandMappable {
  /// Built-in command to run.
  final BuiltinSlashCommandName name;

  /// Creates a [SlashCommand] for [name].
  SlashCommand({required this.name});

  /// Decodes a [SlashCommand] from a map.
  static const fromMap = SlashCommandMapper.fromMap;

  /// Decodes a [SlashCommand] from a JSON string.
  static const fromJson = SlashCommandMapper.fromJson;
}
