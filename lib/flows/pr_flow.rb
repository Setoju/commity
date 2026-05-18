# frozen_string_literal: true

module Commiti
  module Flows
    class PrFlow < BaseFlow
      private

      def flow_type
        :pr
      end

      def collect_diff
        run_stage("Collecting diff against #{options[:base_branch]}...HEAD") do
          Commiti::GitReader.branch_diff(base_branch: options[:base_branch])
        end
      end

      def finalize(message)
        maybe_open_pr_page(message, options[:base_branch])
      end

      def maybe_open_pr_page(description, base_branch)
        pr_url = run_stage('Preparing prefilled PR URL') do
          head_branch = Commiti::GitWriter.current_branch
          origin_url = Commiti::GitWriter.origin_url
          title = Commiti::PrOpener.suggest_title(description, head_branch: head_branch)
          Commiti::PrOpener.compare_url(
            origin_url: origin_url,
            base_branch: base_branch,
            head_branch: head_branch,
            title: title,
            body: description
          )
        end

        if Commiti::InteractivePrompt.ask_yes_no('Open prefilled PR page in browser now?', default: :no)
          run_stage('Opening browser') { Commiti::PrOpener.open_in_browser(pr_url) }
          puts "\nOpened PR page:\n#{pr_url}\n\n"
        else
          puts "\nPR URL:\n#{pr_url}\n\n"
        end
      end
    end
  end
end
