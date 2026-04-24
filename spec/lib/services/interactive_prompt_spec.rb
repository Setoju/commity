# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commity::InteractivePrompt do
  describe '.commit_message_errors' do
    it 'flags empty messages' do
      expect(described_class.commit_message_errors('   ')).to include('Message cannot be empty.')
    end

    it 'flags invalid conventional commit prefix' do
      errors = described_class.commit_message_errors('update readme')
      expect(errors).to include('First line must start with a conventional commit type (feat:, fix:, etc.).')
    end

    it 'flags long first lines' do
      long_subject = "feat: #{'a' * 80}"
      errors = described_class.commit_message_errors(long_subject)
      expect(errors).to include('First line should be 72 characters or fewer.')
    end

    it 'accepts a valid conventional commit message' do
      message = <<~MSG
        feat(auth): add token rotation

        Rotate refresh token per request.
      MSG

      expect(described_class.commit_message_errors(message)).to eq([])
    end
  end

  describe '.editor_command' do
    around do |example|
      old_visual = ENV['VISUAL']
      old_editor = ENV['EDITOR']

      example.run
    ensure
      ENV['VISUAL'] = old_visual
      ENV['EDITOR'] = old_editor
    end

    it 'adds --wait for VS Code editor commands' do
      ENV['VISUAL'] = ''
      ENV['EDITOR'] = 'code'

      expect(described_class.editor_command).to include('--wait')
    end

    it 'does not duplicate --wait when already present' do
      ENV['VISUAL'] = ''
      ENV['EDITOR'] = 'code --wait'

      expect(described_class.editor_command.count('--wait')).to eq(1)
    end
  end
end
