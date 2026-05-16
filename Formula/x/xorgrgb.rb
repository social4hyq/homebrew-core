class Xorgrgb < Formula
  desc "X.Org: color names database"
  homepage "https://www.x.org/"
  url "https://xorg.freedesktop.org/archive/individual/app/rgb-1.1.1.tar.gz"
  sha256 "9bceca0821a46ff54989ab08ab00d6dd87eb2779fc15165d848eaa0ddd742fbe"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0343869afd7bd2f71c2ae3d5da508f7af650a4fe4fbe802293508ea036500695"
  end

  depends_on "pkgconf" => :build
  depends_on "util-macros" => :build
  depends_on "xorgproto" => :build

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
    assert_match "gray100", shell_output("#{bin}/showrgb").chomp
  end
end
