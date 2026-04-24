# frozen_string_literal: true

require "spec_helper"
require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe "Commity CLI", :integration do
  it "shows help output successfully" do
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-Ilib", "bin/commity", "--help")

    expect(status.success?).to be(true)
    expect("#{stdout}\n#{stderr}").to include("Usage: commity [options]")
  end

  it "fails with clear error for invalid PR base branch name" do
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      "bin/commity",
      "--type",
      "pr",
      "--base",
      "main;rm",
      "--no-copy"
    )

    expect(status.success?).to be(false)
    expect("#{stdout}\n#{stderr}").to include("Invalid branch name.")
  end

  it "fails gracefully when run outside a git repository" do
    Dir.mktmpdir("commity-no-git") do |dir|
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        "-I",
        File.expand_path("lib", Dir.pwd),
        File.expand_path("bin/commity", Dir.pwd),
        "--type",
        "commit",
        "--no-copy",
        chdir: dir
      )

      expect(status.success?).to be(false)
      expect("#{stdout}\n#{stderr}").to include("Failed to read git status.")
    end
  end
end
