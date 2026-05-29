class Libxaw < Formula
  desc "X.Org: X Athena Widget Set"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXaw-1.0.16.tar.xz"
  sha256 "731d572b54c708f81e197a6afa8016918e2e06dfd3025e066ca642a5b8c39c8f"
  license all_of: [
    "MIT-open-group",    # "The Open Group"
    "X11",               # "The XFree86 Project, Inc."
    "HPND",              # "Digital Equipment Corporation", "Prentice Hall"
    "HPND-sell-variant", # "OMRON Corporation"
  ]
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18e5d8d97318eaf89dc629d50c1c7fff223e43fc810b02508f273c86cf2a21f2"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxmu"
  depends_on "libxpm"
  depends_on "libxt"

  # Backport fix for improved linking on macOS
  patch do
    on_macos do
      url "https://gitlab.freedesktop.org/xorg/lib/libxaw/-/commit/cce2abf00fa2c9a695f1d0e5c931c70c1ba579cf.diff"
      sha256 "64bfebc3fcb788582abbf2589514e64b3fa62457089c77e644177f1c0a80c10f"
    end
  end

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --disable-specs
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xaw/Text.h"

      int main(int argc, char* argv[]) {
        XawTextScrollMode mode;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
