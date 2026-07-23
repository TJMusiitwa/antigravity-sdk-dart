---
name: google-antigravity-sdk-dart-sync
description: "Procedure for synchronizing upstream Python SDK commits, version strings, and feature updates to the Dart SDK."
disable-model-invocation: true
---

# Google Antigravity SDK - Python to Dart Synchronization Skill

Standard procedure for synchronizing features, bug fixes, updates, and package versions from the reference Python SDK repository (`antigravity-sdk-python`) to this Dart SDK.

## Core Sync Workflow

1.  **Determine Synchronization Range**:
    - Read the last synced commit SHA from [`.last_synced_python_commit`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/.last_synced_python_commit).
    - Locate modified files in the Python repository (`google/antigravity`) since that commit.

2.  **Synchronize Version Strings**:
    - Update version in [`pubspec.yaml`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/pubspec.yaml).
    - Update badges in [`README.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/README.md).
    - Update hardcoded version in [`mcp_bridge.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/lib/src/mcp/mcp_bridge.dart).
    - Prepend new entry to [`CHANGELOG.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/CHANGELOG.md).

3.  **Translate Code**:
    - Map Python `async/await` to Dart `async/await` (`Future<T>`).
    - Map Python async generators to Dart streams (`async*` and `yield`).
    - Translate `pytest` test suites to native `test` framework structures.

4.  **Execute Verification Pipeline**:
    ```bash
    dart pub get
    dart run build_runner build --delete-conflicting-outputs
    dart format .
    dart analyze --fatal-infos
    dart test
    ```

5.  **Finalize Sync**:
    - Record latest Python commit hash in [`.last_synced_python_commit`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/.last_synced_python_commit).

## Completion Criteria

- [ ] Version strings in `pubspec.yaml`, `README.md`, `mcp_bridge.dart`, and `CHANGELOG.md` are in sync.
- [ ] `dart analyze --fatal-infos` completes with 0 errors/warnings.
- [ ] `dart test` passes all tests with 0 failures.
- [ ] `.last_synced_python_commit` is updated with the target upstream commit SHA.
