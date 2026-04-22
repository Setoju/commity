# Commity

AI-powered commit message and pull request description generator for Git repositories, using a local Ollama model.

## What It Does

Commity helps you:

- Generate conventional commit messages from staged changes.
- Generate structured GitHub PR descriptions from branch diffs.
- Review and optionally edit generated commit messages before writing to Git history.
- Open a prefilled GitHub compare/PR page in your browser (no GitHub API token required).

## Requirements

- Ruby 3.0+
- Git
- Ollama running locally at `http://localhost:11434`
- A Git repository as your working directory

## Install Dependencies (from source)

```bash
bundle install
```

## CLI Usage

```bash
bundle exec ruby -Ilib bin/commity [options]
```

Or after gem installation:

```bash
commity [options]
```

### Options

- `--type TYPE` where `TYPE` is `commit` or `pr` (default: `commit`)
- `--base BRANCH` base branch for PR diff (default: `main`)
- `--no-copy` print output only, skip clipboard copy
- `-h`, `--help` show help

## Commit Flow (`--type commit`)

1. Shows `git status --short`.
2. Asks for confirmation before staging (`git add -A`).
3. Ensures there are staged changes.
4. Reads staged diff and generates a commit message.
5. Shows message and asks: `Commit with this message? [y/e/N]`
   - `y`: commit now
   - `e`: open editor, then validate and re-confirm
   - `N`: skip commit
6. Writes commit with `git commit --file <tempfile>`.

### Why `--file` instead of `-m`

Multi-line messages and special characters are safer with `git commit --file`, avoiding shell quoting edge cases.

### Editor Selection

Commit edit mode uses:

1. `VISUAL`
2. `EDITOR`
3. Fallback: `notepad` on Windows, `vi` on non-Windows

## PR Flow (`--type pr`)

1. Reads branch diff: `git diff <base>...HEAD`.
2. Generates PR description with these sections:
   - `## Summary`
   - `## Motivation`
   - `## Changes Made`
   - `## Testing Notes`
3. Builds GitHub compare URL with prefilled title/body using query params.
4. Asks before opening browser.

The tool opens a browser URL only. It does not call GitHub APIs.

## Examples

Generate commit message and commit interactively:

```bash
bundle exec ruby -Ilib bin/commity --type commit
```

Generate PR description against `develop`:

```bash
bundle exec ruby -Ilib bin/commity --type pr --base develop
```

Print only, do not copy to clipboard:

```bash
bundle exec ruby -Ilib bin/commity --type pr --no-copy
```

## Implementation Overview

Main entrypoint:

- `bin/commity`: CLI parsing and high-level control flow

Core services:

- `lib/services/git_reader.rb`
  - Reads staged diff and branch diff
  - Provides recent commits helper
- `lib/services/git_writer.rb`
  - Reads status/staged state
  - Stages (`git add -A`)
  - Commits with message file (`git commit --file`)
  - Reads branch and origin remote
- `lib/services/ollama_client.rb`
  - Sends chat requests to Ollama
- `lib/services/prompt_builder.rb`
  - Builds strict system/user prompts for commit and PR modes
- `lib/services/diff_summarizer.rb`
  - Condenses large diffs before final prompt generation
- `lib/services/interactive_prompt.rb`
  - Confirmation prompts (`y/e/N`)
  - Editor loop and commit message validation
- `lib/services/pr_opener.rb`
  - Parses GitHub remotes
  - Builds compare URL with encoded title/body
  - Opens browser cross-platform
- `lib/services/clipboard.rb`
  - Cross-platform clipboard support

Service loading:

- `lib/commity.rb` requires all service modules.

## Error Handling

The CLI reports user-friendly errors for common cases such as:

- No changes/staged changes
- Invalid or missing Git data
- Ollama connection failures
- Browser open failures

## Notes

- The model default is currently `llama3.2` in `OllamaClient`.
- PR browser URL body payloads are URL-encoded with `URI.encode_www_form`.
