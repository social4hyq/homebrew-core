class SourceHighlight < Formula
  desc "Source-code syntax highlighter"
  homepage "https://www.gnu.org/software/src-highlite/"
  url "https://ftpmirror.gnu.org/gnu/src-highlite/source-highlight-3.1.9.tar.gz"
  mirror "https://ftp.gnu.org/gnu/src-highlite/source-highlight-3.1.9.tar.gz"
  sha256 "3a7fd28378cb5416f8de2c9e77196ec915145d44e30ff4e0ee8beb3fe6211c91"
  license "GPL-3.0-or-later"
  revision 6
  compatibility_version 1

  livecheck do
    url :stable
    regex(/href=.*?source-highlight[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8dfb366b3b73dac764b0a183cb3c44ba94bdede705bf6a0aef0f26eda53cc30f"
  end

  depends_on "boost"

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    ENV.cxx11
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-boost=#{Formula["boost"].opt_prefix}"
    system "make", "install"

    bash_completion.install "completion/source-highlight"
  end

  test do
    assert_match "GNU Source-highlight #{version}", shell_output("#{bin}/source-highlight -V")
  end
end
