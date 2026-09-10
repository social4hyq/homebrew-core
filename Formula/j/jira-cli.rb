class JiraCli < Formula
  desc "Feature-rich interactive Jira CLI"
  homepage "https://github.com/ankitpokhrel/jira-cli"
  url "https://github.com/ankitpokhrel/jira-cli/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "6b1ecbd2228626cdc987548d8d83faae074c7a167cef737a9ac9180a03767154"
  license "MIT"
  revision 1
  head "https://github.com/ankitpokhrel/jira-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "467183eb87c63699aa779ed3170440e09abf24bd1efaaacd9ed440668ca12a06"
  end

  depends_on "go" => :build

  conflicts_with "go-jira", because: "both install `jira` binaries"

  def install
    ldflags = %W[
      -s -w
      -X github.com/ankitpokhrel/jira-cli/internal/version.Version=#{version}
      -X github.com/ankitpokhrel/jira-cli/internal/version.GitCommit=#{tap.user}
      -X github.com/ankitpokhrel/jira-cli/internal/version.SourceDateEpoch=#{time.to_i}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"jira"), "./cmd/jira"

    generate_completions_from_executable(bin/"jira", shell_parameter_format: :cobra)
    (man7/"jira.7").write Utils.safe_popen_read(bin/"jira", "man")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jira version")

    output = shell_output("#{bin}/jira serverinfo 2>&1", 1)
    assert_match "The tool needs a Jira API token to function", output
  end
end
