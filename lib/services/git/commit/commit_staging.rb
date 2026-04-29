# frozen_string_literal: true

module Commity
  module CommitStaging
    def self.prepare(run_stage:)
      maybe_stage_changes(run_stage: run_stage)
      ensure_staged_changes(run_stage: run_stage)
    end

    def self.maybe_stage_changes(run_stage:)
      status = run_stage.call('Reading git status') { Commity::GitWriter.status_short }
      raise 'No changes found in working tree.' if status.strip.empty?

      puts "\nCurrent git status:\n\n#{status}"
      return unless Commity::InteractivePrompt.ask_yes_no('Run git add -A now?', default: :no)

      run_stage.call('Staging changes (git add -A)') { Commity::GitWriter.stage_all }
      puts "\nStaged changes with git add -A.\n"
    end
    private_class_method :maybe_stage_changes

    def self.ensure_staged_changes(run_stage:)
      staged = run_stage.call('Checking staged changes') { Commity::GitWriter.staged_changes? }
      return if staged

      if Commity::InteractivePrompt.ask_yes_no('No staged changes found. Stage all changes now with git add -A?',
                                               default: :yes)
        run_stage.call('Staging changes (git add -A)') { Commity::GitWriter.stage_all }
        puts "\nStaged changes with git add -A.\n"
      end

      staged = run_stage.call('Checking staged changes') { Commity::GitWriter.staged_changes? }
      raise 'No staged changes. Commit flow needs staged changes.' unless staged
    end
    private_class_method :ensure_staged_changes
  end
end