class Xinput < Formula
  desc "Utility to configure and test X input devices"
  homepage "https://gitlab.freedesktop.org/xorg/app/xinput"
  url "https://www.x.org/pub/individual/app/xinput-1.6.4.tar.xz"
  sha256 "ad04d00d656884d133110eeddc34e9c69e626ebebbbab04dc95791c2907057c8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bb692fad67f819028679413be9806f30f228afb9f2fefcb8fa9d05f2ea912c3f"
  end

  depends_on "pkgconf" => :build
  depends_on "xorgproto" => :build
  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxi"
  depends_on "libxinerama"
  depends_on "libxrandr"

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
    assert_path_exists bin/"xinput"
    assert_equal %Q(.TH xinput 1 "xinput #{version}" "X Version 11"),
      shell_output("head -n 1 #{man1}/xinput.1").chomp
  end
end
