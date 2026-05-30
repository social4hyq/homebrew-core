class Identme < Formula
  desc "Public IP address lookup"
  homepage "https://www.ident.me"
  url "https://github.com/pcarrier/ident.me/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "5e37f2f5b661ebe9731aab8d6d2ecdbea6e2239ea6f5ad1f2b158ea15fea947c"
  license "0BSD"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "876cdccb4cc8feed3a2df4ffb108f856e0380a7c83616f1d48c70984929d8d21"
  end

  depends_on "cmake" => :build
  uses_from_macos "curl"

  def install
    system "cmake", "-S", "cli", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match "ipv4", shell_output("#{bin}/identme --json -4")
  end
end
