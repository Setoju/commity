# PLAN — Small Feature: Auto-Grouped Multi-Commit

## Implementation approach
Add an opt-in commit mode that:
1) inspects staged diff metadata,
2) groups files into connected change clusters,
3) generates one conventional message per cluster,
4) applies commits sequentially with confirmation per commit.

Default single-commit behavior remains unchanged.

## Tasks

- [ ] **T1: Add CLI/config surface for opt-in auto-grouped multi-commit** `est:15-25m`
  - Files:
    - `bin/commiti`
    - `lib/services/helpers/config_loader.rb`
    - `README.md`
  - Changes:
    - Add boolean CLI flag (name TBD in implementation, no numeric split input).
    - Ensure config merge keeps existing defaults and backward compatibility.
    - Document usage and behavior.
  - Verify:
    - `bundle exec ruby -Ilib bin/commiti --help`
    - spec(s) for config parsing if needed.

- [ ] **T2: Implement staged-change grouping for connected file clusters** `est:25-35m`
  - Files:
    - `lib/services/git/diff_parser.rb`
    - `lib/services/git/git_reader.rb`
    - `lib/services/flow_context_builder.rb`
    - `lib/services/git/commit/` (new grouping service module)
    - `spec/lib/services/diff_parser_spec.rb`
    - `spec/lib/services/diff_pipeline_integration_spec.rb`
  - Changes:
    - Build deterministic grouping heuristic based on file path/module proximity and change metadata.
    - Return ordered groups suitable for commit planning.
  - Verify:
    - targeted specs for grouping behavior,
    - integration spec for disconnected vs connected file sets.

- [ ] **T3: Generate/apply one commit per group with per-commit confirmation** `est:25-35m`
  - Files:
    - `lib/flows/commit_flow.rb`
    - `lib/services/message_generator.rb`
    - `lib/services/message_presenter.rb`
    - `lib/services/git/commit/commit_execution.rb`
    - `lib/services/git/git_writer.rb`
    - `spec/lib/flows/base_flow_spec.rb`
    - `spec/lib/services/message_generator_spec.rb`
    - `spec/lib/services/git_writer_spec.rb`
  - Changes:
    - For multi-commit mode, loop over groups:
      - stage/select group files,
      - generate validated message,
      - show preview + prompt,
      - commit and continue/abort safely.
    - Preserve existing single-commit path untouched.
  - Verify:
    - unit specs for loop/abort behavior,
    - existing commit-message validation specs remain green.

- [ ] **T4: End-to-end verification and docs polish** `est:10-20m`
  - Files:
    - `README.md`
    - `spec/lib/commiti_cli_integration_spec.rb`
  - Changes:
    - Add user-facing docs and example command.
    - Add/adjust integration test for flag-enabled multi-commit flow.
  - Verify:
    - `bundle exec rspec`
    - `bundle exec rubocop`
