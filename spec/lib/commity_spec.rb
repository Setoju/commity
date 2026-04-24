# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity do
  it 'loads core service constants' do
    expect(defined?(Commity::GitReader)).to eq('constant')
    expect(defined?(Commity::GitWriter)).to eq('constant')
    expect(defined?(Commity::OllamaClient)).to eq('constant')
    expect(defined?(Commity::DiffSummarizer)).to eq('constant')
    expect(defined?(Commity::PromptBuilder)).to eq('constant')
    expect(defined?(Commity::PrOpener)).to eq('constant')
  end
end
