require "httparty"
require "json"

module Commity
  class OllamaClient
    include HTTParty
    base_uri "http://localhost:11434"

    def generate(system:, user:, model: ENV["OLLAMA_MODEL"], temperature: ENV["MODEL_TEMPERATURE"], timeout_seconds: ENV["MODEL_TIMEOUT_SECONDS"], open_timeout_seconds: ENV["MODEL_OPEN_TIMEOUT_SECONDS"])
      response = self.class.post(
        "/api/chat",
        headers: { "Content-Type" => "application/json" },
        timeout: timeout_seconds,
        open_timeout: open_timeout_seconds,
        body: {
          model: model,
          stream: false,
          options: {
            temperature: temperature
          },
          messages: [
            { role: "system", content: system },
            { role: "user",   content: user }
          ]
        }.to_json
      )

      raise "Ollama error: #{response.code}" unless response.success?
      JSON.parse(response.body).dig("message", "content")
    end
  end
end