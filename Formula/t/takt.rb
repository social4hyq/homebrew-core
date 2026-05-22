class Takt < Formula
  desc "Text-based music programming language"
  homepage "https://takt.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/takt/takt-0.310-src.tar.gz"
  sha256 "eb2947eb49ef84b6b3644f9cf6f1ea204283016c4abcd1f7c57b24b896cc638f"
  license "GPL-2.0-or-later"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "14f7a3ad92c73344ad55eda93a5440bd15ce9845f421e11913b73c2a97c01b4e"
  end

  depends_on "readline"

  on_linux do
    depends_on "alsa-lib"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403
    system "./configure", "--prefix=#{prefix}", "--with-lispdir=#{elisp}"
    system "make", "install"
  end

  test do
    system bin/"takt", "-o etude1.mid", pkgshare/"examples/etude1.takt"
  end
end
