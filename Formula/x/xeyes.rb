class Xeyes < Formula
  desc "Follow the mouse X demo using the X SHAPE extension"
  homepage "https://gitlab.freedesktop.org/xorg/app/xeyes"
  url "https://www.x.org/archive/individual/app/xeyes-1.3.1.tar.xz"
  sha256 "5608d76b7b1aac5ed7f22f1b6b5ad74ef98c8693220f32b4b87dccee4a956eaa"
  license "X11"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08b084712d5ec31021f013897e4b2cc0dd872fac7c499e3ae690794747cb99ac"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxcb"
  depends_on "libxext"
  depends_on "libxi"
  depends_on "libxmu"
  depends_on "libxrender"
  depends_on "libxt"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/xeyes -display :100 2>&1", 1)
    assert_match "Error: Can't open display:", output
  end
end
