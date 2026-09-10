class Mecab < Formula
  desc "Yet another part-of-speech and morphological analyzer"
  homepage "https://taku910.github.io/mecab/"
  # Canonical url is https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE
  url "https://deb.debian.org/debian/pool/main/m/mecab/mecab_0.996.orig.tar.gz"
  sha256 "e073325783135b72e666145c781bb48fada583d5224fb2490fb6c1403ba69c59"
  license any_of: ["GPL-2.0-only", "LGPL-2.1-only", "BSD-3-Clause"]
  revision 1

  livecheck do
    url :homepage
    regex(/mecab[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c135834979b26b4f6174134145bff7e59937e82138a57f77e1d607208d564807"
  end

  conflicts_with "mecab-ko", because: "both install mecab binaries"

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    # Fix OpenHarmony: use libc++ instead of libstdc++
    inreplace "configure", "-lstdc++", "-lc++"
    system "./configure", "--sysconfdir=#{etc}", *args, *std_configure_args
    system "make", "install"

    # Put dic files in HOMEBREW_PREFIX/lib instead of lib
    inreplace bin/"mecab-config", "#{lib}/mecab/dic", "#{HOMEBREW_PREFIX}/lib/mecab/dic"
    inreplace etc/"mecabrc", "#{lib}/mecab/dic", "#{HOMEBREW_PREFIX}/lib/mecab/dic"
  end

  def post_install
    (HOMEBREW_PREFIX/"lib/mecab/dic").mkpath
  end

  test do
    assert_equal "#{HOMEBREW_PREFIX}/lib/mecab/dic", shell_output("#{bin}/mecab-config --dicdir").chomp
    return if OS.linux?

    require "utils/linkage"
    library = "/usr/lib/libiconv.2.dylib"
    assert Utils.binary_linked_to_library?(bin/"mecab", library), "No linkage with #{library}!"
  end
end
