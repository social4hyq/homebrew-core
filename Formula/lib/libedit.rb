class Libedit < Formula
  desc "BSD-style licensed readline alternative"
  homepage "https://thrysoee.dk/editline/"
  url "https://thrysoee.dk/editline/libedit-20251016-3.1.tar.gz"
  version "20251016-3.1"
  sha256 "21362b00653bbfc1c71f71a7578da66b5b5203559d43134d2dd7719e313ce041"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/href=.*?libedit[._-]v?(\d{4,}-\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d18c7bff6ed40d310654942ff3e1136b8f465ce6b5eeae832ca4e0a251f04d08"
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
