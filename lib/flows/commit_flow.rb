# frozen_string_literal: true

module Commity
  module Flows
    class CommitFlow < BaseFlow
      private

      def flow_type
        :commit
      end

      def prepare!
        maybe_stage_changes
        ensure_staged_changes
      end

      def collect_diff
        run_stage('Collecting staged diff') { Commity::GitReader.staged_diff }
      end

      def finalize(message)
        maybe_commit(message)
      end

      def maybe_stage_changes
        status = run_stage('Reading git status') { Commity::GitWriter.status_short }
        raise 'No changes found in working tree.' if status.strip.empty?

        puts "\nCurrent git status:\n\n#{status}"
        return unless Commity::InteractivePrompt.ask_yes_no('Run git add -A now?', default: :no)

        run_stage('Staging changes (git add -A)') { Commity::GitWriter.stage_all }
        puts "\nStaged changes with git add -A.\n"
      end

      def ensure_staged_changes
        staged = run_stage('Checking staged changes') { Commity::GitWriter.staged_changes? }
        return if staged

        if Commity::InteractivePrompt.ask_yes_no('No staged changes found. Stage all changes now with git add -A?',
                                                 default: :yes)
          run_stage('Staging changes (git add -A)') { Commity::GitWriter.stage_all }
          puts "\nStaged changes with git add -A.\n"
        end

        staged = run_stage('Checking staged changes') { Commity::GitWriter.staged_changes? }
        raise 'No staged changes. Commit flow needs staged changes.' unless staged
      end

      def edit_message_until_valid(initial_message)
        working = initial_message

        loop do
          edited = Commity::InteractivePrompt.edit_message(working)
          return nil if edited.nil?

          if edited == working.to_s.strip
            puts "\nNo changes detected in editor."
            return edited unless Commity::InteractivePrompt.ask_yes_no('Re-open editor now?', default: :yes)

            next
          end

          errors = Commity::InteractivePrompt.commit_message_errors(edited)
          return edited if errors.empty?

          puts "\nEdited message needs fixes:"
          errors.each { |error| puts "- #{error}" }
          return edited unless Commity::InteractivePrompt.ask_yes_no('Re-open editor now?', default: :yes)

          working = edited
        end
      end

      def maybe_commit(message)
        working_message = message

        loop do
          action = Commity::InteractivePrompt.ask_commit_action

          case action
          when :yes
            errors = Commity::InteractivePrompt.commit_message_errors(working_message)
            unless errors.empty?
              puts "\nCurrent message needs fixes before commit:"
              errors.each { |error| puts "- #{error}" }

              if Commity::InteractivePrompt.ask_yes_no('Open editor to fix now?', default: :yes)
                edited = edit_message_until_valid(working_message)
                if edited.nil?
                  puts "\nEditor did not exit successfully. Commit skipped.\n\n"
                  return
                end

                working_message = edited
                print_message(working_message)
                next
              end

              puts "\nCommit skipped.\n\n"
              return
            end

            output = run_stage('Writing commit') { Commity::GitWriter.commit_with_message_file(working_message) }
            puts output unless output.to_s.strip.empty?
            puts "\nCommit created.\n\n"
            return
          when :edit
            edited = edit_message_until_valid(working_message)
            if edited.nil?
              puts "\nEditor did not exit successfully.\n\n"
              next
            end

            working_message = edited
            print_message(working_message)
          else
            puts "\nCommit skipped.\n\n"
            return
          end
        end
      end
    end
  end
end
