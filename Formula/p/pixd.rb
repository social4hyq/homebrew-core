class Pixd < Formula
  desc "Visual binary data using a colour palette"
  homepage "https://github.com/FireyFly/pixd"
  url "https://github.com/FireyFly/pixd/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "011440a8d191e40a572910b0ce7a094e9b4ee75cf972abc6d30674348edf4158"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d17b98241a5feabbfe5ead3ebfd066eabdafdc1ae65e18de0f9d526f7ecf632b"
  end

  def install
    bin.mkdir
    man1.mkpath

    # BSD install does not understand the GNU "-D" flag.
    inreplace "Makefile", "install -D", "install"

    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.txt").write "H"

    assert_match \
      "0000 \e[0m\e[38;2;147;221;0m▀\e[m",
      shell_output("#{bin}/pixd test.txt")
  end
end
