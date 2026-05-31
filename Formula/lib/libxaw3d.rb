class Libxaw3d < Formula
  desc "X.Org: 3D Athena widget set based on the Xt library"
  homepage "https://www.x.org"
  url "https://xorg.freedesktop.org/archive/individual/lib/libXaw3d-1.6.6.tar.gz"
  sha256 "0cdb8f51c390b0f9f5bec74454e53b15b6b815bc280f6b7c969400c9ef595803"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2831e23aba4307cc7dc9cfb3bdcdbc439a9855a68455942e53eea935e4bd9b92"
  end

  depends_on "pkgconf" => :build
  depends_on "util-macros" => :build
  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxmu"
  depends_on "libxpm"
  depends_on "libxt"

  # Backport fix for improved linking on macOS
  patch do
    on_macos do
      url "https://gitlab.freedesktop.org/xorg/lib/libxaw3d/-/commit/b2365950e5314b0453dd7cf2a552aa30ec19c046.diff"
      sha256 "18919b30bfafd2642895a4f9497f54b8d263e4eb593f192a923340732ed4afa8"
    end
  end

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --enable-gray-stipples
      --enable-arrow-scrollbars
      --enable-multiplane-bitmaps
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <X11/Xaw3d/Label.h>
      int main() { printf("%d", sizeof(LabelWidget)); }
    C
    system ENV.cc, "test.c", "-o", "test"
    output = shell_output("./test").chomp
    assert_match "8", output
  end
end
