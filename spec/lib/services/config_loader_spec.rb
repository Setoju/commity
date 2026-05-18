# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::ConfigLoader do
  describe '.load' do
    let(:env) { {} }

    it 'returns defaults when environment variables are not set' do
      config = described_class.load(env: env)

      expect(config[:google_api_key]).to be_nil
      expect(config[:model]).to eq('gemma-4-31b-it')
      expect(config[:candidates]).to eq(1)
      expect(config[:base_branch]).to eq('main')
      expect(config[:no_copy]).to be(false)
      expect(config[:temperature]).to eq(0.2)
      expect(config[:timeout_seconds]).to eq(180)
      expect(config[:open_timeout_seconds]).to eq(10)
    end

    it 'loads values from environment variables' do
      env.merge!(
        'GOOGLE_API_KEY' => 'key-123',
        'COMMITY_MODEL' => 'gemini-2.5-flash',
        'COMMITY_CANDIDATES' => '3',
        'COMMITY_BASE_BRANCH' => 'develop',
        'COMMITY_NO_COPY' => 'true',
        'COMMITY_MODEL_TEMPERATURE' => '0.5',
        'COMMITY_MODEL_TIMEOUT_SECONDS' => '240',
        'COMMITY_MODEL_OPEN_TIMEOUT_SECONDS' => '20'
      )

      config = described_class.load(env: env)

      expect(config[:google_api_key]).to eq('key-123')
      expect(config[:model]).to eq('gemini-2.5-flash')
      expect(config[:candidates]).to eq(3)
      expect(config[:base_branch]).to eq('develop')
      expect(config[:no_copy]).to be(true)
      expect(config[:temperature]).to eq(0.5)
      expect(config[:timeout_seconds]).to eq(240)
      expect(config[:open_timeout_seconds]).to eq(20)
    end

    it 'accepts GEMINI_API_KEY as a fallback API key variable' do
      env['GEMINI_API_KEY'] = 'gemini-key-123'

      config = described_class.load(env: env)

      expect(config[:google_api_key]).to eq('gemini-key-123')
    end

    it 'falls back to defaults when numeric and boolean values are invalid' do
      env.merge!(
        'COMMITY_CANDIDATES' => 'abc',
        'COMMITY_NO_COPY' => 'wat',
        'COMMITY_MODEL_TEMPERATURE' => 'nan-nope',
        'COMMITY_MODEL_TIMEOUT_SECONDS' => 'oops',
        'COMMITY_MODEL_OPEN_TIMEOUT_SECONDS' => 'oops'
      )

      config = described_class.load(env: env)

      expect(config[:candidates]).to eq(1)
      expect(config[:no_copy]).to be(false)
      expect(config[:temperature]).to eq(0.2)
      expect(config[:timeout_seconds]).to eq(180)
      expect(config[:open_timeout_seconds]).to eq(10)
    end
  end
end
