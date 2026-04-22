require "open3"

module Commity
  module GitReader
    MAX_DIFF_BYTES = 50_000

    def self.staged_diff
      diff, = Open3.capture2("git", "diff", "--cached")
      raise "No staged changes. Run `git add` first." if diff.strip.empty?
      diff[0, MAX_DIFF_BYTES]
    end

    def self.branch_diff(base_branch: "main")
      raise "Invalid branch name." unless base_branch.match?(/\A[a-zA-Z0-9_\-.\/]+\z/)
      diff, = Open3.capture2("git", "diff", "#{base_branch}...HEAD")
      raise "No diff found against '#{base_branch}'." if diff.strip.empty?
      diff[0, MAX_DIFF_BYTES]
    end

    def self.recent_commits(count: 10)
      out, = Open3.capture2("git", "log", "--oneline", "-#{count}")
      out
    end
  end
end