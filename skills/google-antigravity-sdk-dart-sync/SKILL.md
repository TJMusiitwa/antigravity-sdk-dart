---
name: google-antigravity-sdk-dart-sync
description: "Guidelines and procedures for synchronizing changes from the upstream Python SDK to the Dart SDK."
---

# Google Antigravity SDK - Python to Dart Synchronization Skill

This skill contains standard procedures and guidelines for synchronizing features, bug fixes, updates, and package versions from the reference Python SDK repository (`antigravity-sdk-python`) to this Dart SDK.

## Core Sync Workflow

When upstream updates are detected, perform the following steps:

1.  **Determine the Synchronization Range**:
    *   Read the last synced commit hash from [`.last_synced_python_commit`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/.last_synced_python_commit).
    *   Compare with the latest commit on the `main` branch of the Python repository to locate all modified files under `google/antigravity`.

2.  **Synchronize Package Version**:
    *   Find the updated version in Python's `pyproject.toml` (under `[project]` -> `version`).
    *   Propagate the version change to:
        *   [`pubspec.yaml`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/pubspec.yaml) (under `version:`).
        *   [`README.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/README.md) (updating badges).
        *   The hardcoded version in [`mcp_bridge.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/lib/src/mcp/mcp_bridge.dart) (or equivalent MCP implementation class).
        *   [`CHANGELOG.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/CHANGELOG.md) (prepend a new section describing the sync changes).

3.  **Code Translation Guidelines**:
    *   **Asynchronous Patterns**:
        *   Map Python `async/await` to Dart `async/await` (`Future<T>`).
        *   Map Python async generators (`async def ... yield`) to Dart `Stream<T>` (`async*` and `yield`).
    *   **Data Models & Serialization**:
        *   Map Python `dataclasses` or `pydantic` models to Dart models.
        *   If `dart_mappable` is used, ensure `@MappableClass()` annotations are added and run the generator.
    *   **Lifecycle and Context Managers**:
        *   Map Python's `async with` block (context managers) to Dart's `try-finally` blocks or structured resource close callbacks.
    *   **Test Cases**:
        *   Translate `pytest` test suites to native Dart `test` framework structures using `group()` and `test()`.

4.  **Verification Pipeline**:
    *   Run dependencies update:
        ```bash
        dart pub get
        ```
    *   Generate code (if using build generators):
        ```bash
        dart run build_runner build --delete-conflicting-outputs
        ```
    *   Format files:
        ```bash
        dart format .
        ```
    *   Run static analysis:
        ```bash
        dart analyze --fatal-infos
        ```
    *   Run tests:
        ```bash
        dart test
        ```

5.  **Finalize Sync**:
    *   Upon successful compilation and verification, update [`.last_synced_python_commit`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/.last_synced_python_commit) with the latest Python commit hash.
