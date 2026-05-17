class Ktop < Formula
  desc "Top-like tool for your Kubernetes clusters"
  homepage "https://github.com/vladimirvivien/ktop"
  url "https://github.com/vladimirvivien/ktop/archive/refs/tags/v0.5.3.tar.gz"
  sha256 "f255733a56ce292cdf6ca543cf5ef85969814de8ccf60431d70b85dfe38f720f"
  license "Apache-2.0"
  head "https://github.com/vladimirvivien/ktop.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72398d94ad22ea8a4a125693dc0a5b17bfbbc8f1f036efab488e3fc6cc5db736"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/vladimirvivien/ktop/buildinfo.Version=#{version}
      -X github.com/vladimirvivien/ktop/buildinfo.GitSHA=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    output = shell_output("#{bin}/ktop --all-namespaces 2>&1", 1)
    assert_match "connection refused", output
  end
end
