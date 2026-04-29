# frozen_string_literal: true

module Commity
  module Flows
    class BaseFlow
      def initialize(options:)
        # Merge defaults/config file with CLI options (CLI options win)
        @options = Commity::ConfigLoader.load.merge(options || {})
      end

      def run
        prepare!
        diff = collect_diff
        client = Commity::OllamaClient.new
        context = Commity::FlowContextBuilder.build(
          flow_type: flow_type,
          diff: diff,
          client: client,
          run_stage: method(:run_stage)
        )
        Commity::MessagePresenter.print_summarization_notice(context[:summarized_result])

        candidates = generate_candidates(
          client: client,
          prompt: context[:prompt],
          diff_metadata: context[:diff_metadata]
        )
        message = select_message(candidates)

        maybe_copy_to_clipboard(message)
        finalize(message)
      end

      private

      attr_reader :options

      def prepare!; end

      def collect_diff
        raise NotImplementedError, "#{self.class} must implement #collect_diff"
      end

      def flow_type
        raise NotImplementedError, "#{self.class} must implement #flow_type"
      end

      def finalize(_message); end

      def run_stage(message, &)
        Commity::Spinner.run(message, &)
      end

      def generate_with_quality_check(client:, prompt:, diff_metadata:)
        message_generator.generate_with_quality_check(client: client, prompt: prompt, diff_metadata: diff_metadata)
      end

      def generate_candidates(client:, prompt:, diff_metadata:)
        count = options[:candidates].to_i
        message_generator.generate_candidates(client: client, prompt: prompt, diff_metadata: diff_metadata, count: count)
      end

      def select_message(candidates)
        Commity::MessagePresenter.select_message(candidates)
      end

      def print_message(message)
        Commity::MessagePresenter.print_message(message)
      end

      def maybe_copy_to_clipboard(message)
        Commity::MessagePresenter.maybe_copy_to_clipboard(
          message,
          no_copy: options[:no_copy],
          run_stage: method(:run_stage)
        )
      end

      def message_generator
        @message_generator ||= Commity::MessageGenerator.new(flow_type: flow_type, run_stage: method(:run_stage))
      end
    end
  end
end
