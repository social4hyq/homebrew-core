class Lame < Formula
  desc "High quality MPEG Audio Layer III (MP3) encoder"
  homepage "https://lame.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/lame/lame/4.0/lame-4.0.tar.gz"
  sha256 "3df5124d5ad3a98312ffd7ba6a9b36230e4f8a3e66d3ce0f425e336c32d216eb"
  license "LGPL-2.0-or-later"
  revision 1

  livecheck do
    url :stable
    regex(%r{url=.*?/lame[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ee2ea79b2c1e0578a5ffe9a2d9520c3b8f79fdd4636ddf31e16467ce4807ea7a"
  end

  depends_on "pkgconf" => :build
  depends_on "mpg123"

  uses_from_macos "ncurses"

  def install
    # LAME still calls undeclared legacy ID3 APIs, which do not compile as C23.
    # https://sourceforge.net/p/lame/bugs/517/
    ENV["ac_cv_prog_cc_c23"] = "no"
    ENV.append_to_cflags "-Wno-implicit-function-declaration"

    system "./configure", "--disable-dependency-tracking",
                          "--disable-debug",
                          "--prefix=#{prefix}",
                          "--enable-nasm"
    system "make", "install"
  end

  test do
    system bin/"lame", "--genre-list", test_fixtures("test.mp3")
  end
end
