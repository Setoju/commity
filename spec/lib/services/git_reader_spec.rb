# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::GitReader do
  describe '.split_by_file' do
    it 'splits a diff into file chunks' do
      diff = <<~DIFF
        diff --git a/lib/a.rb b/lib/a.rb
        index 111..222 100644
        --- a/lib/a.rb
        +++ b/lib/a.rb
        @@ -1 +1 @@
        -old
        +new
        diff --git a/lib/b.rb b/lib/b.rb
        index 333..444 100644
        --- a/lib/b.rb
        +++ b/lib/b.rb
        @@ -1 +1 @@
        -before
        +after
      DIFF

      chunks = described_class.split_by_file(diff)

      expect(chunks.length).to eq(2)
      expect(chunks[0][:path]).to eq('lib/a.rb')
      expect(chunks[1][:path]).to eq('lib/b.rb')
      expect(chunks[0][:lines].first).to start_with('diff --git')
    end
  end

  describe '.clip_diff_context' do
    it 'returns the original diff when it is under the byte limit' do
      diff = "diff --git a/a.rb b/a.rb\n@@ -1 +1 @@\n-old\n+new\n"

      clipped = described_class.clip_diff_context(diff, max_bytes: 500)

      expect(clipped).to eq(diff)
    end

    it 'clips by file and hunk while preserving structure and notice' do
      long_hunk = (1..400).map { |i| "+line #{i}" }.join("\n")
      diff = <<~DIFF
        diff --git a/a.rb b/a.rb
        index 111..222 100644
        --- a/a.rb
        +++ b/a.rb
        @@ -1 +1,400 @@
        #{long_hunk}
        diff --git a/b.rb b/b.rb
        index 333..444 100644
        --- a/b.rb
        +++ b/b.rb
        @@ -1 +1 @@
        -before
        +after
      DIFF

      clipped = described_class.clip_diff_context(diff, max_bytes: 500)

      expect(clipped.bytesize).to be <= 500
      expect(clipped).to include('diff --git a/a.rb b/a.rb')
      expect(clipped).to include('@@ -1 +1,400 @@')
      expect(clipped).to include(described_class::TRUNCATION_NOTICE.strip)
    end
  end

  describe '.branch_diff' do
    it 'rejects invalid branch names before running git' do
      expect do
        described_class.branch_diff(base_branch: 'main; rm -rf /')
      end.to raise_error('Invalid branch name.')
    end
  end
end
