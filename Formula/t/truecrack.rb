class Truecrack < Formula
  desc "Brute-force password cracker for TrueCrypt"
  homepage "https://github.com/lvaccaro/truecrack"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/truecrack/truecrack_v35.tar.gz"
  version "3.5"
  sha256 "25bf270fa3bc3591c3d795e5a4b0842f6581f76c0b5d17c0aef260246fe726b3"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "510281abb74c15e3324b7fda37186e9e27b3257ac6486935288b340c47ce217d"
  end

  # Fix missing return value compilation issue
  # https://github.com/lvaccaro/truecrack/issues/41
  patch do
    url "https://gist.githubusercontent.com/anonymous/b912a1ede06eb1e8eb38/raw/1394a8a6bedb7caae8ee034f512f76a99fe55976/truecrack-return-value-fix.patch"
    sha256 "8aa608054f9b822a1fb7294a5087410f347ba632bbd4b46002aada76c289ed77"
  end

  def install
    if OS.linux?
      # Issue ref: https://github.com/lvaccaro/truecrack/issues/56
      inreplace "src/Makefile.in", /^CFLAGS = /, "\\0-fcommon -Wno-implicit-function-declaration "
    elsif DevelopmentTools.clang_build_version >= 1403
      # Fix compile with newer Clang
      inreplace "src/Makefile.in", /^CFLAGS = /, "\\0-Wno-implicit-function-declaration "
    end

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    # Re datarootdir override: Dumps two files in top-level share
    # (autogen.sh and cudalt.py) which could cause conflict elsewhere.
    system "./configure", "--enable-cpu",
                          "--datarootdir=#{pkgshare}",
                          "--mandir=#{man}",
                          *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"truecrack"
  end
end
