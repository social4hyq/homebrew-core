class Termshot < Formula
  desc "Creates screenshots based on terminal command output"
  homepage "https://github.com/homeport/termshot"
  url "https://github.com/homeport/termshot/archive/refs/tags/v0.6.1.tar.gz"
  sha256 "40abea3c9ae604f3c2cdc7e2a623bf6063c6b1c504a70c5e3a1b8457dbdd2fbc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ddfb6580acdb9e709ccccee420f23c8c0c13b8c1ae7bc3ff668545d55d81e14"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/homeport/termshot/internal/cmd.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/termshot"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/termshot --version")

    system bin/"termshot", "-f", "brew.png", "--", "termshot"
    assert_path_exists testpath/"brew.png"
  end
end
