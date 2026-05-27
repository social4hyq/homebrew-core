class GnuShogi < Formula
  desc "Japanese Chess"
  homepage "https://www.gnu.org/software/gnushogi/"
  url "https://ftpmirror.gnu.org/gnu/gnushogi/gnushogi-1.4.2.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gnushogi/gnushogi-1.4.2.tar.gz"
  sha256 "1ecc48a866303c63652552b325d685e7ef5e9893244080291a61d96505d52b29"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "605379de4007353ce981ed09ba96d84d5e657b23f157afb73382bf042c1c31f8"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `DRAW'; globals.o:(.bss+0x0): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure", *std_configure_args
    system "make", "install", "MANDIR=#{man6}", "INFODIR=#{info}"
  end

  test do
    (testpath/"test").write <<~EOS
      7g7f
      exit
    EOS

    system bin/"gnushogi < test"
  end
end
