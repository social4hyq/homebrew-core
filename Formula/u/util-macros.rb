class UtilMacros < Formula
  desc "X.Org: Set of autoconf macros used to build other xorg packages"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/util/util-macros-1.20.2.tar.xz"
  sha256 "9ac269eba24f672d7d7b3574e4be5f333d13f04a7712303b1821b2a51ac82e8e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "42511c3ea7a4cdc1f6eac363d01083acb52577486b271adef7db045b2b136a5f"
  end

  depends_on "pkgconf" => :test

  def install
    args = %W[
      --disable-silent-rules
      --sysconfdir=#{etc}
      --localstatedir=#{var}
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    assert_equal version.to_s, shell_output("pkgconf --modversion xorg-macros").chomp
  end
end
