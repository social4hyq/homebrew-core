class Gpatch < Formula
  desc "Apply a diff file to an original"
  homepage "https://savannah.gnu.org/projects/patch/"
  url "https://ftpmirror.gnu.org/gnu/patch/patch-2.8.tar.xz"
  mirror "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz"
  sha256 "f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2554c2365222ebe990730fc5b21075a540e4331c1e5ae95742f91a3d2221bb45"
  end

  def install
    args = std_configure_args
    args << "--program-prefix=g" if OS.mac?

    system "./configure", *args
    system "make", "install"

    return unless OS.mac?

    # Symlink the executable into libexec/gnubin as "patch"
    (libexec/"gnubin").install_symlink bin/"gpatch" => "patch"
    (libexec/"gnuman/man1").install_symlink man1/"gpatch.1" => "patch.1"
    (libexec/"gnubin").install_symlink "../gnuman" => "man"
  end

  def caveats
    on_macos do
      <<~EOS
        GNU "patch" has been installed as "gpatch".
        If you need to use it as "patch", you can add a "gnubin" directory
        to your PATH from your bashrc like:

            PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    testfile = testpath/"test"
    testfile.write "homebrew\n"
    patch = <<~EOS
      1c1
      < homebrew
      ---
      > hello
    EOS
    if OS.mac?
      pipe_output("#{bin}/gpatch #{testfile}", patch)
    else
      pipe_output("#{bin}/patch #{testfile}", patch)
    end
    assert_equal "hello", testfile.read.chomp
  end
end
