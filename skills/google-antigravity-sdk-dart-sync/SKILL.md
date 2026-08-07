---
name: google-antigravity-sdk-dart-sync
description: "Synchronize upstream Python SDK commits (v0.1.10), version strings, features, and test suites to Dart."
disable-model-invocation: true
---

# Python to Dart Synchronization Skill

Standard procedure for synchronizing features, bug fixes, updates, and package versions from the reference Python SDK repository (`antigravity-sdk-python` v0.1.10) to this Dart SDK.

## Core Sync Workflow

1. **SHA Range Discovery**:
   - Read last synced commit SHA from [`.last_synced_python_commit`](file://.last_synced_python_commit).
   - Locate modified files in the reference Python repository (`google/antigravity`) since that commit.

2. **Version Cascade**:
   - Update version string in [`pubspec.yaml`](file://pubspec.yaml).
   - Update badges in [`README.md`](file://README.md).
   - Update version constant in [`mcp_bridge.dart`](file://lib/src/mcp/mcp_bridge.dart).
   - Prepend new version entry in [`CHANGELOG.md`](file://CHANGELOG.md).

3. **Type & Paradigm Mapping**:
   - Map Python async methods to Dart `Future<T>` methods.
   - Map Python async generators to Dart streams (`Stream<T>`, `async*`, `yield`).
   - Translate Python `pytest` suites to native Dart `test` structures.

4. **Verification Pipeline**:
   ```bash
   dart pub get
   dart run build_runner build --delete-conflicting-outputs
   dart format .
   dart analyze --fatal-infos
   dart test
   ```

5. **State Finalization**:
   - Update [`.last_synced_python_commit`](file://.last_synced_python_commit) with target Python commit SHA.

## Completion Criteria

- [ ] Version strings in `pubspec.yaml`, `README.md`, `mcp_bridge.dart`, and `CHANGELOG.md` are aligned.
- [ ] `dart analyze --fatal-infos` passes with 0 diagnostics.
- [ ] `dart test` completes with 0 failures.
- [ ] `.last_synced_python_commit` records target upstream commit SHA.


