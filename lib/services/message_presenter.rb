# frozen_string_literal: true

module Commity
  module MessagePresenter
    def self.print_summarization_notice(summarized_result)
      if summarized_result[:fallback_reason]
        puts "\n#{summarized_result[:fallback_reason]}\n"
      elsif summarized_result[:summarized]
        puts "\nDiff is large - summarizing first to preserve system prompt focus...\n"
      end
    end

    def self.select_message(candidates)
      if candidates.length == 1
        print_message(candidates.first)
        return candidates.first
      end

      print_candidates(candidates)
      selected_index = Commity::InteractivePrompt.ask_candidate_selection(candidates.length)
      selected_message = candidates[selected_index]
      puts "\nUsing candidate #{selected_index + 1}."
      print_message(selected_message)
      selected_message
    end

    def self.maybe_copy_to_clipboard(message, no_copy:, run_stage:)
      return if no_copy

      copied = run_stage.call('Copying output to clipboard') { Commity::Clipboard.copy(message) }
      if copied
        puts "Copied to clipboard!\n\n"
      else
        puts "Clipboard not available. Install xclip: sudo apt install xclip\n\n"
      end
    end

    def self.print_message(message)
      puts "\n#{'─' * 60}"
      puts message
      puts "#{'─' * 60}\n"
    end

    def self.print_candidates(candidates)
      candidates.each_with_index do |candidate, index|
        puts "\nCandidate #{index + 1}:"
        print_message(candidate)
      end
    end
    private_class_method :print_candidates
  end
end