class GitlabReleaseCli < Formula
  desc "Toolset to create, retrieve and update releases on GitLab"
  homepage "https://gitlab.com/gitlab-org/release-cli"
  url "https://gitlab.com/gitlab-org/release-cli/-/archive/v0.24.0/release-cli-v0.24.0.tar.bz2"
  sha256 "e13a53fdaf60e2fb2df620969dd35131800cddad8d3d4c476154110249629daa"
  license "MIT"
  head "https://gitlab.com/gitlab-org/release-cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac7c4b2411eeebece173efb041d901ff8bcacc1f13c899790bb4c987273fb435"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.VERSION=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"release-cli"), "./cmd/release-cli"
  end

  test do
    ENV["CI_SERVER_URL"] = "https://gitlab.com"
    ENV["CI_PROJECT_ID"] = "12345678"

    assert_match version.to_s, shell_output("#{bin}/release-cli --version")

    output = shell_output("#{bin}/release-cli create --tag-name v1.0.0 2>&1", 1)
    assert_match "failed to create GitLab client: access token not provided", output
  end
end
