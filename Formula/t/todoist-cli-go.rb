class TodoistCliGo < Formula
  desc "CLI for Todoist"
  homepage "https://github.com/sachaos/todoist"
  url "https://github.com/sachaos/todoist/archive/refs/tags/v0.24.0.tar.gz"
  sha256 "1993d51b1d6fe85c521bc215584674631bef59fe1e9a4e29cf19d921e8df303f"
  license "MIT"
  head "https://github.com/sachaos/todoist.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "911b8d64e790be84da218474b6196521f42d2689c775c5a0bcbb57ebfddb8185"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(output: bin/"todoist", ldflags:)
  end

  def caveats
    <<~EOS
      This formula was renamed from "todoist-cli" to "todoist-cli-go" to
      free up the "todoist-cli" name for the official Doist CLI
      (https://github.com/Doist/todoist-cli).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/todoist --version")

    test_config = testpath/".config/todoist/config.json"
    test_config.write <<~JSON
      {
        "token": "test_token"
      }
    JSON
    chmod 0600, test_config

    output = shell_output("#{bin}/todoist list 2>&1")
    assert_match "There is no task.", output
  end
end
