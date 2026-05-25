class GitlabCiLinter < Formula
  desc "Command-line tool to lint GitLab CI YAML files"
  homepage "https://gitlab.com/orobardet/gitlab-ci-linter"
  url "https://gitlab.com/orobardet/gitlab-ci-linter/-/archive/v2.4.0/gitlab-ci-linter-v2.4.0.tar.bz2"
  sha256 "caacfabcb3e5d01b821c685d443b709c464b999a60f72bd67ead4a2d991547d7"
  license "MIT"
  head "https://gitlab.com/orobardet/gitlab-ci-linter.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46529ca4cef7048569e5c634331ea76dd0650e8300dbb27a62e2e4977ed3bb45"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X gitlab.com/orobardet/gitlab-ci-linter/config.VERSION=#{version}
      -X gitlab.com/orobardet/gitlab-ci-linter/config.REVISION=#{tap.user}
      -X gitlab.com/orobardet/gitlab-ci-linter/config.BUILDTIME=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gitlab-ci-linter --version")

    (testpath/".gitlab-ci.yml").write <<~YAML
      stages:
        - test

      lint:
        stage: test
        script:
          - echo "This is a test job"
    YAML

    output = shell_output("#{bin}/gitlab-ci-linter check 2>&1", 5)
    assert_match "error linting using Gitlab API", output
  end
end
