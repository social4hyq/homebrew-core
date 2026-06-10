class KubectlExplore < Formula
  desc "Better kubectl explain with the fuzzy finder"
  homepage "https://github.com/keisku/kubectl-explore"
  url "https://github.com/keisku/kubectl-explore/archive/refs/tags/v0.14.1.tar.gz"
  sha256 "cf13b9a569d5fb3852e6d6d6844e3f4383e4dbddfd16187eccd05627a4c10e90"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a2c99ea70da414bff73fab5402174e07c3119f4dac5e306f9a9cf7983f846b0e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "The connection to the server localhost:8080 was refused",
      shell_output("#{bin}/kubectl-explore pod 2>&1", 1)
  end
end
