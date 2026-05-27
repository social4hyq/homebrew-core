class Websocat < Formula
  desc "Command-line client for WebSockets"
  homepage "https://github.com/vi/websocat"
  url "https://github.com/vi/websocat/archive/refs/tags/v1.14.1.tar.gz"
  sha256 "5c976c535800ca635b72839fe49d0fe4ad2479db8744c5a00f0cf911e4832e2d"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ef77768ec19440704b6c3b162d2b9ca40ced6408b160a844a4313e8823b75ac0"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(features: "ssl")
  end

  test do
    system bin/"websocat", "-t", "literal:qwe", "assert:qwe"
  end
end
