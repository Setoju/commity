# frozen_string_literal: true

require 'yaml'

module Commity
  class ConfigLoader
    CONFIG_FILE = '.commity.yaml'

    DEFAULT_CONFIG = {
      'model' => 'llama3.2',
      'ollama_url' => 'http://localhost:11434',
      'candidates' => 1,
      'base_branch' => 'main',
      'no_copy' => false
    }.freeze

    # Loads configuration from .commity.yaml and merges with defaults.
    # Keys are returned as symbols.
    def self.load
      config = DEFAULT_CONFIG.dup

      if File.exist?(CONFIG_FILE)
        begin
          user_config = YAML.load_file(CONFIG_FILE)
          config.merge!(user_config) if user_config.is_a?(Hash)
        rescue Psych::SyntaxError => e
          warn "Warning: Failed to parse #{CONFIG_FILE}: #{e.message}. Using defaults."
        rescue StandardError => e
          warn "Warning: Could not read #{CONFIG_FILE}: #{e.message}. Using defaults."
        end
      end

      # Ensure keys are symbols for consistent internal usage
      config.transform_keys(&:to_sym)
    end
  end
end