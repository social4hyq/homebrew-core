class Flake < Formula
  desc "FLAC audio encoder"
  homepage "https://flake-enc.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/flake-enc/flake/0.11/flake-0.11.tar.bz2"
  sha256 "8dd249888005c2949cb4564f02b6badb34b2a0f408a7ec7ab01e11ceca1b7f19"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f7e8763759dc3b9f9713ea73dc5d8e743e0dae402dda833bba3eef3210fed812"
  end

  def install
    ENV.deparallelize
    system "./configure", "--disable-debug", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"flake", test_fixtures("test.wav"), "-o", testpath/"test"
  end
end
