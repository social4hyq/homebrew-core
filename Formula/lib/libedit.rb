class Libedit < Formula
  desc "BSD-style licensed readline alternative"
  homepage "https://thrysoee.dk/editline/"
  url "https://thrysoee.dk/editline/libedit-20260508-3.1.tar.gz"
  version "20260508-3.1"
  sha256 "91f42d6571dd8d92faedd1341134ce5abca0c5d0b4b352814186d33f2b11272e"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/href=.*?libedit[._-]v?(\d{4,}-\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ddfe49c8fe7aa63b2eb66a8c6f4b63adeef8e4c4a5f8a7238ca5d2d791242b68"
  end

  keg_only :provided_by_macos

  uses_from_macos "ncurses"

  def install
    ENV.append_to_cflags "-D__STDC_ISO_10646__"

    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"

    # Create readline compatibility symlinks for use by license incompatible
    # software. We put these in libexec to avoid conflict with readline.
    # Similar to https://packages.debian.org/sid/libeditreadline-dev
    %w[history readline].each do |libname|
      (libexec/"include/readline").install_symlink include/"editline/readline.h" => "#{libname}.h"
      (libexec/"lib").install_symlink lib/shared_library("libedit") => shared_library("lib#{libname}")
      (libexec/"lib").install_symlink lib/"libedit.a" => "lib#{libname}.a"
    end
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <histedit.h>
      int main(int argc, char *argv[]) {
        EditLine *el = el_init(argv[0], stdin, stdout, stderr);
        return (el == NULL);
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-ledit", "-I#{include}"
    system "./test"
  end
end
