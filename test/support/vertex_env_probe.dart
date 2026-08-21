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

/// Probe used by `types_test.dart` to observe [VertexEndpoint] construction
/// under real ambient environment variables.
///
/// `Platform.environment` is immutable within a Dart process, so the only way
/// to exercise the env-hydration branch of [VertexEndpoint] is to run this
/// probe as a subprocess with `GOOGLE_CLOUD_PROJECT` / `GOOGLE_CLOUD_LOCATION`
/// actually set. Pass `with-base-url` as the sole argument to construct the
/// endpoint with a custom `baseUrl`. Emits the resulting project/location as
/// JSON on stdout.
///
/// This file is intentionally not named `*_test.dart` so that `dart test`
/// does not pick it up as a suite.
library;

import 'dart:convert';
import 'dart:io';

import 'package:antigravity/antigravity.dart';

void main(List<String> args) {
  final withBaseUrl = args.contains('with-base-url');

  final endpoint = withBaseUrl
      ? VertexEndpoint(baseUrl: 'http://localhost:8080')
      : VertexEndpoint();

  stdout.writeln(jsonEncode({
    'project': endpoint.project,
    'location': endpoint.location,
    'baseUrl': endpoint.baseUrl,
  }));
}
