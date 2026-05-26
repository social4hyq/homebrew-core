class Xdpyinfo < Formula
  desc "X.Org: Utility for displaying information about an X server"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/app/xdpyinfo-1.4.0.tar.xz"
  sha256 "dc1de6e6e091ed46c4837b0ae9811e8182f7be0d2af638cab3e530ff081a48b6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "259ac4a2db1ee23b570e66d82193da7e8f79e09a4f169ca41969a6b1e9218c2a"
  end

  depends_on "pkgconf" => :build

  depends_on "libx11"
  depends_on "libxcb"
  depends_on "libxext"
  depends_on "libxi"
  depends_on "libxtst"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "xdpyinfo #{version}", shell_output("DISPLAY= xdpyinfo -version")
  end
end
