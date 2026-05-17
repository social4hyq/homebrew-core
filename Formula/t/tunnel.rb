class Tunnel < Formula
  desc "Expose local servers to the internet securely"
  homepage "https://github.com/labstack/tunnel-client"
  url "https://github.com/labstack/tunnel-client/archive/refs/tags/v0.5.15.tar.gz"
  sha256 "7a57451416b76dbf220e69c7dd3e4c33dc84758a41cdb9337a464338565e3e6e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "350b6a093dfab01adf362f97d3ec635b940e40365e6c129e682273aa5b1f130d"
  end

  # `https://tunnel.labstack.com/docs` is no longer accessible
  deprecate! date: "2025-02-23", because: :unmaintained
  disable! date: "2026-02-23", because: :unmaintained

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/tunnel"
  end

  test do
    assert_match "you need an api key", shell_output("#{bin}/tunnel 8080", 1)
  end
end
