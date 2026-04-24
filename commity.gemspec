# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'commity'
  spec.version = '1.1.0'
  spec.authors = ['Setoju']
  spec.summary = 'AI-powered commit and PR description generator using Ollama'
  spec.description = 'Generates git commit messages and PR descriptions using local LLM via Ollama'

  spec.files = Dir['lib/**/*', 'bin/*', 'examples/*']
  spec.bindir = 'bin'
  spec.executables = ['commity']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'dotenv', '~> 3.2'
  spec.add_dependency 'httparty', '~> 0.21'
end
