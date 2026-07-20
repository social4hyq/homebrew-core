class Xwininfo < Formula
  desc "Print information about windows on an X server"
  homepage "https://gitlab.freedesktop.org/xorg/app/xwininfo"
  url "https://www.x.org/archive/individual/app/xwininfo-1.1.7.tar.xz"
  sha256 "bee14d594cc86cc59aae1015c1b452a71bf60c304131e2716ca1cf0df733b4ac"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "491496df7bc62969919d1e69a2ed7deec782a7134debf1c2e5c35bd2356795b3"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxcb"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/xwininfo -display :100 2>&1", 1)
    assert_match "xwininfo: error: unable to open display", output
  end
end
