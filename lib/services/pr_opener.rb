# frozen_string_literal: true

require 'uri'

module Commity
  module PrOpener
    SCP_REMOTE = %r{\A(?<user>[^@]+)@(?<host>[^:\s/]+):(?<path>[^\s]+)\z}

    def self.compare_url(origin_url:, base_branch:, head_branch:, title:, body:)
      remote = extract_remote_info(origin_url)
      if remote.nil?
        raise 'Supported providers for browser PR opening are GitHub, GitLab, and GitBucket.'
      end

      case remote[:provider]
      when :gitlab
        gitlab_mr_url(
          remote: remote,
          base_branch: base_branch,
          head_branch: head_branch,
          title: title,
          body: body
        )
      else
        github_like_compare_url(
          remote: remote,
          base_branch: base_branch,
          head_branch: head_branch,
          title: title,
          body: body
        )
      end
    end

    def self.github_like_compare_url(remote:, base_branch:, head_branch:, title:, body:)
      query = URI.encode_www_form(
        'expand' => '1',
        'title' => title,
        'body' => body
      )

      base = "#{remote[:web_scheme]}://#{remote[:host]}"
      path = "#{remote[:namespace]}/#{remote[:repo]}"

      "#{base}/#{path}/compare/#{encode_branch_for_path(base_branch)}...#{encode_branch_for_path(head_branch)}?#{query}"
    end

    def self.gitlab_mr_url(remote:, base_branch:, head_branch:, title:, body:)
      query = URI.encode_www_form(
        'merge_request[source_branch]' => head_branch,
        'merge_request[target_branch]' => base_branch,
        'merge_request[title]' => title,
        'merge_request[description]' => body
      )

      base = "#{remote[:web_scheme]}://#{remote[:host]}"
      path = "#{remote[:namespace]}/#{remote[:repo]}"

      "#{base}/#{path}/-/merge_requests/new?#{query}"
    end

    def self.encode_branch_for_path(branch)
      URI.encode_www_form_component(branch.to_s).gsub('+', '%20')
    end

    def self.extract_remote_info(origin_url)
      remote_text = origin_url.to_s.strip
      return nil if remote_text.empty?

      parsed = parse_uri_remote(remote_text) || parse_scp_remote(remote_text)
      return nil if parsed.nil?

      normalized = normalize_repo_path(parsed[:path])
      return nil if normalized.nil?

      provider = detect_provider(parsed[:host])
      return nil if provider.nil?

      {
        provider: provider,
        host: parsed[:host],
        web_scheme: parsed[:web_scheme],
        namespace: normalized[:namespace],
        repo: normalized[:repo]
      }
    end

    def self.parse_uri_remote(remote_text)
      uri = URI.parse(remote_text)
      return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS) || uri.scheme == 'ssh'
      return nil if uri.host.to_s.strip.empty?

      web_scheme = uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS) ? uri.scheme : 'https'
      { host: uri.host, path: uri.path, web_scheme: web_scheme }
    rescue URI::InvalidURIError
      nil
    end

    def self.parse_scp_remote(remote_text)
      match = remote_text.match(SCP_REMOTE)
      return nil if match.nil?

      { host: match[:host], path: match[:path], web_scheme: 'https' }
    end

    def self.normalize_repo_path(raw_path)
      clean = raw_path.to_s.strip
      clean = clean.sub(%r{\A/+}, '').sub(%r{/+\z}, '')
      clean = clean.sub(/\.git\z/, '')
      segments = clean.split('/').reject(&:empty?)
      return nil if segments.length < 2

      {
        namespace: segments[0..-2].join('/'),
        repo: segments[-1]
      }
    end

    def self.detect_provider(host)
      normalized = host.to_s.downcase
      return :gitlab if normalized.include?('gitlab')
      return :gitbucket if normalized.include?('gitbucket')
      return :github if normalized.include?('github')

      nil
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
      info = extract_remote_info(origin_url)
      return nil if info.nil?

      { owner: info[:namespace], repo: info[:repo] }
    end

    def self.windows?
      RUBY_PLATFORM.include?('mingw') || RUBY_PLATFORM.include?('mswin')
    end

    def self.mac?
      RUBY_PLATFORM.include?('darwin')
    end
  end
end
