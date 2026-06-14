import asyncio
import os
from google.antigravity import Agent, LocalAgentConfig
from google.antigravity.hooks import policy

async def main() -> None:
    # Verify GEMINI_API_KEY is present
    if not os.environ.get("GEMINI_API_KEY"):
        print("Error: GEMINI_API_KEY environment variable is not set.")
        return

    # Create config allowing the agent to run commands and edit files autonomously
    # (policy.allow_all() removes the manual confirmation guardrail for run_command)
    config = LocalAgentConfig(
        policies=[policy.allow_all()],
        model=os.environ.get("AGENT_MODEL", "gemini-3.5-flash"),
    )

    # Prompt describing the exact goal, validation targets, and rules
    prompt = """
    You are an autonomous developer agent. Your task is to synchronize updates from the Python SDK 
    repository to this Dart SDK repository.

    Follow these step-by-step instructions:
    1. Read the commit hash stored in `dart-sdk/.last_synced_python_commit` (create the file if it doesn't exist).
    2. Read the current Dart SDK package version number from `dart-sdk/pubspec.yaml` (under version).
    3. Increment the minor version number of the Dart SDK package (e.g., `0.1.3` -> `0.2.0`).
    4. Synchronize this new version number to the Dart SDK package:
       - Update the version field in `dart-sdk/pubspec.yaml` to the new version.
       - Update the hardcoded version in `dart-sdk/lib/src/mcp/mcp_bridge.dart` (specifically in the Implementation instantiation) to the new version.
       - Prepend a new release entry in `dart-sdk/CHANGELOG.md` with the new version if it is not already documented. The entry must focus on changes and enhancements relevant to the Dart package (e.g., newly translated APIs, Dart-specific improvements, or testing changes) rather than raw Python SDK commit messages or Python-specific updates.
       - Update any version badges (e.g., the pub package badge) in `dart-sdk/README.md` to reflect the new version.
    5. Check the git history in `python-sdk` (repository located at https://github.com/google-antigravity/antigravity-sdk-python).
    6. Identify all files under `python-sdk/google/antigravity` (source and tests) modified or added between the tracked commit hash and the current HEAD of `python-sdk`.
    7. For each modified or new Python file:
       - Map the path to the Dart SDK equivalent under `dart-sdk/lib/src` or `dart-sdk/test` (e.g. google/antigravity/agent.py -> lib/src/agent.dart).
       - Translate the Python changes or the new Python file to Dart. Maintain Dart coding patterns, package layout, and use `dart_mappable` serialization where applicable.
       - Translate corresponding Python test files to the native Dart `test` package framework.
    8. Verify the code:
       - Run `dart pub get` inside `dart-sdk`
       - Run `dart run build_runner build --delete-conflicting-outputs` inside `dart-sdk` to regenerate model code.
       - Run `dart format --output=none --set-exit-if-changed .` inside `dart-sdk`.
       - Run `dart analyze --fatal-infos` inside `dart-sdk` to verify zero analysis warnings or errors.
       - Run `dart test` inside `dart-sdk` to verify all unit tests pass successfully.
    9. If any analysis or tests fail, examine the errors, edit the Dart code to fix the issues, and re-run verification until all checks pass.
    10. Once everything builds and passes tests successfully, update the contents of `dart-sdk/.last_synced_python_commit` with the latest commit hash of the Python SDK (`python-sdk`).
    11. Inform me when the task is complete, summarizing which files were translated, which version was synchronized, and what checks were verified.
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
