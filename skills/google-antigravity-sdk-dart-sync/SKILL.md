---
name: google-antigravity-sdk-dart-sync
description: "Synchronize upstream Python SDK commits (v0.1.21), version strings, features, and test suites to Dart."
disable-model-invocation: true
---

# Python to Dart Synchronization Skill

Standard procedure for synchronizing features, bug fixes, updates, and package versions from the reference Python SDK repository (`antigravity-sdk-python` v0.1.21) to this Dart SDK.

## Core Sync Workflow

1. **SHA Range Discovery**:
   - Read last synced commit SHA from [`.last_synced_python_commit`](file://.last_synced_python_commit).
   - Locate modified files in the reference Python repository (`google/antigravity`) since that commit.

2. **Version Cascade**:
   - Update package version string in [`pubspec.yaml`](file://pubspec.yaml).
   - Update SDK version constant `packageVersion` in [`lib/src/version.dart`](file://lib/src/version.dart) (referenced by `lib/src/mcp/mcp_bridge.dart` and `lib/src/connections/local/local_connection.dart` clientVersion).
   - Update default binary harness version `HarnessDownloader.defaultVersion` in [`lib/src/utils/harness_downloader.dart`](file://lib/src/utils/harness_downloader.dart).
   - Update badges and tables in [`README.md`](file://README.md).
   - Prepend new version entry in [`CHANGELOG.md`](file://CHANGELOG.md).

3. **Type & Paradigm Mapping**:
   - Keep `CompactionConfig.tokenThreshold` aligned with the upstream `token_threshold` wire field.
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

- [ ] Version strings in `pubspec.yaml`, `lib/src/version.dart`, `HarnessDownloader.defaultVersion`, `README.md`, and `CHANGELOG.md` are aligned.
- [ ] `dart analyze --fatal-infos` passes with 0 diagnostics.
- [ ] `dart test` completes with 0 failures.
- [ ] `.last_synced_python_commit` records target upstream commit SHA.


## Source authority and range safety

- Treat the checked-out upstream source as authoritative over release notes.
- Read the recorded SHA and prove it exists with `git cat-file -e "$sha^{commit}"`.
  Stop on a missing or invalid marker; do not infer a nearby baseline.
- Resolve a requested tag using `git rev-parse "$tag^{commit}"` and review the
  entire marker-to-target range, including intervening releases.
- Compute version increments from `pubspec.yaml`; derive the harness release from
  upstream metadata. Never hand-transcribe commit IDs into the marker.
- The version constant drives MCP and handshake versions. The README pub.dev badge
  is dynamic, but its current-release text and the changelog must be updated.
- Update `test/binary_discovery_test.dart` alongside the harness version.
- Read the previous release's changelog entry before syncing: exclusions it
  lists remain outstanding even after the baseline advances. A newer empty diff
  does not imply those APIs have been implemented.

## Parity checklist

For every touched symbol, read the source and report evidence for each item in
the sync summary; state "not applicable" only where verified.

| Item | Required comparison |
| --- | --- |
| a. Wire names | Exact serializer/parser keys, one spelling per emitted field. |
| b. Enum values | Exact proto prefixes, accepted strings, and default handling. |
| c. Shared constants | Every tool set, normalization key list, and allowlist counterpart. |
| d. Message shapes | Nesting, envelope discriminators, inline versus wrapped payloads. |
| e. Defaults | Fields, constructors, factories, and validators. |
| f. Bounds | All numeric/string/collection limits, including upper bounds. |
| g. Guards/errors | Invalid combinations on every config class carrying the fields. |
| h. Null/order | Null semantics, optionality, event ordering, and collection ordering. |
| i. Exports | Consumer access through antigravity.dart and applicable beta entry points. |
| j. Aliases | Preserve source aliases when renaming; emit only current wire names. |
| k. Doc comments | New defaults, units, bounds, optionality, and behavioral caveats. |
| l. Removals | Deleted fields/behavior and renamed files, not just additions. |
| m. Wire tests | At least one literal upstream payload assertion for each wire feature. |
| n. Additional boundary risks | Fix and add any new category not covered above. |
| o. Parallel transports | Apply items a–d to every wire protocol separately: the localharness protocol (`LocalConnection`) and GAOS Interactions JSON (`InteractionsConnection`) use different keys and enum spellings for the same config. |
| p. Mapper constructors | `dart_mappable` encodes fields with the mapped constructor's parameter types and cannot use private constructors; widening a mapped parameter (for example to a shorthand interface) breaks `toJson`. Round-trip every changed config. |

## Final audit

- List each changed upstream file and its Dart disposition, including exclusions.
- Explain Dart changes without a direct upstream hunk; revert unjustified scope.
- Run dependency resolution, mapper generation, formatting verification,
  `dart analyze --fatal-infos`, the full test suite, and analysis of
  `example/getting_started/`.
- State whether live-harness behavior was tested; mocks do not establish it.
- Only after checks pass, redirect `git rev-parse HEAD` from the target upstream
  checkout into the marker, then prove it with `cat-file -e` and
  `describe --tags --exact-match`. Include both outputs in the sync summary.
