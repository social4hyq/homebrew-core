class Gperf < Formula
  desc "Perfect hash function generator"
  homepage "https://www.gnu.org/software/gperf/"
  url "https://ftpmirror.gnu.org/gnu/gperf/gperf-3.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz"
  sha256 "fd87e0aba7e43ae054837afd6cd4db03a3f2693deb3619085e6ed9d8d9604ad8"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a392cf3cdbf1af720b14dabe1a2609b33d0862648949fd79d0971a43d6672dc"
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
