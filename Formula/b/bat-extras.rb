class BatExtras < Formula
  desc "Bash scripts that integrate bat with various command-line tools"
  homepage "https://github.com/eth-p/bat-extras"
  url "https://github.com/eth-p/bat-extras/archive/refs/tags/v2024.08.24.tar.gz"
  sha256 "2ff1b9104134f10721ef36580150365e94546e5b41b9a2a6eaa4851c5959b487"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9258f07c44296e8e9f80441549fe2692e1f67f4592024aa8e88f5aa75a0f8be9"
  end

  depends_on "bat" => [:build, :test]
  depends_on "shfmt" => :build
  depends_on "ripgrep" => :test

  def install
    system "./build.sh", "--prefix=#{prefix}", "--minify", "all", "--install"
  end

  test do
    system bin/"prettybat < /dev/null"
    system bin/"batgrep", "/usr/bin/env", bin
  end
end
