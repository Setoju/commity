# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::DiffSummarizer do
  let(:small_diff) { "diff --git a/a.rb b/a.rb\n@@ -1 +1 @@\n-old\n+new\n" }

  describe '.summarize_if_needed' do
    it 'returns original content when diff is under threshold' do
      client = instance_double('client')

      result = described_class.summarize_if_needed(small_diff, client: client)

      expect(result[:summarized]).to be(false)
      expect(result[:content]).to eq(small_diff)
      expect(result[:fallback_reason]).to be_nil
    end

    it 'returns deterministic fallback when summarization times out' do
      big_diff = <<~DIFF + ("+x\n" * 9000)
        diff --git a/lib/a.rb b/lib/a.rb
        index 111..222 100644
        --- a/lib/a.rb
        +++ b/lib/a.rb
        @@ -1 +1,2 @@
      DIFF

      allow(described_class).to receive(:split_by_file).and_return([{ path: 'lib/a.rb', diff: big_diff }])
      allow(described_class).to receive(:summarize_chunks).and_raise(Net::ReadTimeout.new)

      result = described_class.summarize_if_needed(big_diff, client: instance_double('client'))

      expect(result[:summarized]).to be(true)
      expect(result[:fallback_reason]).to include('Summarization timed out')
      expect(result[:content]).to include('### Diff Overview')
      expect(result[:content]).to include('### lib/a.rb')
    end
  end

  describe '.split_by_file' do
    it 'extracts path and content per diff block' do
      diff = <<~DIFF
        diff --git a/lib/a.rb b/lib/a.rb
        @@ -1 +1 @@
        -old
        +new
        diff --git a/lib/b.rb b/lib/b.rb
        @@ -1 +1 @@
        -x
        +y
      DIFF

      chunks = described_class.split_by_file(diff)

      expect(chunks.map { |c| c[:path] }).to eq(['lib/a.rb', 'lib/b.rb'])
      expect(chunks.first[:diff]).to include('@@ -1 +1 @@')
    end
  end

  describe '.mechanical_summary' do
    it 'counts additions, deletions, and hunks' do
      diff = <<~DIFF
        diff --git a/a.rb b/a.rb
        @@ -1 +1 @@
        -old
        +new
      DIFF

      expect(described_class.mechanical_summary(diff)).to eq('- 1 additions, 1 deletions across 1 hunk(s)')
    end
  end
end
