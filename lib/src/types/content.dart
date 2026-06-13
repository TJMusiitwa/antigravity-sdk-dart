abstract class MediaContent {
  final String mimeType;
  final String description;
  final List<int> data;

  MediaContent({
    required this.mimeType,
    required this.description,
    required this.data,
  });
}

class Image extends MediaContent {
  Image({
    required super.mimeType,
    required super.description,
    required super.data,
  });
}

class Document extends MediaContent {
  Document({
    required super.mimeType,
    required super.description,
    required super.data,
  });
}

class Audio extends MediaContent {
  Audio({
    required super.mimeType,
    required super.description,
    required super.data,
  });
}

class Video extends MediaContent {
  Video({
    required super.mimeType,
    required super.description,
    required super.data,
  });
}

/// Union representation of dynamic prompt inputs.
typedef ContentPrimitive =
    dynamic; // String, MediaContent, or List<ContentPrimitive>
