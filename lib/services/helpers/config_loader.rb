# frozen_string_literal: true

module Commity
  class ConfigLoader
    DEFAULT_CONFIG = {
      google_api_key: nil,
      model: Commity::GoogleClient::DEFAULT_MODEL,
      candidates: 1,
      base_branch: 'main',
      no_copy: false,
      temperature: Commity::GoogleClient::DEFAULT_TEMPERATURE,
      timeout_seconds: Commity::GoogleClient::DEFAULT_TIMEOUT_SECONDS,
      open_timeout_seconds: Commity::GoogleClient::DEFAULT_OPEN_TIMEOUT_SECONDS
    }.freeze

    # Loads configuration from environment variables.
    # Keys are returned as symbols with parsed values.
    def self.load(env: ENV)
      {
        google_api_key: google_api_key_from_env(env),
        model: present_or_default(env.fetch('COMMITY_MODEL', nil), DEFAULT_CONFIG[:model]),
        candidates: integer_or_default(env.fetch('COMMITY_CANDIDATES', nil), DEFAULT_CONFIG[:candidates]),
        base_branch: present_or_default(env.fetch('COMMITY_BASE_BRANCH', nil), DEFAULT_CONFIG[:base_branch]),
        no_copy: boolean_or_default(env.fetch('COMMITY_NO_COPY', nil), DEFAULT_CONFIG[:no_copy]),
        temperature: float_or_default(env.fetch('COMMITY_MODEL_TEMPERATURE', nil), DEFAULT_CONFIG[:temperature]),
        timeout_seconds: integer_or_default(env.fetch('COMMITY_MODEL_TIMEOUT_SECONDS', nil), DEFAULT_CONFIG[:timeout_seconds]),
        open_timeout_seconds: integer_or_default(env.fetch('COMMITY_MODEL_OPEN_TIMEOUT_SECONDS', nil),
                                                 DEFAULT_CONFIG[:open_timeout_seconds])
      }
    end

    def self.google_api_key_from_env(env)
      present_or_nil(env.fetch('GOOGLE_API_KEY', nil)) ||
        present_or_nil(env.fetch('GEMINI_API_KEY', nil)) ||
        present_or_nil(env.fetch('GOOGLE_GENERATIVE_AI_API_KEY', nil))
    end
    private_class_method :google_api_key_from_env

    def self.present_or_nil(value)
      normalized = value.to_s.strip
      normalized.empty? ? nil : normalized
    end
    private_class_method :present_or_nil

    def self.present_or_default(value, fallback)
      present_or_nil(value) || fallback
    end
    private_class_method :present_or_default

    def self.integer_or_default(value, fallback)
      return fallback if value.nil? || value.to_s.strip.empty?

      Integer(value)
    rescue ArgumentError
      fallback
    end
    private_class_method :integer_or_default

    def self.float_or_default(value, fallback)
      return fallback if value.nil? || value.to_s.strip.empty?

      Float(value)
    rescue ArgumentError
      fallback
    end
    private_class_method :float_or_default

    def self.boolean_or_default(value, fallback)
      return fallback if value.nil? || value.to_s.strip.empty?

      normalized = value.to_s.strip.downcase
      return true if %w[1 true yes on].include?(normalized)
      return false if %w[0 false no off].include?(normalized)

      fallback
    end
    private_class_method :boolean_or_default
  end
end
