# claude-plugins

[日本語](README.md) | English

A repository of Claude Code configuration (skills, hooks, permission settings, etc.) shared across multiple repositories. It is built to be product-agnostic, and this repository itself doubles as a Claude Code plugin marketplace.

## What's included

This repository is structured as "one marketplace + one plugin (`core`)". Future domain-specific resources (AWS, Python, Go, technical research, etc.) are expected to be added as sibling plugins alongside `core`.

### Skills (`plugins/core/skills/`)

| Skill | Invocation | Description |
|---|---|---|
| `commit` | `/core:commit` | Commits the current changes following this repository's commit convention. For changes carried out with a steering directory, the directory name is used as-is for the commit title |
| `steering-new` | `/core:steering-new` | Creates a steering directory (`.steering/`) for a feature addition or fix, and proceeds through requirements → design → persistent documentation (`docs/`) updates with staged approvals |
| `setup` | `/core:setup` | Copies `claude.md`, `.devcontainer/devcontainer.json`, and the recommended `permissions` settings into the consuming repository — files the plugin mechanism itself can't distribute (see "Usage" below) |

### Hooks (`plugins/core/hooks/`)

| Hook | Event | Description |
|---|---|---|
| `pretooluse-block-prohibited.sh` | PreToolUse | Blocks prohibited command strings that `permissions.deny` alone cannot express |
| `posttooluse-doc-check.sh` | PostToolUse (Edit\|Write) | Advises (never blocks) when identifiers removed or renamed by a code change still appear in `docs/*.md` or `README*.md` |
| `stop-run-tests.sh` | Stop | Runs the command in `.claude/test-command`, if present, and blocks the end of the turn on failure |

## Usage

Claude Code's official plugin mechanism can only distribute components Claude Code itself interprets, such as skills and hooks. `permissions`/`sandbox` settings, `claude.md`, and `.devcontainer/devcontainer.json` fall outside that mechanism, so the `/core:setup` skill copies them separately.

1. Register the marketplace

   ```
   claude plugin marketplace add <owner>/claude-plugins
   ```

2. Install the `core` plugin

   ```
   claude plugin install core@shared-claude-plugins
   ```

   This makes `/core:commit`, `/core:steering-new`, and `/core:setup` available. The marketplace name is `shared-claude-plugins` rather than `claude-plugins` (the repository's own name), because the latter is rejected at install time as impersonating an official Anthropic marketplace.

3. Run `/core:setup` at the root of the consuming repository

   This copies `claude.md`, `.devcontainer/devcontainer.json`, and the recommended `permissions` settings into the repository. If a file already exists, it isn't overwritten — the diff is presented before applying.

- **This configuration set assumes it runs inside a dev container.** The permission policy (approved by default) relies on the assumption that the filesystem outside the container is unreachable. Review the permission policy before using it outside a dev container
- The container's timezone automatically follows the host environment (`/etc/localtime` is bind-mounted read-only). No specific timezone is hardcoded, so anything inside the container that deals with dates — such as `.steering/` directory dates — follows the host's local date
- The test command varies by repository and is not baked into this configuration set. In a repository with tests, write the command on a single line in `.claude/test-command` (e.g. `python3 -m unittest discover -s tests`). If the file is absent, the Stop hook exits without doing anything
- `.claude/settings.local.json` is local-environment-specific and is not shared (it is gitignored)

## Permission policy at a glance

- Everything is approved by default (`permissions.defaultMode: bypassPermissions`); operations that aren't prohibited run without confirmation
- Instead of an allowlist, only prohibited operations are enumerated, via `.claude/settings.json`'s `deny` and the hooks
- See "開発環境の権限設定" ("Development environment permission settings") in `claude.md` for details

## Steering workflow

The requirements, design, and task list for a specific piece of work are recorded under `.steering/[YYYYMMDD]-[NN]-[title]/`. Use the `/core:steering-new [title]` skill to create one. See `claude.md` and `plugins/core/skills/steering-new/SKILL.md` for details.

---

When updating this file, please also update its counterpart, [README.md](README.md).
