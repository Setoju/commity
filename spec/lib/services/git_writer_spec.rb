# frozen_string_literal: true

require "spec_helper"

RSpec.describe Commity::GitWriter do
  def status(success)
    instance_double(Process::Status, success?: success)
  end

  describe ".status_short" do
    it "returns git status output on success" do
      allow(Open3).to receive(:capture2).with("git", "status", "--short").and_return([" M lib/a.rb\n", status(true)])

      expect(described_class.status_short).to eq(" M lib/a.rb\n")
    end

    it "raises on failure" do
      allow(Open3).to receive(:capture2).with("git", "status", "--short").and_return(["", status(false)])

      expect { described_class.status_short }.to raise_error("Failed to read git status.")
    end
  end

  describe ".staged_changes?" do
    it "returns true when staged files exist" do
      allow(Open3).to receive(:capture2).with("git", "diff", "--cached", "--name-only").and_return(["lib/a.rb\n", status(true)])

      expect(described_class.staged_changes?).to be(true)
    end

    it "returns false when no staged files" do
      allow(Open3).to receive(:capture2).with("git", "diff", "--cached", "--name-only").and_return(["\n", status(true)])

      expect(described_class.staged_changes?).to be(false)
    end

    it "raises on failure" do
      allow(Open3).to receive(:capture2).with("git", "diff", "--cached", "--name-only").and_return(["", status(false)])

      expect { described_class.staged_changes? }.to raise_error("Failed to read staged changes.")
    end
  end

  describe ".stage_all" do
    it "returns true when git add succeeds" do
      allow(Open3).to receive(:capture3).with("git", "add", "-A").and_return(["", "", status(true)])

      expect(described_class.stage_all).to be(true)
    end

    it "raises with stderr on failure" do
      allow(Open3).to receive(:capture3).with("git", "add", "-A").and_return(["", "fatal: denied", status(false)])

      expect { described_class.stage_all }.to raise_error("git add failed: fatal: denied")
    end

    it "falls back to stdout when stderr is blank" do
      allow(Open3).to receive(:capture3).with("git", "add", "-A").and_return(["fatal from stdout", "", status(false)])

      expect { described_class.stage_all }.to raise_error("git add failed: fatal from stdout")
    end
  end

  describe ".commit_with_message_file" do
    it "writes message to tempfile and commits with --file" do
      allow(Open3).to receive(:capture3) do |*args|
        expect(args[0..2]).to eq(["git", "commit", "--file"])
        commit_file = args[3]
        expect(File.read(commit_file)).to eq("feat: add tests\n")
        ["[main 123] feat: add tests", "", status(true)]
      end

      out = described_class.commit_with_message_file("feat: add tests")
      expect(out).to include("feat: add tests")
    end

    it "raises with git error details on failure" do
      allow(Open3).to receive(:capture3).and_return(["", "commit failed", status(false)])

      expect { described_class.commit_with_message_file("feat: add tests") }.to raise_error("git commit failed: commit failed")
    end
  end

  describe ".current_branch" do
    it "returns stripped branch name" do
      allow(Open3).to receive(:capture2).with("git", "rev-parse", "--abbrev-ref", "HEAD").and_return(["feature/x\n", status(true)])

      expect(described_class.current_branch).to eq("feature/x")
    end

    it "raises on failure" do
      allow(Open3).to receive(:capture2).with("git", "rev-parse", "--abbrev-ref", "HEAD").and_return(["", status(false)])

      expect { described_class.current_branch }.to raise_error("Failed to read current branch.")
    end
  end

  describe ".origin_url" do
    it "returns stripped remote url" do
      allow(Open3).to receive(:capture2).with("git", "remote", "get-url", "origin").and_return(["git@github.com:acme/repo.git\n", status(true)])

      expect(described_class.origin_url).to eq("git@github.com:acme/repo.git")
    end

    it "raises on failure" do
      allow(Open3).to receive(:capture2).with("git", "remote", "get-url", "origin").and_return(["", status(false)])

      expect { described_class.origin_url }.to raise_error("Failed to read git remote 'origin'.")
    end
  end
end
