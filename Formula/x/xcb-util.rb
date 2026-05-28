class XcbUtil < Formula
  desc "Additional extensions to the XCB library"
  homepage "https://xcb.freedesktop.org"
  url "https://xcb.freedesktop.org/dist/xcb-util-0.4.1.tar.xz"
  sha256 "5abe3bbbd8e54f0fa3ec945291b7e8fa8cfd3cccc43718f8758430f94126e512"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "beff488c2e6722b3c320a8e6921263a8d3f6d39c605f2230fb1fc2d6ae92c82a"
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "libxcb"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    assert_match "-I#{include}", shell_output("pkg-config --cflags xcb-util").chomp
  end
end
