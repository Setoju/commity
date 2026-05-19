# CONTEXT — Small Feature: Multi-Commit Generation

## Feature description
Add a new **multi-commit mode** to Commiti commit flow so one run can produce and apply several atomic conventional commits instead of a single commit.

User goal:
- When many staged changes are present, split work into coherent chunks and commit them one-by-one with generated messages.

Current behavior:
- Commit flow generates one message and runs one `git commit --file ...`.

Target behavior (this workflow):
- User can opt into multi-commit mode.
- Commiti automatically determines connected file groups and proposes a commit plan.
- Each planned commit includes grouped files + generated message.
- User confirms each step before commit is written.

## Key design decisions (proposed)
1. **Entry point / CLI surface**
   - Add a multi-commit mode flag (no numeric split count input).
   - Commiti decides commit count automatically based on connected file changes.
   - No breaking change to existing `--type commit` flow.

2. **Where logic should live**
   - Keep orchestration in `CommitFlow`/`BaseFlow` path, but extract multi-commit implementation to a dedicated service/module (to avoid overloading `CommitExecution`).

3. **Granularity of splitting in v1**
   - Prefer **file-level grouping** for first release (safe, deterministic, easier rollback reasoning).
   - Avoid hunk-level interactive staging in v1 (complex UX and brittle git patching behavior).

4. **User control and safety**
   - Show grouped file list + message before each commit.
   - Require explicit yes/no per planned commit.
   - Abort remaining commits on failure; keep already-created commits intact.

## Scope boundaries
### In scope
- CLI option for enabling auto-grouped multi-commit mode in commit flow.
- Grouping algorithm that detects connected changes and forms commit groups automatically.
- Plan generation for one commit message per computed group.
- Sequential commit execution with per-commit confirmation.
- Tests for grouping/planning/execution paths.

### Out of scope
- Automatic perfect semantic splitting by AST or deep dependency analysis.
- Interactive hunk-level patching UI.
- PR flow changes.
- Multi-provider AI support.

## Edge cases to handle
- All files look weakly connected (single large group outcome).
- Multiple disconnected change clusters (separate commit groups).
- User declines one planned commit mid-run.
- One commit command fails after prior commits succeeded.
- Generated subject violates conventional commit rules (reuse existing validation/normalization).
