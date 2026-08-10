# claude-plugins

[日本語](README.md) | English

A repository of Claude Code configuration (skills, hooks, permission settings, etc.) shared across multiple repositories. It is built to be product-agnostic and is meant to be copied into consuming repositories.

## What's included

### Skills (`.claude/skills/`)

| Skill | Description |
|---|---|
| `commit` | Commits the current changes following this repository's commit convention. For changes carried out with a steering directory, the directory name is used as-is for the commit title |
| `steering-new` | Creates a steering directory (`.steering/`) for a feature addition or fix, and proceeds through requirements → design → persistent documentation (`docs/`) updates with staged approvals |

### Hooks (`.claude/hooks/`)

| Hook | Event | Description |
|---|---|---|
| `pretooluse-block-prohibited.sh` | PreToolUse | Blocks prohibited command strings that `permissions.deny` alone cannot express |
| `posttooluse-doc-check.sh` | PostToolUse (Edit\|Write) | Advises (never blocks) when identifiers removed or renamed by a code change still appear in `docs/*.md` or `README*.md` |
| `stop-run-tests.sh` | Stop | Runs the command in `.claude/test-command`, if present, and blocks the end of the turn on failure |

## Usage

Copy `.claude/`, `claude.md`, and `.devcontainer/` into the root of the consuming repository.

- **This configuration set assumes it runs inside a dev container.** The permission policy (approved by default) relies on the assumption that the filesystem outside the container is unreachable. Review the permission policy before using it outside a dev container
- The test command varies by repository and is not baked into this configuration set. In a repository with tests, write the command on a single line in `.claude/test-command` (e.g. `python3 -m unittest discover -s tests`). If the file is absent, the Stop hook exits without doing anything
- `.claude/settings.local.json` is local-environment-specific and is not shared (it is gitignored)

## Permission policy at a glance

- Everything is approved by default (`permissions.defaultMode: bypassPermissions`); operations that aren't prohibited run without confirmation
- Instead of an allowlist, only prohibited operations are enumerated, via `.claude/settings.json`'s `deny` and the hooks
- See "開発環境の権限設定" ("Development environment permission settings") in `claude.md` for details

## Steering workflow

The requirements, design, and task list for a specific piece of work are recorded under `.steering/[YYYYMMDD]-[NN]-[title]/`. Use the `/steering-new [title]` skill to create one. See `claude.md` and `.claude/skills/steering-new/SKILL.md` for details.

---

When updating this file, please also update its counterpart, [README.md](README.md).
