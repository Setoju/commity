# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Commity::ConfigLoader do
  describe '.load' do
    it 'returns defaults when no config file exists' do
      allow(File).to receive(:exist?).with('.commity.yaml').and_return(false)
      
      config = described_class.load
      
      expect(config[:model]).to eq('llama3.2')
      expect(config[:candidates]).to eq(1)
    end

    it 'overrides defaults with values from YAML file' do
      yaml_content = { 'model' => 'codellama', 'candidates' => 3 }
      allow(File).to receive(:exist?).with('.commity.yaml').and_return(true)
      allow(YAML).to receive(:load_file).with('.commity.yaml').and_return(yaml_content)
      
      config = described_class.load
      
      expect(config[:model]).to eq('codellama')
      expect(config[:candidates]).to eq(3)
      # Preserves other defaults
      expect(config[:no_copy]).to be(false)
    end

    it 'warns and returns defaults on invalid YAML' do
      allow(File).to receive(:exist?).with('.commity.yaml').and_return(true)
      allow(YAML).to receive(:load_file).and_raise(Psych::SyntaxError.new('', 1, 1, 0, nil, nil))
      
      expect { described_class.load }.to output(/Warning: Failed to parse/).to_stderr
      
      config = described_class.load
      expect(config[:model]).to eq('llama3.2')
    end
  end
end