class Wv < Formula
  desc "Programs for accessing Microsoft Word documents"
  homepage "https://wvware.sourceforge.net/"
  url "https://deb.debian.org/debian/pool/main/w/wv/wv_1.2.9.orig.tar.gz"
  mirror "https://abisource.com/downloads/wv/1.2.9/wv-1.2.9.tar.gz"
  sha256 "4c730d3b325c0785450dd3a043eeb53e1518598c4f41f155558385dd2635c19d"
  license "GPL-2.0-or-later"
  revision 3

  livecheck do
    skip "Not actively developed or maintained"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5cf2cf60d06b8fce3eceecbbd287f2a43473656490f3051f85440929d9af4f9f"
  end

  depends_on "pkgconf" => :build
  depends_on "glib"
  depends_on "libgsf"
  depends_on "libpng"
  depends_on "libwmf"

  uses_from_macos "libxml2"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Work around build errors
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types -Wno-int-conversion"

    args = ["--mandir=#{man}"]
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm64?

    system "./configure", *args, *std_configure_args
    system "make"
    ENV.deparallelize
    # the makefile generated does not create the file structure when installing
    # till it is fixed upstream, create the target directories here.
    # https://www.abisource.com/mailinglists/abiword-dev/2011/Jun/0108.html

    bin.mkpath
    (lib/"pkgconfig").mkpath
    (include/"wv").mkpath
    man1.mkpath
    (pkgshare/"wingdingfont").mkpath
    (pkgshare/"patterns").mkpath

    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/wvSummary #{test_fixtures("test.pdf")} 2>&1")
    assert_match "No OLE2 signature", output

    assert_match version.to_s, shell_output("#{bin}/wvHtml --version")
  end
end
