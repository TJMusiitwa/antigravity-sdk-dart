import 'dart:io' if (dart.library.html) 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

part 'content.mapper.dart';

const supportedImageMimes = {
  "image/bmp",
  "image/jpeg",
  "image/png",
  "image/webp",
};

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

const supportedAudioMimes = {
  "audio/wav",
  "audio/mp3",
  "audio/aac",
  "audio/ogg",
  "audio/flac",
  "audio/opus",
  "audio/mpeg",
  "audio/m4a",
  "audio/l16",
};

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
    throw ArgumentError(
      "Could not infer a valid MIME type for extension: '$ext'",
    );
  }
  return mime;
}

sealed class MediaContent {
  final String mimeType;
  final String description;
  final List<int> data;

  MediaContent({
    required this.mimeType,
    required this.description,
    required this.data,
  });

  static MediaContent fromBytes(
    List<int> data,
    String mimeType, {
    String description = '',
  }) {
    if (supportedImageMimes.contains(mimeType)) {
      return Image(mimeType: mimeType, description: description, data: data);
    } else if (supportedDocumentMimes.contains(mimeType)) {
      return Document(mimeType: mimeType, description: description, data: data);
    } else if (supportedAudioMimes.contains(mimeType)) {
      return Audio(mimeType: mimeType, description: description, data: data);
    } else if (supportedVideoMimes.contains(mimeType)) {
      return Video(mimeType: mimeType, description: description, data: data);
    } else {
      throw ArgumentError("Unsupported MIME type: '$mimeType'");
    }
  }

  static MediaContent fromFile(String path, {String description = ''}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", path);
    }
    final mime = _guessMimeType(path);
    final data = file.readAsBytesSync();

    if (supportedImageMimes.contains(mime)) {
      return Image(mimeType: mime, description: description, data: data);
    } else if (supportedDocumentMimes.contains(mime)) {
      return Document(mimeType: mime, description: description, data: data);
    } else if (supportedAudioMimes.contains(mime)) {
      return Audio(mimeType: mime, description: description, data: data);
    } else if (supportedVideoMimes.contains(mime)) {
      return Video(mimeType: mime, description: description, data: data);
    } else {
      throw ArgumentError("Unsupported MIME type: '$mime'");
    }
  }
}

class Image extends MediaContent {
  Image({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedImageMimes.contains(mimeType)) {
      throw ArgumentError("Unsupported Image MIME type: '$mimeType'");
    }
  }

  factory Image.fromFile(String path, {String description = ''}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", path);
    }
    final mime = _guessMimeType(path);
    if (!supportedImageMimes.contains(mime)) {
      throw ArgumentError("Unsupported Image MIME type: '$mime'");
    }
    final data = file.readAsBytesSync();
    return Image(mimeType: mime, description: description, data: data);
  }
}

class Document extends MediaContent {
  Document({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedDocumentMimes.contains(mimeType)) {
      throw ArgumentError("Unsupported Document MIME type: '$mimeType'");
    }
  }

  factory Document.fromFile(String path, {String description = ''}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", path);
    }
    final mime = _guessMimeType(path);
    if (!supportedDocumentMimes.contains(mime)) {
      throw ArgumentError("Unsupported Document MIME type: '$mime'");
    }
    final data = file.readAsBytesSync();
    return Document(mimeType: mime, description: description, data: data);
  }
}

class Audio extends MediaContent {
  Audio({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedAudioMimes.contains(mimeType)) {
      throw ArgumentError("Unsupported Audio MIME type: '$mimeType'");
    }
  }

  factory Audio.fromFile(String path, {String description = ''}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", path);
    }
    final mime = _guessMimeType(path);
    if (!supportedAudioMimes.contains(mime)) {
      throw ArgumentError("Unsupported Audio MIME type: '$mime'");
    }
    final data = file.readAsBytesSync();
    return Audio(mimeType: mime, description: description, data: data);
  }
}

class Video extends MediaContent {
  Video({
    required super.mimeType,
    required super.description,
    required super.data,
  }) {
    if (!supportedVideoMimes.contains(mimeType)) {
      throw ArgumentError("Unsupported Video MIME type: '$mimeType'");
    }
  }

  factory Video.fromFile(String path, {String description = ''}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", path);
    }
    final mime = _guessMimeType(path);
    if (!supportedVideoMimes.contains(mime)) {
      throw ArgumentError("Unsupported Video MIME type: '$mime'");
    }
    final data = file.readAsBytesSync();
    return Video(mimeType: mime, description: description, data: data);
  }
}

/// Union representation of dynamic prompt inputs.
typedef ContentPrimitive
    = dynamic; // String, MediaContent, SlashCommand, or List<ContentPrimitive>

@MappableEnum(caseStyle: CaseStyle.snakeCase)
enum BuiltinSlashCommandName {
  @MappableValue('plan')
  plan('plan');

  final String value;
  const BuiltinSlashCommandName(this.value);
}

@MappableClass()
class SlashCommand with SlashCommandMappable {
  final BuiltinSlashCommandName name;

  SlashCommand({required this.name});

  static const fromMap = SlashCommandMapper.fromMap;
  static const fromJson = SlashCommandMapper.fromJson;
}
