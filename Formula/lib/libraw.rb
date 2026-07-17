class Libraw < Formula
  desc "Library for reading RAW files from digital photo cameras"
  homepage "https://www.libraw.org/"
  url "https://www.libraw.org/data/LibRaw-0.22.2.tar.gz"
  sha256 "de86b035655accff8d4010f1a221fdf50d353cb7b1422ba26f14a0db92612cfa"
  license any_of: ["LGPL-2.1-only", "CDDL-1.0"]
  compatibility_version 2

  livecheck do
    url "https://www.libraw.org/download/"
    regex(/href=.*?LibRaw[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "002ad48c37b3dbf4870868d33ae37d2ee8489a4fb95d26f83cba71ff4659b1f2"
  end

  head do
    url "https://github.com/LibRaw/LibRaw.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "jpeg-turbo"
  depends_on "little-cms2"

  on_macos do
    depends_on "libomp"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Work around "checking for OpenMP flag of C compiler... unknown".
    # Using -dead_strip_dylibs so `brew linkage` can show if OpenMP is actually used.
    ENV.append "LDFLAGS", "-lomp -Wl,-dead_strip_dylibs" if OS.mac?

    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args
    system "make", "install"
    doc.install Dir["doc/*"]
    prefix.install "samples"
  end

  test do
    resource "homebrew-librawtestfile" do
      url "https://www.rawsamples.ch/raws/nikon/d1/RAW_NIKON_D1.NEF"
      mirror "https://web.archive.org/web/20200703103724/https://www.rawsamples.ch/raws/nikon/d1/RAW_NIKON_D1.NEF"
      sha256 "7886d8b0e1257897faa7404b98fe1086ee2d95606531b6285aed83a0939b768f"
    end

    resource("homebrew-librawtestfile").stage(testpath)
    filename = "RAW_NIKON_D1.NEF"
    system bin/"raw-identify", "-u", filename
    system bin/"simple_dcraw", "-v", "-T", filename
  end
end
