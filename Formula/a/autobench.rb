class Autobench < Formula
  desc "Automatic webserver benchmark tool"
  homepage "http://www.xenoclast.org/autobench/"
  url "https://distfiles.macports.org/autobench/autobench-2.1.2.tar.gz"
  mirror "http://www.xenoclast.org/autobench/downloads/autobench-2.1.2.tar.gz"
  sha256 "d8b4d30aaaf652df37dff18ee819d8f42751bc40272d288ee2a5d847eaf0423b"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?autobench[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c46f8011151e0b4c0f64b5fc9a07034479129f339a8c1d25e96b05a8be30f094"
  end

  depends_on "httperf"

  def install
    # Workaround for arm64 linux. Upstream isn't actively maintained
    ENV.append_to_cflags "-fsigned-char" if OS.linux? && Hardware::CPU.arm?

    system "make", "PREFIX=#{prefix}",
                   "MANDIR=#{man1}",
                   "CC=#{ENV.cc}",
                   "CFLAGS=#{ENV.cflags}",
                   "install"
  end

  test do
    system bin/"crfile", "-f", testpath/"test", "-s", "42"
    assert_path_exists testpath/"test"
    assert_equal 42, File.size("test")
  end
end
