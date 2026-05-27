class Dtach < Formula
  desc "Emulates the detach feature of screen"
  homepage "https://dtach.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/dtach/dtach/0.9/dtach-0.9.tar.gz"
  sha256 "32e9fd6923c553c443fab4ec9c1f95d83fa47b771e6e1dafb018c567291492f3"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "194694a77f0688444ba4e5db014f1fd35cb6c0c6404275f87d00e677b7c823d6"
  end

  def install
    # Includes <config.h> instead of "config.h", so "." needs to be in the include path.
    ENV.append "CFLAGS", "-I."

    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"

    system "make"
    bin.install "dtach"
    man1.install Utils::Gzip.compress("dtach.1")
  end

  test do
    system bin/"dtach", "--help"
  end
end
