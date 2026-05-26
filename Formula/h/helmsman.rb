class Helmsman < Formula
  desc "Helm Charts as Code tool"
  homepage "https://github.com/mkubaczyk/helmsman"
  url "https://github.com/mkubaczyk/helmsman/archive/refs/tags/v4.0.5.tar.gz"
  sha256 "d7a49bd4322dfc4f1f8136fe0bcce5ef0bbb9aafe895945580178861fd908ac4"
  license "MIT"
  head "https://github.com/mkubaczyk/helmsman.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a65e21eadfd5caf51c16892c77f32343b680d043fa383e54a9f1869c1567321"
  end

  depends_on "go" => :build
  depends_on "helm"
  depends_on "kubernetes-cli"

  def install
    ldflags = %W[
      -s -w
      -X github.com/mkubaczyk/helmsman/internal/app.appVersion=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/helmsman"
    pkgshare.install "examples/example.yaml", "examples/job.yaml"
  end

  test do
    ENV["ORG_PATH"] = "brewtest"
    ENV["VALUE"] = "brewtest"

    output = shell_output("#{bin}/helmsman --apply -f #{pkgshare}/example.yaml 2>&1", 1)
    assert_match "helm diff not found", output

    assert_match version.to_s, shell_output("#{bin}/helmsman version")
  end
end
