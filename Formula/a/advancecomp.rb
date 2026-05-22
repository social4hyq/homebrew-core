class Advancecomp < Formula
  desc "Recompression utilities for .PNG, .MNG, .ZIP, and .GZ files"
  homepage "https://www.advancemame.it/comp-readme.html"
  url "https://github.com/amadvance/advancecomp/releases/download/v2.6/advancecomp-2.6.tar.gz"
  sha256 "b07d77735540409771cbe1b6df165b5151c11bb9c3d8f01290be0ec88ec3498f"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "94b2e103f7e0ef29d9474bbaf99093d35e879074b9b6a8e7f36755c41e38b040"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--enable-bzip2", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"advdef", "--version"

    cp test_fixtures("test.png"), "test.png"
    system bin/"advpng", "--recompress", "--shrink-fast", "test.png"

    version_string = shell_output("#{bin}/advpng --version")
    assert_includes version_string, "advancecomp v#{version}"
  end
end
