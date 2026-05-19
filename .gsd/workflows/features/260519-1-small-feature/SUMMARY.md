# SUMMARY — Small Feature: Auto-Grouped Multi-Commit

## What was built
Implemented an opt-in `--auto-split` commit mode that automatically groups connected staged file changes into multiple atomic commits.

Key delivered behavior:
- New CLI/config switch for auto-split mode (no user-specified commit count).
- Connected-change grouping heuristic based on logical file stem and namespace proximity.
- Sequential per-group commit generation/execution with per-commit user confirmation.
- Safe stop behavior: if a group commit is skipped, remaining changes are restaged for manual follow-up.
- Single-group fallback: if changes are effectively one connected group, flow reuses standard single-commit behavior.

## Files changed
### CLI / config / docs
- `bin/commiti`
- `lib/services/helpers/config_loader.rb`
- `.env.example`
- `README.md`

### Grouping + flow integration
- `lib/services/git/commit/change_grouping.rb` (new)
- `lib/services/flow_context_builder.rb`
- `lib/commiti.rb`
- `lib/flows/commit_flow.rb`
- `lib/services/git/git_writer.rb`
- `lib/services/git/commit/commit_staging.rb`
- `lib/services/git/commit/commit_execution.rb`

### Tests
- `spec/lib/services/config_loader_spec.rb`
- `spec/lib/commiti_cli_integration_spec.rb`
- `spec/lib/services/change_grouping_spec.rb` (new)
- `spec/lib/services/diff_pipeline_integration_spec.rb`
- `spec/lib/flows/commit_flow_spec.rb` (new)
- `spec/lib/services/git_writer_spec.rb`

## Verification run
- ✅ `bundle exec rspec` (82 examples, 0 failures)
- ⚠️ `bundle exec rubocop` (fails due to existing baseline offenses in unrelated files; no new offense introduced by final auto-split flow files)
- ✅ `gem build commiti.gemspec` (build succeeded: `commiti-1.2.3.gem`)

## How to use
Single-commit behavior remains default:
```bash
bundle exec ruby -Ilib bin/commiti --type commit
```

Enable auto-grouped multi-commit mode:
```bash
bundle exec ruby -Ilib bin/commiti --type commit --auto-split
```

You can also set env-based default:
```bash
COMMITI_AUTO_SPLIT=true
```
