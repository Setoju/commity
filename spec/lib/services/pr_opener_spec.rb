# frozen_string_literal: true

require "spec_helper"
require "cgi"
require "uri"

RSpec.describe Commity::PrOpener do
  describe ".compare_url" do
    it "builds a GitHub compare URL from SSH origin" do
      url = described_class.compare_url(
        origin_url: "git@github.com:acme/commity.git",
        base_branch: "main",
        head_branch: "feat-x",
        title: "My PR",
        body: "Body text"
      )

      expect(url).to start_with("https://github.com/acme/commity/compare/main...feat-x?")

      query = CGI.parse(URI.parse(url).query)
      expect(query["title"]).to eq(["My PR"])
      expect(query["body"]).to eq(["Body text"])
    end

    it "raises when remote is not GitHub" do
      expect do
        described_class.compare_url(
          origin_url: "git@gitlab.com:group/project.git",
          base_branch: "main",
          head_branch: "feat-x",
          title: "PR",
          body: "Body"
        )
      end.to raise_error("Only GitHub remotes are supported for browser PR opening.")
    end
  end

  describe ".suggest_title" do
    it "extracts title from summary section" do
      pr_body = <<~BODY
        ## Summary
        Add API key caching

        ## Motivation
        Avoid repeated network calls.
      BODY

      expect(described_class.suggest_title(pr_body, head_branch: "feature/cache")).to eq("Add API key caching")
    end

    it "falls back to branch name when summary has no prose line" do
      pr_body = <<~BODY
        ## Summary
        - Bullet only

        ## Motivation
        Some reason
      BODY

      expect(described_class.suggest_title(pr_body, head_branch: "feature/cache")).to eq("Update feature/cache")
    end
  end

  describe ".extract_owner_repo" do
    it "parses HTTPS and SSH URL formats" do
      expect(described_class.extract_owner_repo("https://github.com/acme/repo.git")).to eq({ owner: "acme", repo: "repo" })
      expect(described_class.extract_owner_repo("ssh://git@github.com/acme/repo.git")).to eq({ owner: "acme", repo: "repo" })
    end
  end
end
