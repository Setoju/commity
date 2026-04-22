require "httparty"
require "json"

module Commity
  class OllamaClient
    include HTTParty
    base_uri "http://localhost:11434"

    def generate(system:, user:, model: "llama3.2", timeout_seconds: 180, open_timeout_seconds: 10)
      response = self.class.post(
        "/api/chat",
        headers: { "Content-Type" => "application/json" },
        timeout: timeout_seconds,
        open_timeout: open_timeout_seconds,
        body: {
          model: model,
          stream: false,
          options: {
            temperature: 0.2
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