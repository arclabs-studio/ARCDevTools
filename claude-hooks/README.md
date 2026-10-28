# Claude Code hooks

Deterministic middleware for Claude Code sessions. An instruction in `CLAUDE.md` is followed
*probably*; a hook applies *always* — hooks run outside the model. Anything that must never go
wrong belongs here, not in the constitution.

Wiring lives in `ARCAgentStack/config/settings.json`, which `bootstrap.sh` symlinks to
`~/.claude/settings.json`. The commands there point at absolute paths inside this directory, so
these hooks only fire when ARCDevTools sits at (or is symlinked to)
`~/Developer/ARCLabsStudio/Packages/ARCDevTools`.

## Semantics

- **PreToolUse** — emit `{"hookSpecificOutput": {"permissionDecision": "deny"|"ask", ...}}` to
  block or prompt. A `deny` applies even under `bypassPermissions`, which is what makes hooks
  the hard layer.
- **PostToolUse** — cannot block; the tool already ran. Use it for formatting and for feedback
  that teaches: returning concrete diagnostics ("line 7:19: error: Force Cast Violation")
  closes the loop in the same turn instead of at commit time. `swiftlint-feedback.sh` is the
  worked example. Order matters within a matcher group — formatting runs before linting, so
  the lint sees the formatted file.
- **SessionStart** — `additionalContext` is injected into the session.
- **Stop** — `exit 2` sends the model back to work with stderr as the reason. Honour
  `stop_hook_active` or you will loop.

## Active hooks (wired globally)

| Hook | Event | What it does |
|---|---|---|
| `block-dangerous-commands.sh` | PreToolUse · Bash | Blocks `rm -rf`, `sudo rm`, `chmod 777`, redirection into `.env`, download-piped-to-shell, `dd`/`mkfs` to a device |
| `block-dangerous-git.sh` | PreToolUse · Bash | Blocks force-push to main/develop, `git clean -f`, `git reset --hard`, deleting protected branches |
| `validate-commit.sh` | PreToolUse · Bash | Rejects non-Conventional-Commit messages |
| `secrets-commit-guard.sh` | PreToolUse · Bash | Scans the **staged diff** on `git commit` for provider tokens, PEM keys, credential-shaped assignments and JWTs. Ships in `ask` mode |
| `asc-mutation-guard.sh` | PreToolUse · Bash | Blocks state-mutating `asc` verbs unless `--dry-run` or `ASC_CONFIRMED=1` |
| `protect-sensitive-files.sh` | PreToolUse · Edit\|Write | Blocks edits to secrets/credentials, `project.pbxproj` and `.xcodeproj` internals, `*.xcstrings`, lockfiles, `.git/`, DerivedData/`.build`/SPM checkouts |
| `format-on-save.sh` | PostToolUse · Edit\|Write | SwiftFormat on the edited file |
| `swiftlint-feedback.sh` | PostToolUse · Edit\|Write | Lints the just-formatted file and returns the concrete violations to the agent. Silent when clean. Resolves `.swiftlint.yml` upward from the file, falling back to `configs/swiftlint.base.yml` |
| `session-start.sh` | SessionStart · startup | Injects branch, last release tag, pending/staged diffstat, TODO/FIXME count and recent commits |

## Opt-in hooks (present, deliberately not wired globally)

| Hook | Event | Why opt-in |
|---|---|---|
| `xcode-mcp-only.sh` | PreToolUse · Bash | Turns the constitution's "Xcode MCP, not `xcodebuild`" rule into a hard block. Not global because ARC's own CI, ASC and benchmark scripts legitimately shell out. Escape hatch: prefix the command with `ARC_CLI_OK=1` when the user asked for the CLI by name |
| `stop-build-gate.sh` | Stop | "Green before done" — 0 errors and 0 warnings before Claude may finish. Fires at every response end and a build costs 10–60 s. Set `BUILD_CMD` per project first; autodetection is unreliable in workspaces |

Enable either by adding it to a project's own `.claude/settings.json`. Note that ARCDevTools'
`.claude/settings.json` already runs a lighter prompt-type Stop hook that typechecks edited
files — run that or `stop-build-gate.sh`, not both.

## Rules for writing one

Hooks run **unsandboxed, with your permissions**. Treat them as production code: small,
explicit, reviewed. Never install hooks from someone else's repo without reading them — a
malicious repo can ship hooks in its own `.claude/settings.json`.

They are defence in depth, not a sandbox: regex blocks have documented bypasses (obfuscation,
variable indirection). Duplicate the critical paths in `permissions.deny` as a second layer.

Portability notes learned the hard way:

- macOS ships **BSD grep**. `\+` is invalid in a BRE — always pass `-E` and use `grep -vE`.
- Prefer `printf '%s\n'` over `echo` for data: `echo` interprets backslash escapes in some
  shells and will corrupt JSON containing `\n`.
- With `set -o pipefail`, a `grep` that matches nothing returns 1 and aborts the hook. Guard
  each stage with `|| true`.
- Bail out early when not in a git work tree, or `git` failures will abort the hook.
- After `format-on-save.sh` the file changes on disk. If a later `Edit` fails on a stale
  `old_string`, re-read the file.

## Testing a hook

Feed it the event JSON directly:

```bash
printf '{"tool_name":"Bash","tool_input":{"command":"<cmd>"}}' | ./block-dangerous-commands.sh
```

Empty output and exit 0 means "allow". Test the negative cases too — a hook that blocks
everything is as broken as one that blocks nothing.
