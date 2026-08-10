class GnuWhich < Formula
  desc "GNU implementation of which utility"
  # Previous homepage is dead. Have linked to the GNU Projects page for now.
  homepage "https://savannah.gnu.org/projects/which/"
  url "https://ftpmirror.gnu.org/gnu/which/which-2.25.tar.gz"
  mirror "https://ftp.gnu.org/gnu/which/which-2.25.tar.gz"
  sha256 "1cb83e4f702e60b8211ab5ec4c2afbab1b1dec80209456a7d2faf7584ed225ea"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd1eee3c023a1495c197caba29660805a4a02c7d142965a1859f7fc5a7a930bf"
  end

  def install
    ENV.append "CFLAGS", "-std=gnu17" if DevelopmentTools.clang_build_version >= 1700

    # which 2.25's configure uses bash-only syntax ([[ =~ ]]) that the
    # ci-runner's /bin/sh (mksh) rejects; force bash so configure re-execs.
    ENV["CONFIG_SHELL"] = "/bin/bash"

    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
    ]

    args << "--program-prefix=g" if OS.mac?
    system "./configure", *args
    system "make", "install"

    if OS.mac?
      (libexec/"gnubin").install_symlink bin/"gwhich" => "which"
      (libexec/"gnuman/man1").install_symlink man1/"gwhich.1" => "which.1"
      (libexec/"gnubin").install_symlink "../gnuman" => "man"
    end
  end

  def caveats
    on_macos do
      <<~EOS
        GNU "which" has been installed as "gwhich".
        If you need to use it as "which", you can add a "gnubin" directory
        to your PATH from your bashrc like:

            PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    if OS.mac?
      system bin/"gwhich", "gcc"
      system opt_libexec/"gnubin/which", "gcc"
    else
      system bin/"which", "gcc"
    end
  end
end
