# frozen_string_literal: true

module Commity
  module FlowContextBuilder
    def self.build(flow_type:, diff:, client:, run_stage:)
      line_chunks = Commity::DiffParser.split_by_file_lines(diff)
      diff_metadata = Commity::DiffParser.metadata_from_line_chunks(line_chunks)

      summarized_result = run_stage.call('Preparing diff for AI model') do
        Commity::DiffSummarizer.summarize_if_needed(diff, client: client, chunks: summary_chunks(line_chunks))
      end

      prompt = Commity::PromptBuilder.build(
        type: flow_type,
        diff: summarized_result[:content],
        summarized: summarized_result[:summarized],
        raw_diff: diff,
        diff_metadata: diff_metadata
      )

      {
        diff_metadata: diff_metadata,
        summarized_result: summarized_result,
        prompt: prompt
      }
    end

    def self.summary_chunks(line_chunks)
      line_chunks.map { |chunk| { path: chunk[:path], diff: chunk[:lines].join } }
    end
    private_class_method :summary_chunks
  end
end