class Gperf < Formula
  desc "Perfect hash function generator"
  homepage "https://www.gnu.org/software/gperf/"
  url "https://ftpmirror.gnu.org/gnu/gperf/gperf-3.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz"
  sha256 "fd87e0aba7e43ae054837afd6cd4db03a3f2693deb3619085e6ed9d8d9604ad8"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "874090a3a960a5330a03c6f14560d6b7c5ea1870ffaff2c6e1fc8890dcc34c00"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match "TOTAL_KEYWORDS 3",
      pipe_output(bin/"gperf", "homebrew\nfoobar\ntest\n")
  end
end
