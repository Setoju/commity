# frozen_string_literal: true

require 'shellwords'
require 'tempfile'

module Commity
  module InteractivePrompt
    COMMIT_PREFIX = /\A(feat|fix|chore|refactor|docs|style|test|perf|ci|build|revert)(\([^)]+\))?!?:\s+\S/i

    def self.ask_yes_no(question, default: :no)
      suffix = default == :yes ? '[Y/n]' : '[y/N]'
      print "#{question} #{suffix} "
      input = $stdin.gets
      return default == :yes if input.nil?

      value = input.strip.downcase
      return true if %w[y yes].include?(value)
      return false if %w[n no].include?(value)
      return default == :yes if value.empty?

      false
    end

    def self.ask_commit_action
      print 'Commit with this message? [y/e/N] '
      input = $stdin.gets
      return :no if input.nil?

      value = input.strip.downcase
      return :yes if %w[y yes].include?(value)
      return :edit if %w[e edit].include?(value)

      :no
    end

    def self.edit_message(initial_message)
      # Keep the temp file closed while the external editor runs.
      # On Windows, open handles can prevent editors like Notepad from
      # saving in place, which can make edits appear to be ignored.
      file = Tempfile.new(['commity-msg', '.txt'])
      begin
        file.write("#{initial_message.to_s.rstrip}\n")
        file.flush
        file.close

        command = editor_command
        success = system(*command, file.path)
        return nil unless success

        File.read(file.path, mode: 'r:bom|utf-8').strip
      ensure
        file.unlink
      end
    end

    def self.commit_message_errors(message)
      cleaned = message.to_s.strip
      return ['Message cannot be empty.'] if cleaned.empty?

      first_line = cleaned.lines.first.to_s.strip
      errors = []
      unless first_line.match?(COMMIT_PREFIX)
        errors << 'First line must start with a conventional commit type (feat:, fix:, etc.).'
      end
      errors << 'First line should be 72 characters or fewer.' if first_line.length > 72
      errors
    end

    def self.editor_command
      preferred = ENV['VISUAL']
      preferred = ENV['EDITOR'] if preferred.to_s.strip.empty?

      if preferred.to_s.strip.empty?
        return ['notepad'] if windows?

        return ['vi']
      end

      command = Shellwords.split(preferred)
      command << '--wait' if code_editor_command?(command.first) && !command.include?('--wait')

      command
    end

    def self.code_editor_command?(exe)
      name = File.basename(exe.to_s).downcase
      ['code', 'code.cmd', 'code.exe', 'codium', 'codium.cmd', 'codium.exe'].include?(name)
    end

    def self.windows?
      RUBY_PLATFORM.include?('mingw') || RUBY_PLATFORM.include?('mswin')
    end
  end
end
