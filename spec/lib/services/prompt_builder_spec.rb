# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::PromptBuilder do
  describe '.build' do
    it 'builds commit prompt with scope overview and raw diff block' do
      prompt = described_class.build(type: :commit, diff: 'diff --git a/a.rb b/a.rb', summarized: false)

      expect(prompt[:system]).to include('Your sole task is to write a Git commit message')
      expect(prompt[:user]).to include('Change scope overview:')
      expect(prompt[:user]).to include('- Total files changed: 1')
      expect(prompt[:user]).to include('Here is the git diff:')
      expect(prompt[:user]).to include('```diff')
      expect(prompt[:user]).to include('Write the commit message now')
    end

    it 'builds pr prompt with summarized section and raw-diff scope overview' do
      prompt = described_class.build(
        type: :pr,
        diff: "### app/a.rb\n- changed",
        summarized: true,
        raw_diff: 'diff --git a/spec/a_spec.rb b/spec/a_spec.rb'
      )

      expect(prompt[:system]).to include('Your sole task is to write a Pull Request description')
      expect(prompt[:user]).to include('Change scope overview:')
      expect(prompt[:user]).to include('- Total files changed: 1')
      expect(prompt[:user]).to include('Here is a structured summary of the git changes')
      expect(prompt[:user]).to include('Write the PR description now')
      expect(prompt[:user]).not_to include('```diff')
    end
  end
end
