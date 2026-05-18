class Asciitex < Formula
  desc "Generate ASCII-art representations of mathematical equations"
  homepage "https://asciitex.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/asciitex/asciiTeX-0.21.tar.gz"
  sha256 "abf964818833d8b256815eb107fb0de391d808fe131040fb13005988ff92a48d"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e449f81725bd167d351a4e57230e4f81076455312b4b02c2b617a74fd7c3d2b9"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `SYNTAX_ERR_FLAG'; array.o:(.bss+0x0): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure", "--prefix=#{prefix}", "--disable-gtk"
    inreplace "Makefile", "man/asciiTeX_gui.1", ""
    system "make", "install"
    pkgshare.install "EXAMPLES"
  end

  test do
    system bin/"asciiTeX", "-f", "#{pkgshare}/EXAMPLES"
  end
end
