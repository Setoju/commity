# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::Flows::BaseFlow do
  let(:flow_class) do
    Class.new(described_class) do
      private

      def flow_type
        :commit
      end

      def collect_diff
        ''
      end
    end
  end

  let(:flow) { flow_class.new(options: { candidates: 1, no_copy: true, base_branch: 'main' }) }
  let(:prompt) { { system: 'system prompt', user: 'user prompt' } }
  let(:diff_metadata) { { docs_only: false, total_files: 1 } }
  let(:client) { instance_double('Commity::OllamaClient') }

  before do
    allow(Commity::Spinner).to receive(:run) { |_message, &block| block.call }
  end

  describe '#generate_with_quality_check' do
    it 'raises when retry output is still invalid' do
      long_subject = "feat: #{'a' * 110}"
      allow(client).to receive(:generate).and_return(long_subject, long_subject)

      expect do
        flow.send(:generate_with_quality_check, client: client, prompt: prompt, diff_metadata: diff_metadata)
      end.to raise_error(/Generated commit is still invalid after retry/)
    end

    it 'returns retry output when retry becomes valid' do
      invalid_subject = "feat: #{'a' * 110}"
      valid_subject = 'feat: keep subject concise'
      allow(client).to receive(:generate).and_return(invalid_subject, valid_subject)

      output = flow.send(:generate_with_quality_check, client: client, prompt: prompt, diff_metadata: diff_metadata)

      expect(output).to eq(valid_subject)
    end
  end
end
