class Gzip < Formula
  desc "Popular GNU data compression program"
  homepage "https://www.gnu.org/software/gzip/"
  url "https://ftpmirror.gnu.org/gnu/gzip/gzip-1.15.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gzip/gzip-1.15.tar.gz"
  sha256 "545886cf57fa88a65e967fbf705903d7fcb2567c82c7342493e82e8d7b1a210b"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "33cf059d5ee476e7fff81fd079b1e946f30f28c697e9f1136f87617dd0be7e50"
  end

  # gzip 1.15 moved <signal.h> after "gzip.h", whose `head` macro then
  # collides with `struct _aarch64_ctx head` in the aarch64 signal headers.
  # Include <signal.h> first; matches upstream homebrew-core.
  patch do
    file "Patches/gzip/0001-aarch64-head-macro.patch"
    type :unofficial
    resolves "https://lists.gnu.org/archive/html/bug-gzip/2026-09/msg00031.html"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"foo").write "test"
    system bin/"gzip", "foo"
    system bin/"gzip", "-t", "foo.gz"
    assert_equal "test", shell_output("#{bin}/gunzip -c foo")
  end
end
