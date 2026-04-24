# frozen_string_literal: true

require 'httparty'
require 'json'

module Commity
  class OllamaClient
    include HTTParty
    base_uri 'http://localhost:11434'

    DEFAULT_MODEL = 'llama3.2'
    DEFAULT_TEMPERATURE = 0.2
    DEFAULT_TIMEOUT_SECONDS = 180
    DEFAULT_OPEN_TIMEOUT_SECONDS = 10

    def generate(system:, user:, model: ENV.fetch('OLLAMA_MODEL', DEFAULT_MODEL), temperature: ENV.fetch('MODEL_TEMPERATURE', DEFAULT_TEMPERATURE),
                 timeout_seconds: ENV.fetch('MODEL_TIMEOUT_SECONDS', DEFAULT_TIMEOUT_SECONDS), open_timeout_seconds: ENV.fetch('MODEL_OPEN_TIMEOUT_SECONDS', DEFAULT_OPEN_TIMEOUT_SECONDS))
      selected_model = normalize_model(model)
      selected_temperature = normalize_float(temperature, DEFAULT_TEMPERATURE)
      selected_timeout_seconds = normalize_integer(timeout_seconds, DEFAULT_TIMEOUT_SECONDS)
      selected_open_timeout_seconds = normalize_integer(open_timeout_seconds, DEFAULT_OPEN_TIMEOUT_SECONDS)

      response = self.class.post(
        '/api/chat',
        headers: { 'Content-Type' => 'application/json' },
        timeout: selected_timeout_seconds,
        open_timeout: selected_open_timeout_seconds,
        body: {
          model: selected_model,
          stream: false,
          options: {
            temperature: selected_temperature
          },
          messages: [
            { role: 'system', content: system },
            { role: 'user',   content: user }
          ]
        }.to_json
      )

      unless response.success?
        detail = extract_error(response.body)
        raise "Ollama error: #{response.code}#{detail.empty? ? '' : " - #{detail}"}"
      end

      JSON.parse(response.body).dig('message', 'content')
    end

    def normalize_model(model)
      value = model.to_s.strip
      value.empty? ? DEFAULT_MODEL : value
    end

    def normalize_float(value, fallback)
      return fallback if value.nil? || value.to_s.strip.empty?

      Float(value)
    rescue ArgumentError
      fallback
    end

    def normalize_integer(value, fallback)
      return fallback if value.nil? || value.to_s.strip.empty?

      Integer(value)
    rescue ArgumentError
      fallback
    end

    def extract_error(body)
      parsed = JSON.parse(body.to_s)
      parsed['error'].to_s.strip
    rescue JSON::ParserError
      ''
    end
  end
end
