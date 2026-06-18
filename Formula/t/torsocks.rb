class Torsocks < Formula
  desc "Use SOCKS-friendly applications with Tor"
  homepage "https://gitlab.torproject.org/tpo/core/torsocks"
  url "https://gitlab.torproject.org/tpo/core/torsocks/-/archive/v2.5.0/torsocks-v2.5.0.tar.bz2"
  sha256 "31a917328b221e955230b7663abfbc50d3a9b445a68cb0313c11cf884f8cb41f"
  license "GPL-2.0-only"
  head "https://gitlab.torproject.org/tpo/core/torsocks.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8018d72f9a46afb13a9155fc988dc768c18190c7d5ba10163a773f400ade186c"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  # https://gitlab.torproject.org/legacy/trac/-/issues/28538
  patch do
    url "https://gitlab.torproject.org/legacy/trac/uploads/9efc1c0c47b3950aa91e886b01f7e87d/0001-Fix-macros-for-accept4-2.patch"
    sha256 "97881f0b59b3512acc4acb58a0d6dfc840d7633ead2f400fad70dda9b2ba30b0"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "./autogen.sh"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"torsocks", "--help"
  end
end
