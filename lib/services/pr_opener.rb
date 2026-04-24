# frozen_string_literal: true

require 'uri'

module Commity
  module PrOpener
    SSH_REMOTE = %r{\Agit@github\.com:(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?\z}
    HTTPS_REMOTE = %r{\Ahttps://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?/?\z}
    SSH_URL_REMOTE = %r{\Assh://git@github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?/?\z}

    def self.compare_url(origin_url:, base_branch:, head_branch:, title:, body:)
      owner_repo = extract_owner_repo(origin_url)
      raise 'Only GitHub remotes are supported for browser PR opening.' if owner_repo.nil?

      query = URI.encode_www_form(
        'expand' => '1',
        'title' => title,
        'body' => body
      )

      "https://github.com/#{owner_repo[:owner]}/#{owner_repo[:repo]}/compare/#{base_branch}...#{head_branch}?#{query}"
    end

    def self.suggest_title(pr_body, head_branch:)
      in_summary = false
      pr_body.to_s.each_line do |line|
        stripped = line.strip
        if stripped == '## Summary'
          in_summary = true
          next
        end

        break if in_summary && stripped.start_with?('## ')
        next unless in_summary
        next if stripped.empty? || stripped.start_with?('-', '*')

        return stripped[0, 72]
      end

      "Update #{head_branch}"
    end

    def self.open_in_browser(url)
      success = if windows?
                  open_windows_browser(url)
                elsif mac?
                  system('open', url)
                else
                  system('xdg-open', url)
                end

      raise 'Failed to open browser for PR URL.' unless success

      true
    end

    def self.open_windows_browser(url)
      cleaned_url = url.to_s.strip.sub(/\A\\+/, '')

      # Prefer shell protocol handler. This bypasses cmd/explorer parsing of '&'.
      return true if system('rundll32', 'url.dll,FileProtocolHandler', cleaned_url)

      # PowerShell fallback, passing URL as an argument to avoid command parsing.
      system(
        'powershell',
        '-NoProfile',
        '-Command',
        '$u=$args[0]; Start-Process -FilePath $u',
        '--',
        cleaned_url
      )
    end

    def self.extract_owner_repo(origin_url)
      [SSH_REMOTE, HTTPS_REMOTE, SSH_URL_REMOTE].each do |pattern|
        match = origin_url.to_s.strip.match(pattern)
        next if match.nil?

        return { owner: match[:owner], repo: match[:repo] }
      end

      nil
    end

    def self.windows?
      RUBY_PLATFORM.include?('mingw') || RUBY_PLATFORM.include?('mswin')
    end

    def self.mac?
      RUBY_PLATFORM.include?('darwin')
    end
  end
end
