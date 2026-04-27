# frozen_string_literal: true

module Commity
  module DiffParser
    DOC_EXTENSIONS = %w[.md .markdown .rst .adoc .txt].freeze

    def self.split_by_file_lines(diff)
      chunks = []
      current_path = nil
      current_lines = []

      diff.to_s.each_line do |line|
        if line.start_with?('diff --git ')
          chunks << { path: current_path, lines: current_lines } if current_path

          current_path = extract_path(line)
          current_lines = [line]
        else
          current_lines << line
        end
      end

      chunks << { path: current_path, lines: current_lines } if current_path
      chunks
    end

    def self.split_by_file(diff)
      split_by_file_lines(diff).map do |chunk|
        { path: chunk[:path], diff: chunk[:lines].join }
      end
    end

    def self.metadata_from_line_chunks(chunks)
      files = chunks.map { |chunk| chunk[:path].to_s }.reject(&:empty?).uniq
      {
        files: files,
        total_files: files.length,
        docs_only: docs_only_files?(files)
      }
    end

    def self.metadata(diff)
      metadata_from_line_chunks(split_by_file_lines(diff))
    end

    def self.docs_only_files?(files)
      return false if files.empty?

      files.all? do |path|
        normalized = path.to_s.downcase
        DOC_EXTENSIONS.any? { |ext| normalized.end_with?(ext) } ||
          normalized.start_with?('docs/') ||
          normalized.include?('/docs/')
      end
    end

    def self.extract_path(line)
      match = line.chomp.match(%r{\Adiff --git a/(.+) b/(.+)\z})
      match ? match[2].strip : 'unknown'
    end
    private_class_method :extract_path
  end
end
