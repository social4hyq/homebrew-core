class Bgrep < Formula
  desc "Like grep but for binary strings"
  homepage "https://github.com/tmbinc/bgrep"
  url "https://github.com/tmbinc/bgrep/archive/refs/tags/bgrep-0.2.tar.gz"
  sha256 "24c02393fb436d7a2eb02c6042ec140f9502667500b13a59795388c1af91f9ba"
  license "BSD-2-Clause"
  head "https://github.com/tmbinc/bgrep.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b8019b476195d9eaa0e486ecd305915c72dd856967c5f242a344fd143cc9d49"
  end

  def install
    args = %w[bgrep.c -o bgrep]
    args << ENV.cflags if ENV.cflags.present?
    system ENV.cc, *args
    bin.install "bgrep"
  end

  test do
    path = testpath/"hi.prg"
    path.binwrite [0x00, 0xc0, 0xa9, 0x48, 0x20, 0xd2, 0xff,
                   0xa9, 0x49, 0x20, 0xd2, 0xff, 0x60].pack("C*")

    assert_equal "#{path}: 00000004\n#{path}: 00000009\n",
                 shell_output("#{bin}/bgrep 20d2ff #{path}")
  end
end
