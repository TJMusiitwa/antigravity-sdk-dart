# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Security audit workflow run by example/getting_started/workflows.dart.
#
# This is a top-level workflow script for `agent.beta.runWorkflow()`. The
# harness provides `phase`, `log`, `call_tool`, `agent`, `parallel`, and `args`.
# Use `log(...)` for output: `print(...)` is rejected.
#
# Expects `args["paths"]`: a list of source files to audit. It reads each file
# with `call_tool("read_file", ...)` (needs `BuiltinTools.viewFile`), audits
# them in parallel with the `file_auditor` subagent, and then holds a two-turn
# conversation with the `lead_synthesizer` subagent.

phase("Read & Audit Files")


async def read_and_audit(path):
    content = await call_tool("read_file", Path=path)
    # `type_name` selects the `SubagentConfig(name: 'file_auditor')` registered
    # on the agent; `role` labels each parallel call in progress logs.
    return await agent(
        f"Audit `{path}` in one concise sentence naming the vulnerability:\n"
        f"{content}",
        schema={"type": "string"},
        role=f"Audit {path.rsplit('/', 1)[-1]}",
        type_name="file_auditor",
    )


findings = await parallel(args["paths"], read_and_audit)

phase("Multi-Turn Executive Synthesis")
combined = "\n".join(str(f).strip() for f in findings)
lead = agent(
    "You are the lead security synthesizer.",
    role="Lead Synthesizer",
    type_name="lead_synthesizer",
)
summary = await lead(
    f"Summarize these security findings:\n{combined}",
    schema={
        "type": "object",
        "properties": {
            "total_issues": {"type": "integer"},
            "highest_severity": {"type": "string"},
            "summary": {"type": "string"},
        },
        "required": ["total_issues", "highest_severity", "summary"],
    },
)
remediation = await lead(
    "Now propose a concise 1-sentence remediation plan for the"
    " highest-severity issue from your summary.",
    schema={"type": "string"},
)
log(
    f"Audit complete: {summary['total_issues']} issues"
    f" (highest={summary['highest_severity']}): {summary['summary']}"
)
log(f"Remediation plan: {remediation}")
