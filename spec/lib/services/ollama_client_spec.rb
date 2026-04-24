# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Commity::OllamaClient do
  let(:client) { described_class.new }

  describe '.generate' do
    it 'normalizes timeout and temperature values before POST' do
      response = instance_double('HTTParty::Response', success?: true, body: { message: { content: 'ok' } }.to_json,
                                                       code: 200)

      expect(described_class).to receive(:post) do |path, opts|
        expect(path).to eq('/api/chat')
        expect(opts[:timeout]).to eq(90)
        expect(opts[:open_timeout]).to eq(7)

        payload = JSON.parse(opts[:body])
        expect(payload['model']).to eq('llama3.2')
        expect(payload.dig('options', 'temperature')).to eq(0.3)
        expect(payload.dig('messages', 0, 'role')).to eq('system')
        expect(payload.dig('messages', 1, 'role')).to eq('user')

        response
      end

      content = client.generate(
        system: 'sys',
        user: 'usr',
        model: 'llama3.2',
        temperature: '0.3',
        timeout_seconds: '90',
        open_timeout_seconds: '7'
      )

      expect(content).to eq('ok')
    end

    it 'falls back to defaults when numeric env inputs are invalid' do
      response = instance_double('HTTParty::Response', success?: true, body: { message: { content: 'ok' } }.to_json,
                                                       code: 200)

      expect(described_class).to receive(:post) do |_path, opts|
        expect(opts[:timeout]).to eq(described_class::DEFAULT_TIMEOUT_SECONDS)
        expect(opts[:open_timeout]).to eq(described_class::DEFAULT_OPEN_TIMEOUT_SECONDS)

        payload = JSON.parse(opts[:body])
        expect(payload.dig('options', 'temperature')).to eq(described_class::DEFAULT_TEMPERATURE)
        response
      end

      client.generate(
        system: 'sys',
        user: 'usr',
        model: nil,
        temperature: 'not-a-number',
        timeout_seconds: 'bad',
        open_timeout_seconds: 'bad'
      )
    end

    it 'includes Ollama error details when present' do
      response = instance_double('HTTParty::Response', success?: false, body: { error: 'invalid model' }.to_json,
                                                       code: 500)
      allow(described_class).to receive(:post).and_return(response)

      expect do
        client.generate(system: 'sys', user: 'usr')
      end.to raise_error('Ollama error: 500 - invalid model')
    end
  end
end
