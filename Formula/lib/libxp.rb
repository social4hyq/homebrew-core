class Libxp < Formula
  desc "X Print Client Library"
  homepage "https://gitlab.freedesktop.org/xorg/lib/libxp"
  url "https://gitlab.freedesktop.org/xorg/lib/libxp/-/archive/libXp-1.0.4/libxp-libXp-1.0.4.tar.bz2"
  sha256 "81468f6d5d8d8f847aac50af60b36c43d84d976d907ab1dfd667683dbfb5fb90"
  license "MIT"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^libXp[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "42fa4377131a5428ddc6bd401ea51b1aa87d4b91adc46c7827f01b1827b2938c"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "util-macros" => :build

  depends_on "libx11"
  depends_on "libxau"
  depends_on "libxext"

  resource "printproto" do
    url "https://gitlab.freedesktop.org/xorg/proto/printproto/-/archive/printproto-1.0.5/printproto-printproto-1.0.5.tar.bz2"
    sha256 "f2819d05a906a1bc2d2aea15e43f3d372aac39743d270eb96129c9e7963d648d"
  end

  def install
    resource("printproto").stage do
      system "sh", "autogen.sh"
      system "./configure", "--disable-silent-rules", *std_configure_args
      system "make", "install"
    end

    ENV.prepend_path "PKG_CONFIG_PATH", "#{lib}/pkgconfig"
    system "sh", "autogen.sh"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "-I#{include}", shell_output("pkgconf --cflags xp").chomp
  end
end
