// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';
import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

void main() {
  group('MediaContent.fromBytes and MediaContent.fromFile statics', () {
    test('fromBytes resolves image, document, audio, and video types', () {
      final img = MediaContent.fromBytes([1, 2, 3], 'image/png',
          description: 'Sample PNG');
      expect(img, isA<Image>());
      expect(img.mimeType, equals('image/png'));
      expect(img.description, equals('Sample PNG'));

      final doc = MediaContent.fromBytes([4, 5, 6], 'application/pdf',
          description: 'Report');
      expect(doc, isA<Document>());
      expect(doc.mimeType, equals('application/pdf'));

      final audio = MediaContent.fromBytes([7, 8, 9], 'audio/mp3');
      expect(audio, isA<Audio>());
      expect(audio.mimeType, equals('audio/mp3'));

      final video = MediaContent.fromBytes([10, 11, 12], 'video/mp4');
      expect(video, isA<Video>());
      expect(video.mimeType, equals('video/mp4'));
    });

    test('fromBytes throws on unsupported MIME type', () {
      expect(
        () => MediaContent.fromBytes([1, 2, 3], 'application/octet-stream'),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('fromFile resolves file based on extension and path', () {
      final tempDir =
          Directory.systemTemp.createTempSync('antigravity_content_test');
      try {
        final imgFile = File('${tempDir.path}/test.png')
          ..writeAsBytesSync([1, 2, 3]);
        final media =
            MediaContent.fromFile(imgFile.path, description: 'Local image');
        expect(media, isA<Image>());
        expect(media.mimeType, equals('image/png'));
        expect(media.description, equals('Local image'));

        final docFile = File('${tempDir.path}/manual.pdf')
          ..writeAsBytesSync([4, 5, 6]);
        final doc = MediaContent.fromFile(docFile, description: 'User manual');
        expect(doc, isA<Document>());
        expect(doc.mimeType, equals('application/pdf'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
