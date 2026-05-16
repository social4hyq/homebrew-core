class Cliam < Formula
  desc "Cloud agnostic IAM permissions enumerator"
  homepage "https://github.com/securisec/cliam"
  url "https://github.com/securisec/cliam/archive/refs/tags/2.2.0.tar.gz"
  sha256 "3fd407787b49645da3ac14960c751cd90acf1cfacec043c57bbf4d81be9b2d9e"
  license "GPL-3.0-or-later"
  head "https://github.com/securisec/cliam.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "23c195100219b7c751cda5511ade9ba20c6f40615f39385db79c31e2b7aa2333"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/securisec/cliam/cli/version.BuildDate=#{time.iso8601}
      -X github.com/securisec/cliam/cli/version.GitCommit=
      -X github.com/securisec/cliam/cli/version.GitBranch=
      -X github.com/securisec/cliam/cli/version.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cli"

    generate_completions_from_executable(bin/"cliam", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/cliam aws utils sts-get-caller-identity " \
                          "--profile brewtest 2>&1", 1)
    assert_match "SharedCredsLoad: failed to load shared credentials file", output

    output = shell_output("#{bin}/cliam gcp rest enumerate", 1)
    assert_match "accessapproval", output

    assert_match version.to_s, shell_output("#{bin}/cliam version")
  end
end
