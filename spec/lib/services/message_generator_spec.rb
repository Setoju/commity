# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::MessageGenerator do
  let(:run_stage) { ->(_message, &block) { block.call } }
  let(:generator) { described_class.new(flow_type: :commit, run_stage: run_stage) }
  let(:client) { instance_double('Commity::GoogleClient') }
  let(:prompt) { { system: 'system prompt', user: 'user prompt' } }
  let(:model) { Commity::GoogleClient::DEFAULT_MODEL }

  it 'normalizes retry output to a conventional commit when prefix is missing' do
    allow(client).to receive(:generate).and_return('update validation flow', 'improve validation flow')

    result = generator.generate_with_quality_check(
      client: client,
      prompt: prompt,
      diff_metadata: { docs_only: false, total_files: 1 },
      model: model
    )

    expect(result).to start_with('feat: ')
    expect(Commity::InteractivePrompt.commit_message_errors(result)).to eq([])
  end

  it 'uses docs prefix normalization for docs-only changes' do
    allow(client).to receive(:generate).and_return('refresh readme', 'improve README structure')

    result = generator.generate_with_quality_check(
      client: client,
      prompt: prompt,
      diff_metadata: { docs_only: true, total_files: 1 },
      model: model
    )

    expect(result).to start_with('docs: ')
    expect(Commity::InteractivePrompt.commit_message_errors(result)).to eq([])
  end
end
