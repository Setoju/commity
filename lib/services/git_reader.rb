# frozen_string_literal: true

require 'open3'
require_relative 'diff_parser'

module Commity
  module GitReader
    MAX_DIFF_BYTES = 50_000
    TRUNCATION_NOTICE = "\n# ... diff clipped by Commity to preserve context under size limit\n"

    def self.staged_diff
      # Strip context lines using -U0 and filter out binary/lockfile noise
      diff, status = Open3.capture2('git', 'diff', '--cached', '-U0')
      raise 'Failed to read staged diff.' unless status.success?
      raise 'No staged changes. Run `git add` first.' if diff.strip.empty?

      filtered_diff = filter_diff_noise(diff)
      clip_diff_context(filtered_diff, max_bytes: MAX_DIFF_BYTES)
    end

    def self.branch_diff(base_branch: 'main')
      raise 'Invalid branch name.' unless base_branch.match?(%r{\A[a-zA-Z0-9_\-./]+\z})

      # Strip context lines using -U0 and filter out binary/lockfile noise
      diff, status = Open3.capture2('git', 'diff', '-U0', "#{base_branch}...HEAD")
      raise "Failed to read branch diff against '#{base_branch}'." unless status.success?
      raise "No diff found against '#{base_branch}'." if diff.strip.empty?

      filtered_diff = filter_diff_noise(diff)
      clip_diff_context(filtered_diff, max_bytes: MAX_DIFF_BYTES)
    end

    def self.recent_commits(count: 10)
      out, = Open3.capture2('git', 'log', '--oneline', "-#{count}")
      out
    end

    def self.clip_diff_context(diff, max_bytes:)
      return diff if diff.bytesize <= max_bytes

      chunks = split_by_file(diff)
      clipped = if chunks.empty?
                  diff.byteslice(0, max_bytes)
                else
                  clip_chunks(chunks, max_bytes: max_bytes)
                end

      append_notice(clipped, max_bytes: max_bytes)
    end

    LOCKFILE_PATTERNS = [
      %r{Gemfile\.lock},
      %r{package-lock\.json},
      %r{yarn\.lock},
      %r{pnpm-lock\.yaml},
      %r{composer\.lock},
      %r{mix\.lock},
      %r{Cargo\.lock},
      %r{Pipfile\.lock}
    ].freeze

    def self.filter_diff_noise(diff)
      filtered_lines = []
      skip_chunk = false

      diff.each_line do |line|
        if line.start_with?('diff --git')
          path = extract_path_from_diff_header(line)
          is_lockfile = LOCKFILE_PATTERNS.any? { |pattern| path.match?(pattern) }
          # git diff output for binary files often includes "Binary files ... differ"
          is_binary_diff_header = line.include?('Binary files')

          if is_lockfile || is_binary_diff_header
            skip_chunk = true
            next # Skip this diff header
          else
            skip_chunk = false
          end
        end

        unless skip_chunk
          filtered_lines << line
        end
      end
      filtered_lines.join
    end
    private_class_method :filter_diff_noise

    def self.extract_path_from_diff_header(line)
      match = line.chomp.match(%r{\Adiff --git a/(.+) b/(.+)\z})
      match ? match[2].strip : 'unknown'
    end
    private_class_method :extract_path_from_diff_header

    # Returns [{ path: String, lines: Array<String> }]
    def self.split_by_file(diff)
      Commity::DiffParser.split_by_file_lines(diff)
    end

    def self.clip_chunks(chunks, max_bytes:)
      output = +''

      chunks.each do |chunk|
        remaining = max_bytes - output.bytesize
        break if remaining <= 0

        chunk_text = chunk[:lines].join
        if chunk_text.bytesize <= remaining
          output << chunk_text
          next
        end

        output << clip_single_chunk(chunk[:lines], max_bytes: remaining)
        break
      end

      if output.empty?
        first_chunk_text = chunks.first[:lines].join
        return first_chunk_text.byteslice(0, max_bytes)
      end

      output
    end

    def self.clip_single_chunk(lines, max_bytes:)
      output = +''
      return output if max_bytes <= 0

      header_lines = []
      hunks = []
      current_hunk = nil
      in_hunks = false

      lines.each do |line|
        if line.start_with?('@@')
          in_hunks = true
          current_hunk = [line]
          hunks << current_hunk
          next
        end

        if in_hunks
          current_hunk << line
        else
          header_lines << line
        end
      end

      header_lines.each do |line|
        break if output.bytesize + line.bytesize > max_bytes

        output << line
      end

      return output if hunks.empty?

      hunks.each do |hunk|
        hunk_text = hunk.join
        if output.bytesize + hunk_text.bytesize <= max_bytes
          output << hunk_text
          next
        end

        hunk_header = hunk.first
        break if output.bytesize + hunk_header.bytesize > max_bytes

        output << hunk_header
        hunk[1..].to_a.each do |line|
          break if output.bytesize + line.bytesize > max_bytes

          output << line
        end
        break
      end

      output
    end

    def self.append_notice(clipped_diff, max_bytes:)
      safe_clipped = clipped_diff.to_s
      return safe_clipped if safe_clipped.bytesize >= max_bytes && max_bytes <= TRUNCATION_NOTICE.bytesize

      return safe_clipped + TRUNCATION_NOTICE if safe_clipped.bytesize + TRUNCATION_NOTICE.bytesize <= max_bytes

      available = max_bytes - TRUNCATION_NOTICE.bytesize
      return safe_clipped.byteslice(0, max_bytes) if available <= 0

      safe_clipped.byteslice(0, available) + TRUNCATION_NOTICE
    end
  end
end
