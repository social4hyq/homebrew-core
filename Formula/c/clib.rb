class Clib < Formula
  desc "Package manager for C programming"
  homepage "https://github.com/clibs/clib"
  url "https://github.com/clibs/clib/archive/refs/tags/2.8.7.tar.gz"
  sha256 "83d5767e363c3ed4b4271000b9ce63b6e11b6c4740df910e0074f844fb34258e"
  license "MIT"
  head "https://github.com/clibs/clib.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "26108b3cba5331284535b7714450f88c85e627da765d478740e597c98710d69b"
  end

  uses_from_macos "curl"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/clib --version")

    pipe_output("#{bin}/clib init", "brewtest\n0.0.1\n", 0)
    assert_match "brewtest", (testpath/"clib.json").read
  end
end
