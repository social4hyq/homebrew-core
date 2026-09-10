class Libtool < Formula
  desc "Generic library support script"
  homepage "https://www.gnu.org/software/libtool/"
  url "https://ftpmirror.gnu.org/gnu/libtool/libtool-2.6.2.tar.xz"
  mirror "https://ftp.gnu.org/gnu/libtool/libtool-2.6.2.tar.xz"
  sha256 "2ef1067c16c97db930fd740cc9bc3d3ba9a583804ae5ac42cc3e8719e49e191e"
  license "GPL-2.0-or-later"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eccba31a84c3a6512e54ea6f6d8ad8e06c1c0081a2ac6fcb7b9b54b54f11acd5"
  end

  depends_on "m4"

  def install
    ENV["M4"] = Formula["m4"].opt_bin/"m4"

    args = %w[
      --disable-silent-rules
      --enable-ltdl-install
    ]
    args << "--program-prefix=g" if OS.mac?

    system "./configure", *args, *std_configure_args
    system "make", "install"

    if OS.mac?
      %w[libtool libtoolize].each do |prog|
        (libexec/"gnubin").install_symlink bin/"g#{prog}" => prog
        (libexec/"gnuman/man1").install_symlink man1/"g#{prog}.1" => "#{prog}.1"
      end
      (libexec/"gnubin").install_symlink "../gnuman" => "man"
    else
      bin.install_symlink "libtool" => "glibtool"
      bin.install_symlink "libtoolize" => "glibtoolize"
    end
  end

  def caveats
    on_macos do
      <<~EOS
        All commands have been installed with the prefix "g".
        If you need to use these commands with their normal names, you
        can add a "gnubin" directory to your PATH from your bashrc like:
          PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    system bin/"glibtool", "execute", File.executable?("/usr/bin/true") ? "/usr/bin/true" : "/bin/true"

    (testpath/"hello.c").write <<~C
      #include <stdio.h>
      int main() { puts("Hello, world!"); return 0; }
    C

    system bin/"glibtool", "--mode=compile", "--tag=CC",
      ENV.cc, "-c", "hello.c", "-o", "hello.o"
    system bin/"glibtool", "--mode=link", "--tag=CC",
      ENV.cc, "hello.o", "-o", "hello"
    assert_match "Hello, world!", shell_output("./hello")

    system bin/"glibtoolize", "--ltdl"
  end
end
