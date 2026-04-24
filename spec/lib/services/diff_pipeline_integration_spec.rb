# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Diff pipeline", :integration do
  class FakeSummaryClient
    def generate(system:, user:, **_kwargs)
      return "- summarize file changes" if system.include?("provided diff chunk")

      user
    end
  end

  it "keeps file context then summarizes large diffs" do
    large_hunk = (1..10_000).map { |i| "+line #{i}" }.join("\n")
    diff = <<~DIFF
      diff --git a/app/models/user.rb b/app/models/user.rb
      index 111..222 100644
      --- a/app/models/user.rb
      +++ b/app/models/user.rb
      @@ -1 +1,10000 @@
      #{large_hunk}
    DIFF

    clipped = Commity::GitReader.clip_diff_context(diff, max_bytes: Commity::GitReader::MAX_DIFF_BYTES)
    result = Commity::DiffSummarizer.summarize_if_needed(clipped, client: FakeSummaryClient.new)

    expect(clipped).to include("diff --git a/app/models/user.rb b/app/models/user.rb")
    expect(clipped).to include("@@ -1 +1,10000 @@")
    expect(result[:summarized]).to be(true)
    expect(result[:content]).to include("### app/models/user.rb")
  end
end
