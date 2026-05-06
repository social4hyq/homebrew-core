class Diffutils < Formula
  desc "File comparison utilities"
  homepage "https://www.gnu.org/software/diffutils/"
  url "https://ftpmirror.gnu.org/gnu/diffutils/diffutils-3.12.tar.gz"
  mirror "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.gz"
  sha256 "5be181b27ec38aad2450080661a64e4a1752bb29b7d5052bf0a02a70f623f9b2"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e3118805330acb1458cb510f7f52c8287b7b7b2fdb5f0e1c84537e58ab42fe16"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"a").write "foo"
    (testpath/"b").write "foo"
    system bin/"diff", "a", "b"
  end
end
