class GnuTime < Formula
  desc "GNU implementation of time utility"
  homepage "https://www.gnu.org/software/time/"
  url "https://ftpmirror.gnu.org/gnu/time/time-1.10.tar.gz"
  mirror "https://ftp.gnu.org/gnu/time/time-1.10.tar.gz"
  sha256 "e8c29fb4ab599d8478e41e8618f50db8aede9c90af27d0d2ef28ae50d5de09c3"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ded7342519b730175bf6f568618b603e6042979cb2d5db05ad8d79c9ceae0830"
  end

  uses_from_macos "ruby" => :test

  def install
    args = %W[
      --prefix=#{prefix}
      --info=#{info}
    ]

    args << "--program-prefix=g" if OS.mac?
    system "./configure", *args
    system "make", "install"

    (libexec/"gnubin").install_symlink bin/"gtime" => "time" if OS.mac?
  end

  def caveats
    on_macos do
      <<~EOS
        GNU "time" has been installed as "gtime".
        If you need to use it as "time", you can add a "gnubin" directory
        to your PATH from your bashrc like:

            PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    if OS.mac?
      system bin/"gtime", "ruby", "--version"
      system opt_libexec/"gnubin/time", "ruby", "--version"
    else
      system bin/"time", "ruby", "--version"
    end
  end
end
