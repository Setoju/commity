# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Commiti::GoogleClient do
  let(:client) do
    described_class.new(
      config: {
        google_api_key: 'test-google-api-key',
        model: described_class::DEFAULT_MODEL,
        temperature: described_class::DEFAULT_TEMPERATURE,
        timeout_seconds: described_class::DEFAULT_TIMEOUT_SECONDS,
        open_timeout_seconds: described_class::DEFAULT_OPEN_TIMEOUT_SECONDS
      }
    )
  end

  describe '.generate' do
    it 'normalizes timeout and temperature values before POST' do
      response = instance_double(
        'HTTParty::Response',
        success?: true,
        body: { candidates: [{ content: { parts: [{ text: 'ok' }] } }] }.to_json,
        code: 200
      )

      expect(described_class).to receive(:post) do |path, opts|
        expect(path).to eq('/v1beta/models/gemma-4-31b-it:generateContent')
        expect(opts[:query]).to eq({ key: 'test-google-api-key' })
        expect(opts[:timeout]).to eq(90)
        expect(opts[:open_timeout]).to eq(7)

        payload = JSON.parse(opts[:body])
        expect(payload.dig('generationConfig', 'temperature')).to eq(0.3)
        expect(payload.dig('systemInstruction', 'parts', 0, 'text')).to eq('sys')
        expect(payload.dig('contents', 0, 'role')).to eq('user')
        expect(payload.dig('contents', 0, 'parts', 0, 'text')).to eq('usr')

        response
      end

      content = client.generate(
        system: 'sys',
        user: 'usr',
        model: 'models/gemma-4-31b-it',
        temperature: '0.3',
        timeout_seconds: '90',
        open_timeout_seconds: '7'
      )

      expect(content).to eq('ok')
    end

    it 'falls back to defaults when numeric env inputs are invalid' do
      response = instance_double(
        'HTTParty::Response',
        success?: true,
        body: { candidates: [{ content: { parts: [{ text: 'ok' }] } }] }.to_json,
        code: 200
      )

      expect(described_class).to receive(:post) do |_path, opts|
        expect(opts[:timeout]).to eq(described_class::DEFAULT_TIMEOUT_SECONDS)
        expect(opts[:open_timeout]).to eq(described_class::DEFAULT_OPEN_TIMEOUT_SECONDS)

        payload = JSON.parse(opts[:body])
        expect(payload.dig('generationConfig', 'temperature')).to eq(described_class::DEFAULT_TEMPERATURE)
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

    it 'includes Google AI error details when present' do
      response = instance_double(
        'HTTParty::Response',
        success?: false,
        body: { error: { message: 'invalid API key' } }.to_json,
        code: 401
      )
      allow(described_class).to receive(:post).and_return(response)

      expect do
        client.generate(system: 'sys', user: 'usr')
      end.to raise_error('Google AI error: 401 - invalid API key')
    end

    it 'raises when API key is not configured' do
      client_without_key = described_class.new(config: {})

      expect do
        client_without_key.generate(system: 'sys', user: 'usr')
      end.to raise_error(/Set GOOGLE_API_KEY \(or GEMINI_API_KEY\)/)
    end
  end
end
