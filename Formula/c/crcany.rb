class Crcany < Formula
  desc "Compute any CRC, a bit at a time, a byte at a time, and a word at a time"
  homepage "https://github.com/madler/crcany"
  url "https://github.com/madler/crcany/archive/refs/tags/v2.1.tar.gz"
  sha256 "e07cf86f2d167ea628e6c773369166770512f54a34a3d5c0acd495eb947d8a1b"
  license "Zlib"
  head "https://github.com/madler/crcany.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72b183ebcc4fb5b9fb1c46d8056e3009ba48501db2aa4ca941f067c9456ede85"
  end

  def install
    system "make"
    bin.install "crcany"
  end

  test do
    output = shell_output("#{bin}/crcany -list")
    assert_match "CRC-3/GSM (3gsm)", output
    assert_match "CRC-64/XZ (64xz)", output

    input = "test"
    filename = "foobar"
    (testpath/filename).write input

    expected = <<~EOS
      CRC-3/GSM: 0x0
    EOS
    assert_equal expected, pipe_output("#{bin}/crcany -3gsm", input)
    assert_equal expected, shell_output("#{bin}/crcany -3gsm #{filename}")

    expected = <<~EOS
      CRC-64/XZ: 0xfa15fda7c10c75a5
    EOS
    assert_equal expected, pipe_output("#{bin}/crcany -64xz", input)
    assert_equal expected, shell_output("#{bin}/crcany -64xz #{filename}")
  end
end
