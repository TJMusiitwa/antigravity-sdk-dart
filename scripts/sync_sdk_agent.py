import asyncio
import os
from google.antigravity import Agent, GeminiAPIEndpoint, LocalAgentConfig, types
from google.antigravity.hooks import policy

async def main() -> None:
    # Verify GEMINI_API_KEY is present
    if not os.environ.get("GEMINI_API_KEY"):
        print("Error: GEMINI_API_KEY environment variable is not set.")
        return

    # Configure endpoint with specified thinking level
    thinking_level_str = os.environ.get("AGENT_THINKING_LEVEL", "extra_high")
    thinking_level = types.ThinkingLevel.from_string(thinking_level_str)
    endpoint = GeminiAPIEndpoint(
        options=types.GeminiModelOptions(thinking_level=thinking_level)
    )

    # Create config allowing the agent to run commands and edit files autonomously
    # (policy.allow_all() removes the manual confirmation guardrail for run_command)
    config = LocalAgentConfig(
        policies=[policy.allow_all()],
        model=os.environ.get("AGENT_MODEL", "gemini-3.7-flash"),
        endpoint=endpoint,
    )

    # Prompt describing the exact goal, validation targets, and rules
    prompt = """
    You are an autonomous developer agent. Your task is to synchronize updates from the Python SDK
    repository to this Dart SDK repository.

    GROUND RULES (apply throughout):
    - Never type a commit SHA, version string, or file list from memory. Every such value must come from
      command output you have just run in this session, and must be written to disk by redirecting that output.
    - The upstream source under `python-sdk/google/antigravity/` is the only authority. If GitHub release notes,
      discussions, or changelogs disagree with the code, the code wins. Note the discrepancy in your summary;
      do not implement the notes.
    - No scope creep. Do not add fields, wire keys, tool entries, or fallback logic that the upstream diff does
      not contain. If you believe something extra is needed, propose it in the summary instead of shipping it.
    - Do not claim work you did not verify. Every line of your final summary must correspond to something you
      re-read or re-ran after making the change.

    Follow these step-by-step instructions:

    1. Pull the latest Python SDK changes: `git -C python-sdk checkout main && git -C python-sdk pull --ff-only`.
       Report the resulting `git -C python-sdk log -1 --oneline`.

    2. ESTABLISH THE SYNC RANGE (mechanically — do not transcribe hashes by hand):
       - `OLD=$(cat dart-sdk/.last_synced_python_commit)`. If the file is missing, stop and ask which commit to
         start from — do not guess.
       - `git -C python-sdk cat-file -e "$OLD^{commit}"` — this MUST succeed. If it fails, the recorded SHA is
         corrupt or does not exist upstream: stop and report it rather than picking a nearby commit.
       - `NEW=$(git -C python-sdk rev-parse HEAD)` — always the full 40-character SHA, never abbreviated.
       - If syncing to a tag, resolve it with `git -C python-sdk rev-parse "v0.1.11^{commit}"`. A bare
         `git rev-parse v0.1.11` on an annotated tag yields the TAG OBJECT, not the commit, and will record a
         hash that does not exist upstream.
       - `git -C python-sdk log --oneline "$OLD".."$NEW"` and
         `git -C python-sdk diff --stat "$OLD".."$NEW" -- google/antigravity/`
       - If the range is empty, stop and report that the SDKs are already in sync.

    3. Read `dart-sdk/skills/google-antigravity-sdk-dart-sync/SKILL.md` before editing anything. It is the
       documented sync procedure and takes precedence over this prompt where they conflict. You are also
       responsible for keeping it accurate — see step 7.

    4. VERSION CASCADE. Read the current version from `dart-sdk/pubspec.yaml` and increment the minor version
       (e.g. `0.8.0` -> `0.9.0`). Apply the new version to EVERY location below:
       - `dart-sdk/pubspec.yaml` — the `version:` field.
       - `dart-sdk/lib/src/mcp/mcp_bridge.dart` — the hardcoded version in the `Implementation` instantiation.
       - `dart-sdk/lib/src/connections/local/local_connection.dart` — `clientVersion`.
       - `dart-sdk/README.md` — pub.dev version badge(s).
       - `dart-sdk/CHANGELOG.md` — prepend a new release entry. Focus on changes relevant to the Dart package
         (newly translated APIs, Dart-specific improvements, testing changes), not raw Python commit messages.
       Separately, `dart-sdk/lib/src/utils/harness_downloader.dart` -> `defaultVersion` tracks the UPSTREAM
       harness/Python release (e.g. `0.1.11`), not the Dart package version. Update it from the upstream tag, and
       update the matching fixtures in `dart-sdk/test/binary_discovery_test.dart`.
       Prove nothing was missed: `grep -rn "<old-version>" dart-sdk/lib dart-sdk/bin dart-sdk/README.md
       dart-sdk/pubspec.yaml` must return zero hits.

    5. TRANSLATE CHANGES. For each modified or new Python file under `python-sdk/google/antigravity`:
       - Map the path to the Dart equivalent under `dart-sdk/lib/src` or `dart-sdk/test`
         (e.g. `google/antigravity/agent.py` -> `lib/src/agent.dart`).
       - Translate idiomatically, maintaining Dart coding patterns and package layout, and using `dart_mappable`
         serialization where applicable.
       - Translate corresponding Python test files to the native Dart `test` package framework.

    6. PARITY CHECKLIST. This is a list of BUG CLASSES, not a list of known bugs. Each item names a category of
       divergence that survives `dart analyze` and `dart test` and only fails at runtime against a real harness.
       The parenthesised examples come from past syncs and are ILLUSTRATIVE ONLY — never treat an example as the
       scope of its item. Apply every item to every symbol the current diff touches, and state the result per item
       in your summary, including "not applicable this sync" where that is the honest answer.

       CONTRACT PARITY — anything crossing the process boundary between the SDK and the harness:
       a. WIRE FIELD NAMES. Diff every map key your serializer emits, and every key your parser reads, against the
          Python proto/dict keys character for character (snake_case on the wire, camelCase in Dart). Emit exactly
          one key per field — never a new key AND a legacy alias, and never a legacy key carrying new values.
       b. ENUM WIRE VALUES. For every new or changed enum, compare the Dart serialized form and parser against the
          exact strings Python emits and accepts, including any prefix convention the upstream proto uses
          (e.g. `STOP_REASON_*`, `AGENT_BEHAVIOR_*`). Follow the existing repo idiom of accepting both prefixed and
          bare forms. A parser whose every input falls through to the default/unspecified case is dead code that
          unit tests will happily pass — see item (m).
       c. SHARED KEY / CONSTANT LISTS. When upstream adds a value to a module-level collection (e.g. a list of
          argument keys to normalize, a set of tool names, a default allowlist), find every Dart counterpart and
          update it. Grep upstream for the new literal to find every collection it joined, not just the first.
       d. MESSAGE & EVENT SHAPES. Compare the full structure of each request/response/event: nesting depth, whether
          a payload is inlined or wrapped, and whether upstream collapsed or split two variants into one. A rename
          at the envelope level is as breaking as a rename at the field level.

       SEMANTIC PARITY — same signature, different behavior:
       e. DEFAULTS. Compare default values field by field, including defaults that live in a factory or validator
          rather than the field declaration.
       f. VALIDATION BOUNDS. Match Pydantic `ge`/`le`/`gt`/`lt`/`min_length`/`max_length` exactly, including upper
          bounds that are easy to skip. Pull such limits into named Dart constants, not bare literals.
       g. VALIDATION GUARDS & ERRORS. If upstream raises for an invalid combination, port that raise — with a
          comparable message — and check whether the guard applies to EVERY class carrying the field, not just the
          first one you edited.
       h. NULLABILITY, OPTIONALITY & ORDERING. Required-vs-optional, null-means-X semantics, and any order upstream
          guarantees (event emission, list ordering, validation sequence) must survive translation.

       SURFACE PARITY — what a Dart consumer sees:
       i. PUBLIC API & EXPORTS. Any new public type must be exported from `dart-sdk/lib/antigravity.dart`, or
          consumers cannot reach it. Do not change existing public signatures unless upstream changed theirs.
       j. DEPRECATION & ALIASES. When renaming a public symbol, add a typedef/legacy parameter for source
          compatibility — but the WIRE FORMAT and the DOCUMENTATION must use the new name only.
       k. DOC COMMENTS. If a parameter changes required->optional, gains null-means-X behavior, or changes units or
          bounds, update its doc comment in the same edit.

       COVERAGE:
       l. REMOVALS & DELETIONS. Upstream deletions are part of the diff. Port removed fields, files, and behaviors
          rather than silently keeping the Dart side ahead of upstream.
       m. WIRE-LEVEL TEST COVERAGE. For each new feature, at least one test must exercise the UPSTREAM WIRE
          REPRESENTATION — a literal payload/string as the harness would send it — not just the Dart constructor.
          Constructor-only tests cannot detect items (a) through (d).

       n. ANYTHING ELSE THAT CROSSES THE BOUNDARY. This checklist is meant to grow. If you find a divergence class
          not covered above, fix it AND append it as a new item to the parity checklist in
          `dart-sdk/skills/google-antigravity-sdk-dart-sync/SKILL.md`, so the next sync inherits what this one learned.

    7. UPDATE THE REPO'S OWN DOCUMENTATION. The files under `dart-sdk/skills/` document the preferred API and the
       sync baseline, and go stale on exactly the changes this task makes. Grep for and update stale references:
       `grep -rn "<old-upstream-version>\\|<old-default-model>\\|<renamed-symbol>" dart-sdk/skills dart-sdk/README.md dart-sdk/example`
       - `skills/google-antigravity-sdk-dart-sync/SKILL.md` — bump the upstream version it pins, and add any newly
         discovered version location to its cascade table.
       - Any other skill referencing a default model, enum name, or API spelling you changed.
       - `README.md` and `example/README.md` — default model, new features, examples table.

    8. VERIFY THE CODE (inside `dart-sdk`):
       - `dart pub get`
       - `dart run build_runner build --delete-conflicting-outputs`
       - `dart format --output=none --set-exit-if-changed .`
       - `dart analyze --fatal-infos`
       - `dart test`
       - `dart analyze` over every file in `example/getting_started/`.
       Green tests are necessary, not sufficient: for each new feature, confirm at least one test exercises the
       UPSTREAM WIRE REPRESENTATION, not just the Dart constructor.

    9. If any analysis or tests fail, examine the errors, edit the Dart code to fix the issues, and re-run
       verification until all checks pass.

    10. SELF-AUDIT before reporting. Re-read `git -C python-sdk diff "$OLD".."$NEW" -- google/antigravity/`
        against your changes and answer explicitly in the summary:
        - Which upstream hunks did I NOT port, and why?
        - Which of my changes have NO corresponding upstream hunk? (Justify or revert.)
        - Which parity-checklist items did I verify by reading code, versus assume?

    11. FINALIZE THE SYNC MARKER (mechanically). Once and only once everything builds and passes:
        - `git -C python-sdk rev-parse HEAD > dart-sdk/.last_synced_python_commit`
          (write it with this command — never by typing the hash)
        - Prove it round-trips, and paste both outputs into your summary:
          `NEW=$(cat dart-sdk/.last_synced_python_commit)`
          `git -C python-sdk cat-file -e "$NEW^{commit}" && echo "OK: $NEW"`
          `git -C python-sdk describe --tags --exact-match "$NEW" || echo "note: not an exact tag"`
        - If `cat-file -e` fails, the file is wrong — fix it before reporting.

    12. Inform me when the task is complete. The summary must state: the new Dart version; the old and new upstream
        SHAs (both full, as printed by git); which files were translated; which documentation/skills were updated;
        the verification output; the self-audit answers; and any upstream behavior deliberately not ported, stated
        plainly rather than omitted.
    """

    print("Starting Antigravity SDK Local Agent session...")
    async with Agent(config) as sync_agent:
        response = await sync_agent.chat(prompt)
        response_text = await response.text()
        print("\n=== Sync Agent Execution Summary ===")
        print(response_text)

        # Write the summary to a file outside the git repository (in the workspace root)
        # so it doesn't get committed to git, but can be read by GitHub Actions.
        dart_sdk_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        workspace_dir = os.path.dirname(dart_sdk_dir)
        summary_file = os.path.join(workspace_dir, "sync_summary.txt")
        
        with open(summary_file, "w") as f:
            f.write(response_text)
        print(f"Agent summary written to {summary_file}")

if __name__ == "__main__":
    asyncio.run(main())
