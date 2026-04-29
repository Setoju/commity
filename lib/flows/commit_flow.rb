# frozen_string_literal: true

module Commity
  module Flows
    class CommitFlow < BaseFlow
      private

      def flow_type
        :commit
      end

      def prepare!
        Commity::CommitStaging.prepare(run_stage: method(:run_stage))
      end

      def collect_diff
        run_stage('Collecting staged diff') { Commity::GitReader.staged_diff }
      end

      def finalize(message)
        Commity::CommitExecution.maybe_commit(
          message,
          run_stage: method(:run_stage),
          print_message: method(:print_message)
        )
      end
    end
  end
end
