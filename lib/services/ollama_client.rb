require "httparty"
require "json"

module Commity
  class OllamaClient
    include HTTParty
    base_uri "http://localhost:11434"

    def generate(system:, user:, model: "llama3.2")
      response = self.class.post(
        "/api/chat",
        headers: { "Content-Type" => "application/json" },
        body: {
          model: model,
          stream: false,
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