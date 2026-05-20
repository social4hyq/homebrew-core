class LunarDate < Formula
  desc "Chinese lunar date library"
  homepage "https://github.com/yetist/lunar-date"
  url "https://github.com/yetist/lunar-date/releases/download/v3.2.0/lunar-date-3.2.0.tar.xz"
  sha256 "2d24263803c0d8ed90c7d68bb7f69a481441f0b3ed89b5a29ea704dea86a4580"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "95a9a3200bf84c3749952b05837053a0a93c401c023558ded83452feb50d0913"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    pkgshare.install "tests"

    # Fix missing #include <locale.h> in testing.c
    inreplace pkgshare/"tests/testing.c", "#include <stdlib.h>",
      "#include <stdlib.h>\n#include <locale.h>"
  end

  test do
    pkgconf_flags = Utils.safe_popen_read("pkgconf", "--cflags", "--libs", "lunar-date-3.0", "glib-2.0").chomp.split
    system ENV.cc, pkgshare/"tests/testing.c", *pkgconf_flags,
                   "-I#{include}/lunar-date-3.0/lunar-date",
                   "-L#{lib}", "-o", "testing"
    assert_match "End of date tests", shell_output("#{testpath}/testing")
  end
end
