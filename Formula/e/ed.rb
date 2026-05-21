class Ed < Formula
  desc "Classic UNIX line editor"
  homepage "https://www.gnu.org/software/ed/ed.html"
  url "https://ftpmirror.gnu.org/gnu/ed/ed-1.22.5.tar.lz"
  mirror "https://ftp.gnu.org/gnu/ed/ed-1.22.5.tar.lz"
  sha256 "56e107ddc2f29dad6690376c15bf9751509e1ee3b8241710e44edbe5c3a158cc"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e82298eb58d3058c071269692805dc53484cd822dca49f49e2539008025761c"
  end

  keg_only :provided_by_macos

  patch do
    file "Patches/ed/0001-Use-TMPDIR-aware-mkstemp-instead-of-tmpfile.patch"
  end

  def install
    ENV.deparallelize

    args = ["--prefix=#{prefix}"]
    args << "--program-prefix=g" if OS.mac?

    system "./configure", *args
    system "make"
    system "make", "install"

    if OS.mac?
      %w[ed red].each do |prog|
        (libexec/"gnubin").install_symlink bin/"g#{prog}" => prog
        (libexec/"gnuman/man1").install_symlink man1/"g#{prog}.1" => "#{prog}.1"
      end
    end

    (libexec/"gnubin").install_symlink "../gnuman" => "man"
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
    testfile = testpath/"test"
    testfile.write "Hello world\n"

    if OS.mac?
      pipe_output("#{bin}/ged -s #{testfile}", ",s/o//\nw\n", 0)
      assert_equal "Hell world\n", testfile.read

      pipe_output("#{opt_libexec}/gnubin/ed -s #{testfile}", ",s/l//g\nw\n", 0)
      assert_equal "He word\n", testfile.read
    else
      pipe_output("#{bin}/ed -s #{testfile}", ",s/o//\nw\n", 0)
      assert_equal "Hell world\n", testfile.read
    end
  end
end
