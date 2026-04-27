# frozen_string_literal: true

module Commity
  module DiffSummarizer
    module FallbackBuilder
      def mechanical_summary(diff)
        additions = diff.to_s.each_line.count { |line| line.start_with?('+') && !line.start_with?('+++') }
        deletions = diff.to_s.each_line.count { |line| line.start_with?('-') && !line.start_with?('---') }
        hunks = diff.to_s.each_line.count { |line| line.start_with?('@@') }
        "- #{additions} additions, #{deletions} deletions across #{hunks} hunk(s)"
      end

      def fallback_summary(diff, chunks: nil)
        parsed_chunks = chunks || Commity::DiffParser.split_by_file(diff)
        files = []

        parsed_chunks.each do |chunk|
          current = {
            path: chunk[:path].to_s,
            additions: 0,
            deletions: 0,
            status: 'modified'
          }

          chunk[:diff].to_s.each_line do |line|
            stripped = line.strip
            current[:status] = 'added' if stripped.start_with?('new file mode')
            current[:status] = 'deleted' if stripped.start_with?('deleted file mode')
            current[:status] = 'renamed' if stripped.start_with?('rename from ') || stripped.start_with?('rename to ')

            next if line.start_with?('diff --git ', '+++', '---', '@@')

            current[:additions] += 1 if line.start_with?('+')
            current[:deletions] += 1 if line.start_with?('-')
          end

          files << current
        end

        return diff.to_s[0, FALLBACK_BYTES] if files.empty?

        lines = []
        lines << '### Diff Overview'
        lines << "- Total files changed: #{files.length}"
        lines << ''

        files.first(MAX_FILES_IN_SUMMARY).each do |file|
          lines << "### #{file[:path]}"
          lines << "- Status: #{file[:status]}"
          lines << "- Added lines: #{file[:additions]}"
          lines << "- Removed lines: #{file[:deletions]}"
          lines << ''
        end

        lines << "...and #{files.length - MAX_FILES_IN_SUMMARY} more files" if files.length > MAX_FILES_IN_SUMMARY

        lines.join("\n").strip
      end
    end
  end
end
