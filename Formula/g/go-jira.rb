class GoJira < Formula
  desc "Simple jira command-line client in Go"
  homepage "https://github.com/go-jira/jira"
  url "https://github.com/go-jira/jira/archive/refs/tags/v1.0.27.tar.gz"
  sha256 "c5bcf7b61300b67a8f4e42ab60e462204130c352050e8551b1c23ab2ecafefc7"
  license "Apache-2.0"
  head "https://github.com/go-jira/jira.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ecf6f5ee8fc3530ea766c83293d459fe09d12b764fd3a2aefb93193288c8c03c"
  end

  depends_on "go" => :build

  conflicts_with "jira-cli", because: "both install `jira` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"jira"), "cmd/jira/main.go"
  end

  test do
    system bin/"jira", "export-templates"
    template_dir = testpath/".jira.d/templates/"

    files = Dir.entries(template_dir)
    # not an exhaustive list, see https://github.com/go-jira/jira/blob/4d74554300fa7e5e660cc935a92e89f8b71012ea/jiracli/templates.go#L239
    expected_templates = %w[comment components create edit issuetypes list view worklog debug]

    assert_equal([], expected_templates - files)
    assert_equal("{{ . | toJson}}\n", File.read("#{template_dir}/debug"))
  end
end
