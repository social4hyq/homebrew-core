class Tradcpp < Formula
  desc "K&R-style C preprocessor"
  homepage "https://www.netbsd.org/~dholland/tradcpp/"
  url "https://cdn.netbsd.org/pub/NetBSD/misc/dholland/tradcpp-0.5.3.tar.gz"
  sha256 "e17b9f42cf74b360d5691bc59fb53f37e41581c45b75fcd64bb965e5e2fe4c5e"
  license "BSD-2-Clause"

  livecheck do
    url :homepage
    regex(/href=.*?tradcpp[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6fea089abb4b04bc6df9ce333bfcdaa0b570c5b0ebcc42c36e5b8ff99e1dfc9d"
  end

  depends_on "bmake" => :build

  def install
    bmake_args = %W[
      prefix=#{prefix}
      MK_INSTALL_AS_USER=yes
      MANDIR=#{man}
    ]

    system "bmake"
    system "bmake", *bmake_args, "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #define FOO bar
      FOO
    C
    assert_match "bar", shell_output("#{bin}/tradcpp ./test.c")
  end
end
